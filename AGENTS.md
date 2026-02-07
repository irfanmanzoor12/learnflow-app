# AGENTS.md

## Repository: learnflow-app

LearnFlow is an AI-powered Python tutoring platform built with cloud-native technologies using the Skills + MCP Code Execution pattern.

## Project Overview

- **Name**: LearnFlow
- **Type**: Cloud-native microservices application on Kubernetes
- **Built with**: Skills from `.claude/skills/` — NOT manual coding

## Key Directories

- `services/triage-agent/` — Routes student queries to specialist agents
- `services/concepts-agent/` — Explains Python concepts with examples
- `services/code-runner/` — Executes student code (via mcp-code-execution skill)
- `frontend/` — Next.js 14 + Monaco editor UI
- `k8s/` — Kubernetes namespace and Dapr component manifests
- `scripts/` — Deployment and verification orchestration
- `.claude/skills/` — Reusable skills for Claude Code and Goose

## Agent Rules

1. **Use Skills first**: Deploy infrastructure using `.claude/skills/` scripts before custom code.
2. **Small diffs**: Make the smallest viable change.
3. **No hardcoded secrets**: Use K8s Secrets and env vars.
4. **Validate**: Run verify scripts after every deployment.
5. **Follow patterns**: Backend services follow the `fastapi-dapr-agent` skill pattern.

## Tech Stack

- **Frontend**: Next.js 14, Monaco Editor, TypeScript
- **Backend**: FastAPI, Dapr, OpenAI SDK
- **Messaging**: Kafka (via Dapr pub/sub)
- **Database**: PostgreSQL (via Dapr state store)
- **Orchestration**: Kubernetes (Minikube)
- **AI Agents**: Claude Code, Goose

## For Claude Code

- Use `Bash` tool for `scripts/deploy-all.sh`
- Use skills in `.claude/skills/` for infrastructure
- Use `Write` tool for application code

## For Goose

- Use `toolkit.run_shell()` for deployment scripts
- Skills in `.claude/skills/` are auto-discovered
- Use `toolkit.write_file()` for application code
