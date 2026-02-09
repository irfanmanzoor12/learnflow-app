---
sidebar_position: 2
---

# Concepts Agent

Explains Python concepts with examples and interactive prompts.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/explain` | Explain a Python concept |
| `GET` | `/topics` | List available curriculum topics |
| `POST` | `/dapr/subscribe` | Dapr subscription handler |
| `GET` | `/health` | Health check |
| `GET` | `/ready` | Readiness check |

## Curriculum

Built-in Python curriculum covering 6 topics:

| Topic | Module | Difficulty |
|-------|--------|-----------|
| Variables & Data Types | basics | beginner |
| For Loops | loops | beginner |
| While Loops | loops | beginner |
| Lists | data_structures | intermediate |
| Dictionaries | data_structures | intermediate |
| Functions | functions | intermediate |

Each topic includes:
- Clear explanation
- Code examples
- "Try it yourself" prompts for practice

## Explain Request

```json
POST /explain
{
  "question": "explain for loops",
  "user_id": 1
}
```

## Explain Response

```json
{
  "topic": "for_loop",
  "explanation": "A for loop iterates over a sequence...",
  "examples": ["for i in range(5):\n    print(i)"],
  "try_it": "Write a for loop that prints numbers 1 to 10",
  "difficulty": "beginner"
}
```
