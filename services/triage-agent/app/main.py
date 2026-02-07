from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import httpx
import os
import logging
import asyncpg
from typing import Dict, Any, Optional, List

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="LearnFlow Triage Agent", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Config
DAPR_HTTP_PORT = os.getenv("DAPR_HTTP_PORT", "3500")
DAPR_URL = f"http://localhost:{DAPR_HTTP_PORT}"
PUBSUB_NAME = "kafka-pubsub"
STATE_STORE = "postgres-statestore"

CONCEPTS_SERVICE = "concepts-agent"
CODE_RUNNER_SERVICE = "code-runner"

PG_HOST = os.getenv("POSTGRES_HOST", "postgres-postgresql.postgres.svc.cluster.local")
PG_PORT = os.getenv("POSTGRES_PORT", "5432")
PG_USER = os.getenv("POSTGRES_USER", "postgres")
PG_PASSWORD = os.getenv("POSTGRES_PASSWORD", "postgres")
PG_DATABASE = os.getenv("POSTGRES_DATABASE", "learnflow")

db_pool: Optional[asyncpg.Pool] = None

# --- Models ---

class ChatRequest(BaseModel):
    message: str
    user_id: int = 1

class ChatResponse(BaseModel):
    response: str
    agent: str
    intent: str

class CodeRequest(BaseModel):
    code: str
    user_id: int = 1

# --- Intent Classification ---

CONCEPT_KEYWORDS = [
    "explain", "what is", "what are", "how does", "how do", "why",
    "define", "describe", "tell me about", "teach", "learn",
    "difference between", "example", "concept", "meaning",
    "tutorial", "help me understand", "for loop", "while loop",
    "variable", "function", "class", "list", "dictionary", "string",
    "integer", "boolean", "tuple", "set", "module", "import",
]

CODE_KEYWORDS = [
    "run", "execute", "code", "error", "bug", "fix", "debug",
    "traceback", "exception", "syntax", "indent", "output",
    "print", "compile", "test this", "try this",
]


def classify_intent(message: str) -> str:
    """Classify student intent from message."""
    msg_lower = message.lower()

    concept_score = sum(1 for kw in CONCEPT_KEYWORDS if kw in msg_lower)
    code_score = sum(1 for kw in CODE_KEYWORDS if kw in msg_lower)

    # Check if message contains code block
    if "```" in message or msg_lower.startswith("def ") or msg_lower.startswith("for "):
        code_score += 3

    if code_score > concept_score:
        return "code"
    return "concept"


# --- Lifecycle ---

@app.on_event("startup")
async def startup():
    global db_pool
    try:
        db_pool = await asyncpg.create_pool(
            host=PG_HOST, port=int(PG_PORT), user=PG_USER,
            password=PG_PASSWORD, database=PG_DATABASE,
            min_size=1, max_size=5
        )
        logger.info("Database pool created")
    except Exception as e:
        logger.error(f"DB connection failed: {e}")

@app.on_event("shutdown")
async def shutdown():
    if db_pool:
        await db_pool.close()


# --- Endpoints ---

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "triage-agent"}

@app.get("/ready")
async def readiness():
    checks = {"api": "ok", "database": "unknown"}
    try:
        if db_pool:
            async with db_pool.acquire() as conn:
                await conn.fetchval("SELECT 1")
            checks["database"] = "ok"
    except Exception as e:
        checks["database"] = f"error: {str(e)}"
    return checks


@app.post("/chat", response_model=ChatResponse)
async def chat(req: ChatRequest):
    """Main chat endpoint - classifies intent and routes to specialist."""
    intent = classify_intent(req.message)
    logger.info(f"User {req.user_id}: intent={intent}, message={req.message[:50]}...")

    # Store user message in DB
    if db_pool:
        try:
            async with db_pool.acquire() as conn:
                await conn.execute(
                    "INSERT INTO conversations (user_id, agent, message, role) VALUES ($1, $2, $3, $4)",
                    req.user_id, "triage", req.message, "user"
                )
        except Exception as e:
            logger.error(f"Failed to store message: {e}")

    # Route to specialist via Dapr service invocation
    response_text = ""
    agent_name = ""

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            if intent == "concept":
                # Route to concepts agent
                resp = await client.post(
                    f"{DAPR_URL}/v1.0/invoke/{CONCEPTS_SERVICE}/method/explain",
                    json={"question": req.message, "user_id": req.user_id}
                )
                resp.raise_for_status()
                data = resp.json()
                response_text = data.get("explanation", "I can help with that concept.")
                agent_name = "concepts"

            elif intent == "code":
                # Route to code runner
                resp = await client.post(
                    f"{DAPR_URL}/v1.0/invoke/{CODE_RUNNER_SERVICE}/method/execute",
                    json={"code": req.message, "language": "python", "timeout": 5}
                )
                resp.raise_for_status()
                data = resp.json()
                stdout = data.get("stdout", "")
                stderr = data.get("stderr", "")
                response_text = f"Output:\n{stdout}" if stdout else f"Error:\n{stderr}"
                agent_name = "code-runner"

    except httpx.HTTPStatusError as e:
        logger.error(f"Service call failed: {e}")
        response_text = f"I understood your {intent} question, but the specialist is unavailable right now."
        agent_name = "triage"
    except Exception as e:
        logger.error(f"Routing failed: {e}")
        # Fallback: provide a direct response
        if intent == "concept":
            response_text = _fallback_concept_response(req.message)
            agent_name = "triage-fallback"
        else:
            response_text = "Please use the code editor to run your code."
            agent_name = "triage-fallback"

    # Publish routing event to Kafka
    try:
        async with httpx.AsyncClient() as client:
            await client.post(
                f"{DAPR_URL}/v1.0/publish/{PUBSUB_NAME}/learning.routed",
                json={"user_id": req.user_id, "intent": intent, "agent": agent_name}
            )
    except Exception:
        pass  # Non-critical

    # Store assistant response
    if db_pool and response_text:
        try:
            async with db_pool.acquire() as conn:
                await conn.execute(
                    "INSERT INTO conversations (user_id, agent, message, role) VALUES ($1, $2, $3, $4)",
                    req.user_id, agent_name, response_text, "assistant"
                )
        except Exception as e:
            logger.error(f"Failed to store response: {e}")

    return ChatResponse(response=response_text, agent=agent_name, intent=intent)


