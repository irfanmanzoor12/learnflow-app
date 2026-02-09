---
slug: /
sidebar_position: 1
---

# LearnFlow

**AI-Powered Python Tutoring Platform** built with the Skills + MCP Code Execution pattern.

## What is LearnFlow?

LearnFlow is a cloud-native tutoring platform where students can:

- **Ask questions** about Python concepts and get AI-powered explanations
- **Write and run code** in a Monaco editor with live execution
- **Track progress** across modules from basics to functions

## Architecture at a Glance

```
Student Browser → Next.js Frontend → Triage Agent → Concepts Agent
                                   → Code Runner (MCP Server)
                  All connected via Kafka pub/sub + Dapr service mesh
                  PostgreSQL for persistence
                  Kubernetes for orchestration
```

## Built With Skills

This application was built using **reusable Skills** that execute deployment scripts outside the agent context window:

| Skill | Purpose | Token Cost |
|-------|---------|------------|
| `kafka-k8s-setup` | Deploy Kafka cluster | ~110 tokens |
| `postgres-k8s-setup` | Deploy PostgreSQL | ~110 tokens |
| `fastapi-dapr-agent` | Service pattern | ~130 tokens |
| `mcp-code-execution` | Code runner | ~130 tokens |

vs Direct MCP approach: 50,000+ tokens per session. **80-98% token reduction.**

## Quick Start

```bash
# Prerequisites: Minikube, Docker, kubectl, Helm, Dapr CLI
bash scripts/deploy-all.sh
```

Single command deploys the entire stack using Skills autonomously.
