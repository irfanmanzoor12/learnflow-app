---
name: postgres-k8s-setup
description: Deploy PostgreSQL on Kubernetes using Helm with Bitnami charts
---

# PostgreSQL Kubernetes Setup

## When to Use
- User asks to deploy PostgreSQL or set up a database
- Setting up persistent storage for microservices
- LearnFlow backend needs a database

## Instructions
1. Run deployment: `bash .claude/skills/postgres-k8s-setup/scripts/deploy.sh`
2. Verify status: `python3 .claude/skills/postgres-k8s-setup/scripts/verify.py`
3. Confirm all checks pass before proceeding.

## Validation
- [ ] PostgreSQL pod in Running state
- [ ] Database connection successful
- [ ] Can create tables and query data

See [REFERENCE.md](./REFERENCE.md) for configuration and connection strings.
