# LearnFlow

AI-Powered Python Tutoring Platform built with Skills + MCP Code Execution.

## Architecture

```
Browser → Next.js Frontend (Monaco Editor + Chat)
              ↓
         Triage Agent (FastAPI + Dapr) → routes queries
              ↓
         Concepts Agent (FastAPI + Dapr) → explains Python
         Code Runner (MCP Server) → executes code
              ↓
         Kafka (event streaming) + PostgreSQL (state)
```

## Quick Start

```bash
# 1. Deploy infrastructure (using skills)
bash .claude/skills/kafka-k8s-setup/scripts/deploy.sh
bash .claude/skills/postgres-k8s-setup/scripts/deploy.sh

# 2. Deploy LearnFlow
bash scripts/deploy-all.sh

# 3. Verify
python3 scripts/verify-all.py

# 4. Access
kubectl port-forward -n learnflow svc/learnflow-frontend 3000:80
# Open http://localhost:3000
```

## Services

| Service | Purpose | Port |
|---------|---------|------|
| triage-agent | Routes student queries | 8001 |
| concepts-agent | Explains Python concepts | 8002 |
| code-runner | Executes Python code (MCP) | 8000 |
| frontend | Next.js + Monaco UI | 3000 |

## Built With Skills

This application was built using the Skills + MCP Code Execution pattern:
- `kafka-k8s-setup` — Deploy Kafka
- `postgres-k8s-setup` — Deploy PostgreSQL
- `fastapi-dapr-agent` — Backend service pattern
- `mcp-code-execution` — Code execution server
- `nextjs-k8s-deploy` — Frontend deployment
- `docusaurus-deploy` — Documentation site

## Hackathon III

Repository 2 of 2 for the Reusable Intelligence and Cloud-Native Mastery hackathon.
