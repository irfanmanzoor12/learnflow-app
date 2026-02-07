from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import httpx
import os
import logging
from typing import Dict, Any, Optional

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="LearnFlow Concepts Agent", version="1.0.0")

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

# --- Models ---

class ExplainRequest(BaseModel):
    question: str
    user_id: int = 1

class ExplainResponse(BaseModel):
    explanation: str
    topic: str
    examples: list = []
    difficulty: str = "beginner"

# --- Python Curriculum Knowledge Base ---

CURRICULUM = {
    "variables": {
        "topic": "Variables & Data Types",
        "module": "Basics",
        "difficulty": "beginner",
        "explanation": (
            "Variables in Python store values. Unlike many languages, Python uses **dynamic typing** - "
            "you don't declare types explicitly.\n\n"
            "### Basic Types\n"
            "- `int` — whole numbers: `age = 16`\n"
            "- `float` — decimals: `pi = 3.14`\n"
            "- `str` — text: `name = 'Maya'`\n"
            "- `bool` — True/False: `is_student = True`\n\n"
            "### Type Conversion\n"
            "```python\n"
            "x = '42'        # string\n"
            "y = int(x)      # now integer 42\n"
            "z = float(x)    # now float 42.0\n"
            "```"
        ),
        "examples": [
            "name = 'Maya'\nprint(type(name))  # <class 'str'>",
            "age = 16\nprint(age + 1)  # 17",
            "# Multiple assignment\nx, y, z = 1, 2, 3\nprint(x, y, z)",
        ],
    },
    "for_loop": {
        "topic": "For Loops",
        "module": "Control Flow",
        "difficulty": "beginner",
        "explanation": (
            "A **for loop** iterates over a sequence (list, string, range, etc.).\n\n"
            "### Basic Syntax\n"
            "```python\nfor item in sequence:\n    # do something with item\n```\n\n"
            "### Common Patterns\n"
            "- `range(n)` — loop n times (0 to n-1)\n"
            "- `range(start, stop)` — loop from start to stop-1\n"
            "- `range(start, stop, step)` — with step size\n"
            "- `enumerate()` — get index and value\n"
        ),
        "examples": [
            "for i in range(5):\n    print(i)  # 0, 1, 2, 3, 4",
            "fruits = ['apple', 'banana', 'cherry']\nfor fruit in fruits:\n    print(fruit)",
            "for i, fruit in enumerate(fruits):\n    print(f'{i}: {fruit}')",
            "# Sum numbers 1 to 10\ntotal = 0\nfor n in range(1, 11):\n    total += n\nprint(total)  # 55",
        ],
    },
    "while_loop": {
        "topic": "While Loops",
        "module": "Control Flow",
        "difficulty": "beginner",
        "explanation": (
            "A **while loop** repeats as long as a condition is True.\n\n"
            "```python\nwhile condition:\n    # do something\n    # update condition\n```\n\n"
            "### Key Points\n"
            "- Always ensure the condition eventually becomes False\n"
            "- Use `break` to exit early\n"
            "- Use `continue` to skip to next iteration\n"
        ),
        "examples": [
            "count = 0\nwhile count < 5:\n    print(count)\n    count += 1",
            "# Find first power of 2 > 1000\nn = 1\nwhile n <= 1000:\n    n *= 2\nprint(n)  # 1024",
        ],
    },
    "lists": {
        "topic": "Lists",
        "module": "Data Structures",
        "difficulty": "beginner",
        "explanation": (
            "A **list** is an ordered, mutable collection.\n\n"
            "```python\nfruits = ['apple', 'banana', 'cherry']\n```\n\n"
            "### Common Operations\n"
            "- Access: `fruits[0]` → 'apple'\n"
            "- Append: `fruits.append('date')`\n"
            "- Insert: `fruits.insert(1, 'blueberry')`\n"
            "- Remove: `fruits.remove('banana')`\n"
            "- Length: `len(fruits)`\n"
            "- Slice: `fruits[1:3]`\n\n"
            "### List Comprehension\n"
            "```python\nsquares = [x**2 for x in range(10)]\n```"
        ),
        "examples": [
            "nums = [3, 1, 4, 1, 5, 9]\nnums.sort()\nprint(nums)  # [1, 1, 3, 4, 5, 9]",
            "# List comprehension\nevens = [x for x in range(20) if x % 2 == 0]\nprint(evens)",
        ],
    },
    "functions": {
        "topic": "Functions",
        "module": "Functions",
        "difficulty": "intermediate",
        "explanation": (
            "A **function** is a reusable block of code defined with `def`.\n\n"
            "```python\ndef function_name(parameters):\n    # body\n    return result\n```\n\n"
            "### Key Concepts\n"
            "- **Parameters**: inputs to the function\n"
            "- **Return value**: output from the function\n"
            "- **Default arguments**: `def greet(name='World')`\n"
            "- **Scope**: variables inside a function are local\n"
        ),
        "examples": [
            "def greet(name):\n    return f'Hello, {name}!'\n\nprint(greet('Maya'))",
            "def add(a, b=0):\n    return a + b\n\nprint(add(3, 4))  # 7\nprint(add(3))     # 3",
            "# Multiple return values\ndef min_max(numbers):\n    return min(numbers), max(numbers)\n\nlo, hi = min_max([3, 1, 4, 1, 5])\nprint(lo, hi)  # 1 5",
        ],
    },
    "dictionaries": {
        "topic": "Dictionaries",
        "module": "Data Structures",
        "difficulty": "intermediate",
        "explanation": (
            "A **dictionary** stores key-value pairs.\n\n"
            "```python\nstudent = {'name': 'Maya', 'age': 16, 'grade': 'A'}\n```\n\n"
            "### Common Operations\n"
            "- Access: `student['name']` → 'Maya'\n"
            "- Safe access: `student.get('email', 'N/A')`\n"
            "- Add/update: `student['email'] = 'maya@school.com'`\n"
            "- Keys: `student.keys()`\n"
            "- Values: `student.values()`\n"
            "- Items: `student.items()`\n"
        ),
        "examples": [
            "student = {'name': 'Maya', 'age': 16}\nfor key, value in student.items():\n    print(f'{key}: {value}')",
            "# Count word frequency\nwords = 'the cat sat on the mat'.split()\nfreq = {}\nfor w in words:\n    freq[w] = freq.get(w, 0) + 1\nprint(freq)",
        ],
    },
}


