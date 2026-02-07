#!/usr/bin/env python3
"""Verify FastAPI Dapr Agent deployment on Kubernetes."""
import subprocess
import json
import sys
import time
import signal


def run(cmd):
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return result.stdout.strip() if result.returncode == 0 else None


def curl(url, method="GET", data=None):
    cmd = f"curl -s -X {method} {url}"
    if data:
        cmd += f" -H 'Content-Type: application/json' -d '{data}'"
    return run(cmd)


def main():
    print("=== FastAPI Dapr Agent Verification ===\n")
    passed = 0
    total = 6
    pf_pid = None

    # 1. Check pods
    print("1. Checking pods...")
    output = run("kubectl get pods -n fastapi-app -l app=fastapi-dapr-agent -o json")
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

    # 2. Check Dapr components
    print("2. Checking Dapr components...")
    kafka = run("kubectl get component kafka-pubsub -n fastapi-app -o name 2>/dev/null")
    pg = run("kubectl get component postgres-statestore -n fastapi-app -o name 2>/dev/null")
    if kafka and pg:
        print("   ✓ Kafka pubsub + PostgreSQL state store")
        passed += 1
    else:
        print(f"   ✗ Missing components (kafka={bool(kafka)}, pg={bool(pg)})")

    # 3. Port forward and test health
    print("3. Testing health endpoint...")
    pf = subprocess.Popen(
        "kubectl port-forward -n fastapi-app svc/fastapi-dapr-agent 18000:80".split(),
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )
    pf_pid = pf.pid
    time.sleep(3)

    health = curl("http://localhost:18000/health")
    if health and "healthy" in health:
        print("   ✓ Health OK")
        passed += 1
    else:
        print("   ✗ Health check failed")

    # 4. Test readiness
    print("4. Testing readiness...")
    ready = curl("http://localhost:18000/ready")
    if ready and "ok" in ready:
        print("   ✓ Readiness OK")
        passed += 1
    else:
        print(f"   ✗ Readiness: {ready}")

    # 5. Test state management
    print("5. Testing Dapr state...")
    save = curl("http://localhost:18000/state", "POST",
                '{"key":"verify-test","value":{"status":"ok"}}')
    if save and "saved" in save:
        get = curl("http://localhost:18000/state/verify-test")
        if get and "verify-test" in get:
            curl("http://localhost:18000/state/verify-test", "DELETE")
            print("   ✓ State save/get/delete OK")
            passed += 1
        else:
            print("   ✗ State get failed")
    else:
        print("   ✗ State save failed")

    # 6. Test pub/sub
    print("6. Testing Kafka pub/sub...")
    pub = curl("http://localhost:18000/publish", "POST",
               '{"message":"verify-test","metadata":{}}')
    if pub and "published" in pub:
        print("   ✓ Event published")
        passed += 1
    else:
        print("   ✗ Publish failed")

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
