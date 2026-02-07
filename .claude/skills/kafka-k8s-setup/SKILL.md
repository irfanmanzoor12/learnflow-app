---
name: kafka-k8s-setup
description: Deploy Apache Kafka on Kubernetes using Helm with Bitnami charts
---

# Kafka Kubernetes Setup

## When to Use
- User asks to deploy Kafka or set up event streaming
- Setting up event-driven microservices infrastructure
- LearnFlow backend needs async messaging

## Instructions
1. Run deployment: `bash .claude/skills/kafka-k8s-setup/scripts/deploy.sh`
2. Verify status: `python3 .claude/skills/kafka-k8s-setup/scripts/verify.py`
3. Confirm all checks pass before proceeding.

## Validation
- [ ] All Kafka pods in Running state
- [ ] Test topic created successfully
- [ ] Messages can be produced and consumed

See [REFERENCE.md](./REFERENCE.md) for configuration options and troubleshooting.
