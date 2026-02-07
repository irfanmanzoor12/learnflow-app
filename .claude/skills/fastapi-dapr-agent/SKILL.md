---
name: fastapi-dapr-agent
description: Deploy FastAPI microservice with Dapr sidecar, Kafka pub/sub, and PostgreSQL on Kubernetes
---

# FastAPI Dapr Agent

## When to Use
- User asks to deploy a FastAPI microservice with Dapr
- Setting up event-driven backend services
- LearnFlow backend agents need deployment

## Prerequisites
- Kafka deployed (use `kafka-k8s-setup` skill first)
- PostgreSQL deployed (use `postgres-k8s-setup` skill first)

## Instructions
1. Create application: `bash .claude/skills/fastapi-dapr-agent/scripts/create_app.sh`
2. Deploy to K8s: `bash .claude/skills/fastapi-dapr-agent/scripts/deploy.sh`
3. Verify: `python3 .claude/skills/fastapi-dapr-agent/scripts/verify.py`

## Validation
- [ ] FastAPI pod running with Dapr sidecar
- [ ] Health and readiness endpoints OK
- [ ] State save/retrieve via Dapr works
- [ ] Kafka pub/sub via Dapr works

See [REFERENCE.md](./REFERENCE.md) for API docs, Dapr components, and troubleshooting.
