---
name: mcp-code-execution
description: Deploy MCP server with code execution pattern - scripts execute outside context for token efficiency
---

# MCP Code Execution

## When to Use
- User asks to deploy an MCP server with code execution
- Setting up MCP tools that wrap external operations
- Implementing the MCP Code Execution pattern (scripts execute, not loaded into context)

## Instructions
1. Create MCP server: `bash .claude/skills/mcp-code-execution/scripts/create_server.sh`
2. Deploy to K8s: `bash .claude/skills/mcp-code-execution/scripts/deploy.sh`
3. Verify: `python3 .claude/skills/mcp-code-execution/scripts/verify.py`

## Validation
- [ ] MCP server pod running
- [ ] Tool discovery endpoint works
- [ ] Code execution endpoint returns results
- [ ] Resource listing works

See [REFERENCE.md](./REFERENCE.md) for MCP protocol details and adding custom tools.
