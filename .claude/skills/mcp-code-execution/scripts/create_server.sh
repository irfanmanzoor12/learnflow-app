#!/bin/bash
set -e

APP_DIR="${1:-/tmp/mcp-code-execution}"

echo "=== Creating MCP Code Execution Server ==="

mkdir -p "$APP_DIR"

# 1. Create the MCP server with code execution capability
cat <<'PYEOF' > "$APP_DIR/main.py"
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Any, Optional
import subprocess
import logging
import json
import sys
import os
import tempfile

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="MCP Code Execution Server", version="1.0.0")


# --- Models ---

class MCPTool(BaseModel):
    name: str
    description: str
    parameters: Dict[str, Any]

class MCPResource(BaseModel):
    uri: str
    name: str
    mimeType: str

class MCPExecuteRequest(BaseModel):
    tool: str
    arguments: Dict[str, Any] = {}

class MCPExecuteResponse(BaseModel):
    result: Any
    metadata: Optional[Dict[str, Any]] = {}

class CodeExecuteRequest(BaseModel):
    code: str
    language: str = "python"
    timeout: int = 5


# --- Tool Registry ---

TOOLS: List[MCPTool] = [
    MCPTool(
        name="execute_code",
        description="Execute Python code in a sandboxed environment and return output",
        parameters={
            "type": "object",
            "properties": {
                "code": {"type": "string", "description": "Python code to execute"},
                "timeout": {"type": "integer", "description": "Timeout in seconds (max 10)", "default": 5}
            },
            "required": ["code"]
        }
    ),
    MCPTool(
        name="echo",
        description="Echo back the provided message",
        parameters={
            "type": "object",
            "properties": {
                "message": {"type": "string", "description": "Message to echo"}
            },
            "required": ["message"]
        }
    ),
    MCPTool(
        name="calculate",
        description="Perform arithmetic calculation",
        parameters={
            "type": "object",
            "properties": {
                "operation": {"type": "string", "enum": ["add", "subtract", "multiply", "divide"]},
                "a": {"type": "number"},
                "b": {"type": "number"}
            },
            "required": ["operation", "a", "b"]
        }
    ),
    MCPTool(
        name="kubectl_status",
        description="Get Kubernetes cluster status summary",
        parameters={
            "type": "object",
            "properties": {
                "namespace": {"type": "string", "description": "Namespace to check (default: all)", "default": ""}
            }
        }
    ),
]

RESOURCES: List[MCPResource] = [
    MCPResource(uri="mcp://server/status", name="Server Status", mimeType="application/json"),
    MCPResource(uri="mcp://server/tools", name="Tool Inventory", mimeType="application/json"),
]


# --- Tool Executors ---

def execute_code(arguments: Dict[str, Any]) -> Dict[str, Any]:
    """Execute Python code in subprocess with timeout."""
    code = arguments.get("code", "")
    timeout = min(arguments.get("timeout", 5), 10)  # Cap at 10s

    with tempfile.NamedTemporaryFile(mode='w', suffix='.py', delete=False) as f:
        f.write(code)
        tmp_path = f.name

    try:
        result = subprocess.run(
            [sys.executable, tmp_path],
            capture_output=True, text=True, timeout=timeout,
            env={**os.environ, "PYTHONDONTWRITEBYTECODE": "1"}
        )
        return {
            "stdout": result.stdout[:10000],  # Truncate large outputs
            "stderr": result.stderr[:5000],
            "exit_code": result.returncode,
            "timed_out": False
        }
    except subprocess.TimeoutExpired:
        return {"stdout": "", "stderr": f"Execution timed out after {timeout}s", "exit_code": -1, "timed_out": True}
    finally:
        os.unlink(tmp_path)


def execute_echo(arguments: Dict[str, Any]) -> str:
    return f"Echo: {arguments.get('message', '')}"


def execute_calculate(arguments: Dict[str, Any]) -> float:
    op = arguments.get("operation")
    a, b = arguments.get("a", 0), arguments.get("b", 0)
    ops = {"add": a + b, "subtract": a - b, "multiply": a * b, "divide": a / b if b != 0 else float("inf")}
    if op not in ops:
        raise ValueError(f"Unknown operation: {op}")
    return ops[op]


def execute_kubectl_status(arguments: Dict[str, Any]) -> Dict[str, Any]:
    """Get K8s status via kubectl (runs as script, not in context)."""
    ns = arguments.get("namespace", "")
    ns_flag = f"-n {ns}" if ns else "--all-namespaces"

    try:
        result = subprocess.run(
            f"kubectl get pods {ns_flag} --no-headers 2>/dev/null | wc -l",
            shell=True, capture_output=True, text=True, timeout=10
        )
        pod_count = result.stdout.strip()

        result2 = subprocess.run(
            f"kubectl get pods {ns_flag} --no-headers 2>/dev/null | grep -c Running || echo 0",
            shell=True, capture_output=True, text=True, timeout=10
        )
        running_count = result2.stdout.strip()

        return {"total_pods": pod_count, "running_pods": running_count, "namespace": ns or "all"}
    except Exception as e:
        return {"error": str(e)}


TOOL_EXECUTORS = {
    "execute_code": execute_code,
    "echo": execute_echo,
    "calculate": execute_calculate,
    "kubectl_status": execute_kubectl_status,
}


# --- Endpoints ---

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "mcp-code-execution"}

@app.get("/ready")
async def readiness():
    return {"status": "ready", "tools_count": len(TOOLS), "resources_count": len(RESOURCES)}

@app.get("/mcp/tools")
async def list_tools():
    return {"tools": [t.dict() for t in TOOLS]}

@app.get("/mcp/resources")
async def list_resources():
    return {"resources": [r.dict() for r in RESOURCES]}

@app.post("/mcp/execute", response_model=MCPExecuteResponse)
async def execute_tool(request: MCPExecuteRequest):
    if request.tool not in TOOL_EXECUTORS:
        raise HTTPException(status_code=404, detail=f"Tool '{request.tool}' not found")
    try:
        result = TOOL_EXECUTORS[request.tool](request.arguments)
        return MCPExecuteResponse(result=result, metadata={"tool": request.tool, "success": True})
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/execute")
async def execute_code_direct(request: CodeExecuteRequest):
    """Direct code execution endpoint (convenience wrapper)."""
    result = execute_code({"code": request.code, "timeout": request.timeout})
    return result

@app.get("/mcp/resource/{uri:path}")
async def get_resource(uri: str):
    if uri == "mcp://server/status":
        return {"uri": uri, "content": {"server": "mcp-code-execution", "status": "operational"}}
    if uri == "mcp://server/tools":
        return {"uri": uri, "content": {"tools": [t.name for t in TOOLS]}}
    raise HTTPException(status_code=404, detail=f"Resource '{uri}' not found")

@app.get("/")
async def root():
    return {"service": "MCP Code Execution Server", "version": "1.0.0",
            "pattern": "Skills + MCP Code Execution",
            "endpoints": {"/mcp/tools": "List tools", "/mcp/execute": "Execute tool",
                          "/execute": "Direct code execution", "/mcp/resources": "List resources"}}
PYEOF

# 2. Create requirements.txt
cat <<'EOF' > "$APP_DIR/requirements.txt"
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.5.0
EOF

# 3. Create Dockerfile
cat <<'EOF' > "$APP_DIR/Dockerfile"
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .

# Run as non-root user
RUN useradd -m -u 1000 appuser
USER appuser

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

echo "✓ MCP Code Execution server created at ${APP_DIR}"
