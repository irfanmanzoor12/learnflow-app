---
sidebar_position: 1
---

# Triage Agent

Routes student queries to the appropriate specialist agent.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/chat` | Classify intent and route to specialist |
| `POST` | `/run-code` | Proxy code execution to Code Runner |
| `GET` | `/progress/{user_id}` | Get student mastery data |
| `GET` | `/conversations/{user_id}` | Get chat history |
| `GET` | `/health` | Health check |
| `GET` | `/ready` | Readiness check |

## Intent Classification

The triage agent uses keyword scoring to classify student intent:

- **Concept questions** ("explain", "what is", "how does") → routes to Concepts Agent
- **Code execution** ("run", "execute", "code") → routes to Code Runner
- **Fallback** → handles directly with built-in responses

## Chat Request

```json
POST /chat
{
  "message": "explain for loops in Python",
  "user_id": 1
}
```

## Chat Response

```json
{
  "response": "A for loop in Python...",
  "intent": "concept",
  "agent": "concepts-agent",
  "user_id": 1,
  "conversation_id": 42
}
```

## Dapr Integration

- **Service invocation**: Calls concepts-agent and code-runner via Dapr sidecar
- **Pub/sub**: Publishes to `learning.routed` Kafka topic
- **State**: Stores conversation metadata in PostgreSQL via Dapr state store
