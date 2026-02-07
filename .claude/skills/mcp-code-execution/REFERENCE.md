# MCP Code Execution - Reference

## The MCP Code Execution Pattern

This skill implements the pattern from Anthropic's engineering blog: instead of loading MCP tool definitions into agent context (expensive), wrap them in Skills that execute scripts outside context.

### Token Efficiency

| Component | Tokens | Notes |
|-----------|--------|-------|
| SKILL.md | ~100 | Loaded when triggered |
| REFERENCE.md | 0 | Loaded only if needed |
| scripts/*.sh | 0 | Executed, never loaded |
| Final output | ~10 | "✓ All checks passed" |

**Total: ~110 tokens** vs 50,000+ with direct MCP server connections.

### Before (Direct MCP)
```json
// ~/.claude/mcp.json - loads ALL tool defs at startup
{"servers": {"mcp": {"command": "mcp-server"}}}
// Cost: ~15,000 tokens every session
```

### After (Skill + Script)
```markdown
# SKILL.md - loaded on demand (~100 tokens)
Run: bash scripts/deploy.sh
# Scripts execute outside context (0 tokens)
```

## API Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/health` | Liveness probe |
| GET | `/ready` | Readiness check with tool counts |
| GET | `/mcp/tools` | List available MCP tools |
| GET | `/mcp/resources` | List available MCP resources |
| POST | `/mcp/execute` | Execute an MCP tool |
| POST | `/execute` | Direct code execution (convenience) |
| GET | `/mcp/resource/{uri}` | Fetch a specific resource |

## Available Tools

### `execute_code`
Execute Python code in a sandboxed subprocess.
```json
{"tool": "execute_code", "arguments": {"code": "print('hello')", "timeout": 5}}
```
Returns: `{"stdout": "hello\n", "stderr": "", "exit_code": 0, "timed_out": false}`

### `echo`
Echo back a message.
```json
{"tool": "echo", "arguments": {"message": "test"}}
```

### `calculate`
Arithmetic operations.
```json
{"tool": "calculate", "arguments": {"operation": "add", "a": 10, "b": 5}}
```

### `kubectl_status`
Get Kubernetes pod status summary.
```json
{"tool": "kubectl_status", "arguments": {"namespace": "default"}}
```

## Adding Custom Tools

1. Define tool schema in `TOOLS` list
2. Implement executor function
3. Register in `TOOL_EXECUTORS` dict
4. Rebuild and redeploy

Example:
```python
MCPTool(
    name="my_tool",
    description="Does something useful",
    parameters={"type": "object", "properties": {"input": {"type": "string"}}, "required": ["input"]}
)

def execute_my_tool(arguments):
    return f"Result: {arguments['input']}"

TOOL_EXECUTORS["my_tool"] = execute_my_tool
```

## Code Execution Safety

- **Timeout**: Max 10 seconds per execution
- **Output truncation**: stdout capped at 10,000 chars, stderr at 5,000
- **Non-root**: Container runs as UID 1000
- **Resource limits**: 512Mi memory, 500m CPU
- **No network access from executed code** (subprocess isolation)

## Cleanup

```bash
kubectl delete namespace mcp-server
minikube image rm mcp-code-execution:latest
rm -rf /tmp/mcp-code-execution
```

## References

- MCP Code Execution Pattern: https://www.anthropic.com/engineering/code-execution-with-mcp
- Model Context Protocol: https://modelcontextprotocol.io/
- FastAPI: https://fastapi.tiangolo.com/
