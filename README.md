# LearnFlow

AI-Powered Python Tutoring Platform built with **Skills + MCP Code Execution** pattern.

**Hackathon III** — Repository 2 of 2: Reusable Intelligence and Cloud-Native Mastery.

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                   KUBERNETES CLUSTER                      │
│                                                           │
│  ┌──────────────┐    ┌──────────────┐   ┌─────────────┐ │
│  │ Triage Agent │───►│  Concepts    │   │ Code Runner │ │
│  │ (FastAPI)    │    │  Agent       │   │ (MCP Server)│ │
│  │ +Dapr sidecar│    │ (FastAPI)    │   │ +Dapr       │ │
│  │ Port: 8001   │    │ +Dapr       │   │ Port: 8000  │ │
│  └──────┬───────┘    │ Port: 8002  │   └─────────────┘ │
│         │            └──────────────┘                    │
│         │                                                │
│         ▼                                                │
│  ┌─────────────────────────────────────────────────┐    │
│  │                    KAFKA                         │    │
│  │  learning.routed | learning.response | code.*    │    │
│  └─────────────────────────────────────────────────┘    │
│         │                                                │
│         ▼                                                │
│  ┌──────────────┐          ┌──────────────────────────┐ │
│  │ PostgreSQL   │          │ Dapr Components          │ │
│  │ (learnflow)  │          │ • kafka-pubsub           │ │
│  │ 4 tables     │          │ • postgres-statestore    │ │
│  └──────────────┘          └──────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

## Quick Start

### Prerequisites

- Minikube running (`minikube start --cpus=4 --memory=8192`)
- Docker, kubectl, Helm 3.x, Dapr CLI installed

### Deploy Everything (Single Command)

```bash
bash scripts/deploy-all.sh
```

This script uses Skills to autonomously:
1. Deploy Kafka via `kafka-k8s-setup` skill
2. Deploy PostgreSQL via `postgres-k8s-setup` skill
3. Run database migrations (users, conversations, progress, code_submissions)
4. Create `learnflow` namespace with Dapr components
5. Build and deploy triage-agent, concepts-agent, code-runner
6. Wait for all services to be ready

### Verify

```bash
python3 scripts/verify-all.py
```

Runs 10 checks: infrastructure, pods, health endpoints, chat flow, code execution.

### Test Manually

```bash
# Port forward triage agent
kubectl port-forward -n learnflow svc/triage-agent 8001:80

# Ask a Python question
curl -X POST http://localhost:8001/chat \
  -H 'Content-Type: application/json' \
  -d '{"message": "explain for loops in Python", "user_id": 1}'

# Execute code
kubectl port-forward -n learnflow svc/code-runner 8000:80
curl -X POST http://localhost:8000/execute \
  -H 'Content-Type: application/json' \
  -d '{"code": "print(2+2)", "language": "python", "timeout": 5}'
```

## Services

| Service | Purpose | Port | Pattern |
|---------|---------|------|---------|
| **learnflow-frontend** | Next.js + Monaco editor student UI | 3000 | Next.js 14 Standalone |
| **triage-agent** | Routes student queries to specialist agents | 8001 | FastAPI + Dapr |
| **concepts-agent** | Explains Python concepts with curriculum KB | 8002 | FastAPI + Dapr |
| **code-runner** | Executes Python code in sandbox (MCP server) | 8000 | MCP Code Execution |

### Triage Agent

Classifies student intent and routes to the right specialist:
- "explain for loops" → Concepts Agent
- "run this code" → Code Runner
- Stores all conversations in PostgreSQL
- Publishes routing events to Kafka via Dapr

### Concepts Agent

Built-in Python curriculum covering:
- Variables & Data Types
- For Loops, While Loops
- Lists, Dictionaries
- Functions

Each topic includes explanations, code examples, and "try it yourself" prompts.

### Code Runner

MCP Code Execution server with:
- Python code execution with 10s timeout
- stdout/stderr capture and output truncation
- Tool discovery via MCP protocol (`/mcp/tools`, `/mcp/execute`)

## Database Schema

```sql
users          — student/teacher accounts
conversations  — chat history per user and agent
progress       — mastery tracking per module/topic (0-100%)
code_submissions — code execution history with output
```

Seeded with demo student "Maya" and teacher "Mr. Rodriguez" with initial progress data.

## Built With Skills (MCP Code Execution Pattern)

This application was built using reusable Skills that execute scripts outside agent context for token efficiency:

| Skill | Used For | Token Cost |
|-------|----------|------------|
| `kafka-k8s-setup` | Deploy Kafka cluster | ~110 tokens |
| `postgres-k8s-setup` | Deploy PostgreSQL database | ~110 tokens |
| `fastapi-dapr-agent` | Backend service pattern | ~130 tokens |
| `mcp-code-execution` | Code runner deployment | ~130 tokens |

Each skill: `SKILL.md` (~100 tokens loaded) + `scripts/` (0 tokens, executed) + `REFERENCE.md` (on-demand).

vs Direct MCP: 50,000+ tokens per session. **80-98% token reduction.**

## Project Structure

```
learnflow-app/
├── .claude/skills/           # 7 reusable skills (Claude Code + Goose)
├── AGENTS.md                 # AI agent guidance
├── README.md
├── frontend/                 # Next.js 14 + Monaco Editor
│   ├── src/app/
│   │   ├── page.tsx          # Dashboard with progress
│   │   ├── chat/page.tsx     # AI tutor chat interface
│   │   ├── code/page.tsx     # Monaco code editor + runner
│   │   └── api/              # BFF routes (chat, run-code, progress)
│   ├── package.json
│   └── Dockerfile
├── services/
│   ├── triage-agent/         # Query routing service
│   ├── concepts-agent/       # Python tutoring service
│   └── code-runner/          # Deployed via mcp-code-execution skill
├── docs/                     # Docusaurus v3 documentation site
│   ├── docs/                 # Markdown content (8 pages)
│   ├── docusaurus.config.js
│   └── Dockerfile
├── k8s/
│   ├── namespace.yaml        # learnflow namespace (Dapr enabled)
│   ├── dapr-components.yaml  # Kafka pubsub + PostgreSQL state store
│   └── db-migration.sql      # Database schema + seed data
└── scripts/
    ├── deploy-all.sh         # Single-command full stack deployment
    └── verify-all.py         # 10-check end-to-end verification
```

## Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Frontend | Next.js 14 + Monaco Editor | Student UI with code editor |
| Backend | FastAPI + Dapr | AI-powered tutoring agents |
| Messaging | Kafka (Helm) | Event-driven communication |
| Database | PostgreSQL (Helm) | User data, progress, conversations |
| Service Mesh | Dapr | State management, pub/sub, service invocation |
| Code Execution | MCP Server | Sandboxed Python execution |
| Documentation | Docusaurus v3 | API docs + architecture guide |
| Orchestration | Kubernetes (Minikube) | Container management |
| Skills | Claude Code + Goose | Autonomous deployment via Skills |

## Related Repository

- **Skills Library**: [Hackathon_III](https://github.com/irfanmanzoor12/Hackathon_III) — 7 reusable skills with MCP Code Execution pattern + skill development guide
