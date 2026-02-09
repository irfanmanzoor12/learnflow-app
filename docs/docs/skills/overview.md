---
sidebar_position: 1
---

# Skills Overview

Skills are reusable, agent-discoverable deployment units that follow the **MCP Code Execution pattern**.

## What is a Skill?

A Skill is a directory under `.claude/skills/<name>/` with three components:

```
.claude/skills/<skill-name>/
├── SKILL.md          # ~100 tokens, loaded into agent context
├── scripts/          # 0 tokens, executed outside context
│   ├── deploy.sh
│   └── verify.py
└── REFERENCE.md      # On-demand, loaded only when needed
```

## Token Efficiency

| Component | Token Cost | Purpose |
|-----------|-----------|---------|
| SKILL.md | ~100 tokens | Trigger phrases, instructions |
| scripts/ | 0 tokens | Execute outside context |
| REFERENCE.md | On-demand | Detailed docs when needed |

**Total per skill invocation: ~110-130 tokens**
**vs Direct MCP: 50,000+ tokens per session**

## Skills Used in LearnFlow

| Skill | Deploys | Trigger |
|-------|---------|---------|
| `kafka-k8s-setup` | Apache Kafka on K8s | "deploy Kafka" |
| `postgres-k8s-setup` | PostgreSQL on K8s | "deploy PostgreSQL" |
| `fastapi-dapr-agent` | FastAPI + Dapr service | "create FastAPI agent" |
| `mcp-code-execution` | MCP code execution server | "deploy MCP server" |
| `nextjs-k8s-deploy` | Next.js frontend | "deploy Next.js app" |
| `docusaurus-deploy` | Documentation site | "deploy Docusaurus" |
| `agents-md-gen` | AGENTS.md file | "generate AGENTS.md" |

## Cross-Agent Compatibility

These skills work with both **Claude Code** and **Goose** — any agent that discovers `.claude/skills/` directories.
