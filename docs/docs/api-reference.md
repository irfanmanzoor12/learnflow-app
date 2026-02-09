---
sidebar_position: 5
---

# API Reference

## Triage Agent (Port 8001)

### POST /chat

Send a message to the AI tutor.

```bash
curl -X POST http://localhost:8001/chat \
  -H 'Content-Type: application/json' \
  -d '{"message": "explain for loops in Python", "user_id": 1}'
```

**Response:**
```json
{
  "response": "A for loop in Python iterates over a sequence...",
  "intent": "concept",
  "agent": "concepts-agent",
  "user_id": 1,
  "conversation_id": 42
}
```

### POST /run-code

Execute Python code via the triage agent.

```bash
curl -X POST http://localhost:8001/run-code \
  -H 'Content-Type: application/json' \
  -d '{"code": "print(2+2)", "language": "python", "timeout": 5}'
```

### GET /progress/{user_id}

Get student progress data.

```json
{
  "user_id": 1,
  "progress": [
    {"module": "basics", "topic": "variables", "mastery": 75},
    {"module": "loops", "topic": "for_loop", "mastery": 40}
  ]
}
```

### GET /conversations/{user_id}

Get conversation history.

---

## Code Runner (Port 8000)

### POST /execute

Execute Python code in sandbox.

```bash
curl -X POST http://localhost:8000/execute \
  -H 'Content-Type: application/json' \
  -d '{"code": "print(2+2)", "language": "python", "timeout": 10}'
```

**Response:**
```json
{
  "stdout": "4\n",
  "stderr": "",
  "exit_code": 0,
  "execution_time": 0.05
}
```

### GET /mcp/tools

List available MCP tools.

```json
{
  "tools": [
    {"name": "execute_code", "description": "Execute Python code in sandbox"},
    {"name": "echo", "description": "Echo input back"},
    {"name": "calculate", "description": "Evaluate math expression"},
    {"name": "kubectl_status", "description": "Get cluster status"}
  ]
}
```

---

## Concepts Agent (Port 8002)

### POST /explain

Get an explanation for a Python topic.

```bash
curl -X POST http://localhost:8002/explain \
  -H 'Content-Type: application/json' \
  -d '{"question": "explain for loops", "user_id": 1}'
```

### GET /topics

List available curriculum topics.

---

## Health Checks

All services expose:
- `GET /health` — liveness probe
- `GET /ready` — readiness probe
