#!/usr/bin/env python3
"""Verify MCP Code Execution server deployment."""
import subprocess
import json
import sys
import time


def run(cmd):
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return result.stdout.strip() if result.returncode == 0 else None


def curl(url, method="GET", data=None):
    cmd = f"curl -s -X {method} {url}"
    if data:
        cmd += f" -H 'Content-Type: application/json' -d '{data}'"
    return run(cmd)


def main():
    print("=== MCP Code Execution Verification ===\n")
    passed = 0
    total = 6
    pf_pid = None

    # 1. Check pods
    print("1. Checking pods...")
    output = run("kubectl get pods -n mcp-server -l app=mcp-code-execution -o json")
    if output:
        pods = json.loads(output)["items"]
        running = sum(1 for p in pods if p["status"]["phase"] == "Running")
        if running > 0:
            print(f"   ✓ {running} pod(s) running")
            passed += 1
        else:
            print("   ✗ No running pods")
    else:
        print("   ✗ Cannot find pods")

    # 2. Port forward
    print("2. Setting up port forward...")
    pf = subprocess.Popen(
        "kubectl port-forward -n mcp-server svc/mcp-code-execution 18001:80".split(),
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )
    pf_pid = pf.pid
    time.sleep(3)

    # 3. Test health
    print("3. Testing health...")
    health = curl("http://localhost:18001/health")
    if health and "healthy" in health:
        print("   ✓ Health OK")
        passed += 1
    else:
        print("   ✗ Health failed")

    # 4. Test tool discovery
    print("4. Testing tool discovery...")
    tools = curl("http://localhost:18001/mcp/tools")
    if tools:
        tool_data = json.loads(tools)
        names = [t["name"] for t in tool_data.get("tools", [])]
        if "execute_code" in names:
            print(f"   ✓ {len(names)} tools found: {', '.join(names)}")
            passed += 1
        else:
            print("   ✗ execute_code tool missing")
    else:
        print("   ✗ Tools endpoint failed")

    # 5. Test code execution
    print("5. Testing code execution...")
    code_result = curl(
        "http://localhost:18001/mcp/execute", "POST",
        '{"tool":"execute_code","arguments":{"code":"print(2+2)","timeout":5}}'
    )
    if code_result:
        data = json.loads(code_result)
        stdout = data.get("result", {}).get("stdout", "").strip()
        if stdout == "4":
            print("   ✓ Code execution: print(2+2) = 4")
            passed += 1
        else:
            print(f"   ✗ Unexpected output: {stdout}")
    else:
        print("   ✗ Code execution failed")

    # 6. Test echo tool
    print("6. Testing echo tool...")
    echo = curl(
        "http://localhost:18001/mcp/execute", "POST",
        '{"tool":"echo","arguments":{"message":"hello MCP"}}'
    )
    if echo and "hello MCP" in echo:
        print("   ✓ Echo tool works")
        passed += 1
    else:
        print("   ✗ Echo failed")

    # Cleanup
    if pf_pid:
        try:
            subprocess.run(f"kill {pf_pid}", shell=True, capture_output=True)
        except Exception:
            pass

    print(f"\n=== {passed}/{total} checks passed ===")
    sys.exit(0 if passed == total else 1)


if __name__ == "__main__":
    main()
