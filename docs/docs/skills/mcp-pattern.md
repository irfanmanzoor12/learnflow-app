---
sidebar_position: 2
---

# MCP Code Execution Pattern

The core innovation in LearnFlow's skill system.

## The Problem

Traditional MCP tool calls load entire tool definitions, schemas, and documentation into the agent's context window:

```
Agent Context Window (before):
├── Tool definitions:     ~5,000 tokens
├── Helm chart templates: ~15,000 tokens
├── K8s YAML docs:        ~10,000 tokens
├── Error handling:       ~5,000 tokens
└── Total:                ~35,000+ tokens per tool
```

This wastes context capacity and increases cost.

## The Solution

**Execute scripts outside the context window.** Only the output (success/failure + key info) enters context.

```
Agent Context Window (after):
├── SKILL.md:             ~100 tokens (instructions)
├── Script execution:     0 tokens (runs in shell)
├── Script output:        ~10 tokens (just the result)
└── Total:                ~110 tokens per skill
```

## How It Works

1. Agent reads `SKILL.md` (~100 tokens) — learns trigger phrases and what to do
2. Agent executes `scripts/deploy.sh` — runs in shell, not loaded into context
3. Script output ("Kafka deployed successfully") enters context (~10 tokens)
4. Agent uses output to inform next steps

## Before vs After

| Metric | Direct MCP | Skills Pattern |
|--------|-----------|----------------|
| Tokens per deployment | 50,000+ | ~110 |
| Context remaining | ~78,000 | ~127,890 |
| Cost per operation | High | Minimal |
| Reusability | Low | High |
| Agent compatibility | Single agent | Claude Code + Goose |

## Creating New Skills

See the [Skill Development Guide](https://github.com/irfanmanzoor12/Hackathon_III/blob/master/docs/skill-development-guide.md) in the skills library repository.