def find_topic(question: str) -> Optional[Dict]:
    """Find the best matching curriculum topic for a question."""
    q = question.lower()
    topic_keywords = {
        "variables": ["variable", "data type", "int", "float", "string", "bool", "type"],
        "for_loop": ["for loop", "for i in", "range(", "iterate", "for each"],
        "while_loop": ["while loop", "while ", "repeat until"],
        "lists": ["list", "array", "append", "sort", "slice", "comprehension"],
        "functions": ["function", "def ", "return", "parameter", "argument"],
        "dictionaries": ["dictionary", "dict", "key", "value", "hash map"],
    }

    best_match = None
    best_score = 0

    for topic_key, keywords in topic_keywords.items():
        score = sum(1 for kw in keywords if kw in q)
        if score > best_score:
            best_score = score
            best_match = topic_key

    if best_match and best_score > 0:
        return CURRICULUM[best_match]
    return None


# --- Endpoints ---

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "concepts-agent"}

@app.get("/ready")
async def readiness():
    return {"status": "ready", "topics_count": len(CURRICULUM)}


@app.post("/explain", response_model=ExplainResponse)
async def explain(req: ExplainRequest):
    """Explain a Python concept with examples."""
    logger.info(f"Explain request: {req.question[:50]}...")

    topic_data = find_topic(req.question)

    if topic_data:
        explanation = topic_data["explanation"]
        if topic_data["examples"]:
            explanation += "\n\n### Try it yourself:\n```python\n"
            explanation += topic_data["examples"][0]
            explanation += "\n```"

        # Publish learning event
        try:
            async with httpx.AsyncClient() as client:
                await client.post(
                    f"{DAPR_URL}/v1.0/publish/{PUBSUB_NAME}/learning.response",
                    json={"user_id": req.user_id, "topic": topic_data["topic"],
                          "module": topic_data["module"]}
                )
        except Exception:
            pass

        return ExplainResponse(
            explanation=explanation,
            topic=topic_data["topic"],
            examples=topic_data["examples"],
            difficulty=topic_data["difficulty"],
        )
    else:
        return ExplainResponse(
            explanation=(
                f"Great question about: *{req.question}*\n\n"
                "I can help you learn Python! Here are topics I specialize in:\n"
                "- **Variables & Data Types** — storing and using values\n"
                "- **For Loops** — iterating over sequences\n"
                "- **While Loops** — repeating with conditions\n"
                "- **Lists** — ordered collections\n"
                "- **Functions** — reusable code blocks\n"
                "- **Dictionaries** — key-value pairs\n\n"
                "Try asking about any of these topics!"
            ),
            topic="General",
            examples=[],
            difficulty="beginner",
        )


@app.post("/subscribe")
async def handle_event(event: Dict[str, Any]):
    """Handle events from Kafka via Dapr subscription."""
    logger.info(f"Received event: {event}")
    return {"status": "processed"}

@app.get("/dapr/subscribe")
async def dapr_subscribe():
    """Dapr subscription config."""
    return [
        {"pubsubname": PUBSUB_NAME, "topic": "learning.routed", "route": "/subscribe"}
    ]


@app.get("/topics")
async def list_topics():
    """List available curriculum topics."""
    return {
        "topics": [
            {"key": k, "name": v["topic"], "module": v["module"], "difficulty": v["difficulty"]}
            for k, v in CURRICULUM.items()
        ]
    }


@app.get("/")
async def root():
    return {"service": "LearnFlow Concepts Agent", "version": "1.0.0"}
