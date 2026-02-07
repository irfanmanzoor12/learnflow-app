---
name: docusaurus-deploy
description: Deploy Docusaurus v3 documentation site to Kubernetes with Nginx
---

# Docusaurus Deploy

## When to Use
- User asks to deploy documentation site
- Setting up project documentation with Docusaurus
- LearnFlow needs a documentation portal

## Instructions
1. Create site: `bash .claude/skills/docusaurus-deploy/scripts/create_site.sh`
2. Deploy to K8s: `bash .claude/skills/docusaurus-deploy/scripts/deploy.sh`
3. Verify: `python3 .claude/skills/docusaurus-deploy/scripts/verify.py`

## Validation
- [ ] Docusaurus pods running (2 replicas)
- [ ] Homepage loads with content
- [ ] Health endpoint returns OK

See [REFERENCE.md](./REFERENCE.md) for Nginx config and customization.