@app.post("/run-code")
async def run_code(req: CodeRequest):
    """Proxy code execution to code-runner service."""
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.post(
                f"{DAPR_URL}/v1.0/invoke/{CODE_RUNNER_SERVICE}/method/execute",
                json={"code": req.code, "language": "python", "timeout": 5}
            )
            resp.raise_for_status()
            result = resp.json()

            # Store submission
            if db_pool:
                try:
                    async with db_pool.acquire() as conn:
                        await conn.execute(
                            "INSERT INTO code_submissions (user_id, code, stdout, stderr, exit_code) VALUES ($1, $2, $3, $4, $5)",
                            req.user_id, req.code,
                            result.get("stdout", ""), result.get("stderr", ""),
                            result.get("exit_code", 0)
                        )
                except Exception:
                    pass

            return result
    except Exception as e:
        logger.error(f"Code execution failed: {e}")
        raise HTTPException(status_code=502, detail=str(e))


@app.get("/progress/{user_id}")
async def get_progress(user_id: int):
    """Get student progress."""
    if not db_pool:
        raise HTTPException(status_code=503, detail="Database unavailable")

    async with db_pool.acquire() as conn:
        rows = await conn.fetch(
            "SELECT module, topic, mastery FROM progress WHERE user_id = $1 ORDER BY module, topic",
            user_id
        )
    return {"user_id": user_id, "progress": [dict(r) for r in rows]}


@app.get("/conversations/{user_id}")
async def get_conversations(user_id: int, limit: int = 20):
    """Get recent conversations for a user."""
    if not db_pool:
        raise HTTPException(status_code=503, detail="Database unavailable")

    async with db_pool.acquire() as conn:
        rows = await conn.fetch(
            "SELECT agent, message, role, created_at FROM conversations WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2",
            user_id, limit
        )
    return {"user_id": user_id, "conversations": [dict(r) for r in rows]}


@app.get("/")
async def root():
    return {"service": "LearnFlow Triage Agent", "version": "1.0.0"}


# --- Fallback responses ---

def _fallback_concept_response(message: str) -> str:
    """Provide a basic concept response when concepts-agent is unavailable."""
    msg = message.lower()

    if "for loop" in msg:
        return (
            "A **for loop** in Python iterates over a sequence (list, string, range, etc.).\n\n"
            "```python\n# Basic for loop\nfor i in range(5):\n    print(i)  # prints 0, 1, 2, 3, 4\n\n"
            "# Looping over a list\nfruits = ['apple', 'banana', 'cherry']\n"
            "for fruit in fruits:\n    print(fruit)\n```\n\n"
            "Try writing a for loop in the code editor!"
        )
    elif "while loop" in msg:
        return (
            "A **while loop** repeats as long as a condition is True.\n\n"
            "```python\ncount = 0\nwhile count < 5:\n    print(count)\n    count += 1\n```\n\n"
            "Be careful with infinite loops - always make sure the condition eventually becomes False!"
        )
    elif "variable" in msg:
        return (
            "A **variable** stores a value that you can use later.\n\n"
            "```python\nname = 'Maya'  # string variable\nage = 16       # integer variable\npi = 3.14      # float variable\n\nprint(f'{name} is {age} years old')\n```\n\n"
            "Python variables don't need type declarations - the type is inferred from the value."
        )
    elif "list" in msg:
        return (
            "A **list** is an ordered, mutable collection in Python.\n\n"
            "```python\nfruits = ['apple', 'banana', 'cherry']\n\n"
            "# Access by index\nprint(fruits[0])  # 'apple'\n\n"
            "# Add items\nfruits.append('date')\n\n"
            "# Loop through\nfor fruit in fruits:\n    print(fruit)\n```"
        )
    elif "function" in msg:
        return (
            "A **function** is a reusable block of code.\n\n"
            "```python\ndef greet(name):\n    return f'Hello, {name}!'\n\n"
            "result = greet('Maya')\nprint(result)  # 'Hello, Maya!'\n```\n\n"
            "Functions help organize code and avoid repetition."
        )
    else:
        return (
            "Great question! I can help you learn Python. Try asking about:\n"
            "- Variables and data types\n"
            "- For loops and while loops\n"
            "- Lists, dictionaries, and sets\n"
            "- Functions and classes\n\n"
            "Or write some code in the editor and I'll help you understand it!"
        )
