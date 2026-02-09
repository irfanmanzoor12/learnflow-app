---
sidebar_position: 3
---

# Code Runner

MCP (Model Context Protocol) server that executes Python code in a sandboxed environment.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/execute` | Execute Python code |
| `GET` | `/mcp/tools` | List available MCP tools |
| `POST` | `/mcp/execute` | Execute MCP tool |
| `GET` | `/health` | Health check |
| `GET` | `/ready` | Readiness check |

## Code Execution

```json
POST /execute
{
  "code": "print(2 + 2)",
  "language": "python",
  "timeout": 10
}
```

### Response

```json
{
  "stdout": "4\n",
  "stderr": "",
  "exit_code": 0,
  "execution_time": 0.05
}
```

## MCP Pattern

This service implements the **MCP Code Execution pattern**:

- Scripts execute **outside** the agent context window (0 tokens loaded)
- Only the output enters context (~10 tokens)
- Tool discovery via `/mcp/tools` endpoint
- Standard MCP execute interface via `/mcp/execute`

## Safety

- 10-second execution timeout
- Output truncated at 10,000 characters
- Runs as non-root user (UID 1000)
- No network access from executed code
- No filesystem persistence between executions

## Deployed Via Skill

The code runner is deployed using the `mcp-code-execution` skill:

```bash
bash .claude/skills/mcp-code-execution/scripts/create_server.sh /tmp/code-runner
bash .claude/skills/mcp-code-execution/scripts/deploy.sh /tmp/code-runner code-runner learnflow
```
