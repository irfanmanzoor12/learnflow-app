---
name: nextjs-k8s-deploy
description: Deploy Next.js 14 App Router application to Kubernetes with standalone build
---

# Next.js K8s Deploy

## When to Use
- User asks to deploy a Next.js frontend
- Setting up the LearnFlow UI with Monaco editor
- Deploying any React/Next.js app to Kubernetes

## Instructions
1. Create app: `bash .claude/skills/nextjs-k8s-deploy/scripts/create_app.sh`
2. Deploy to K8s: `bash .claude/skills/nextjs-k8s-deploy/scripts/deploy.sh`
3. Verify: `python3 .claude/skills/nextjs-k8s-deploy/scripts/verify.py`

## Validation
- [ ] Next.js pod running
- [ ] Health and readiness endpoints return OK
- [ ] Homepage renders successfully

See [REFERENCE.md](./REFERENCE.md) for configuration and customization.
