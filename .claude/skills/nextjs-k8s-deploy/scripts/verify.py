#!/usr/bin/env python3
"""Verify Next.js deployment on Kubernetes."""
import subprocess
import json
import sys
import time


def run(cmd):
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return result.stdout.strip() if result.returncode == 0 else None


def curl(url):
    return run(f"curl -s {url}")


def main():
    print("=== Next.js Verification ===\n")
    passed = 0
    total = 5
    pf_pid = None

    # 1. Check pods
    print("1. Checking pods...")
    output = run("kubectl get pods -n nextjs-app -l app=nextjs-app -o json")
    if output:
        pods = json.loads(output)["items"]
        running = sum(1 for p in pods if p["status"]["phase"] == "Running")
        print(f"   ✓ {running}/{len(pods)} pods running") if running > 0 else print("   ✗ No running pods")
        if running > 0:
            passed += 1
    else:
        print("   ✗ Cannot find pods")

    # 2. Check replicas
    print("2. Checking replicas...")
    output = run("kubectl get deployment nextjs-app -n nextjs-app -o json")
    if output:
        dep = json.loads(output)
        ready = dep["status"].get("readyReplicas", 0)
        desired = dep["spec"]["replicas"]
        if ready >= desired:
            print(f"   ✓ {ready}/{desired} replicas ready")
            passed += 1
        else:
            print(f"   ✗ {ready}/{desired} replicas ready")
    else:
        print("   ✗ Deployment not found")

    # 3. Port forward and test
    print("3. Testing health endpoint...")
    pf = subprocess.Popen(
        "kubectl port-forward -n nextjs-app svc/nextjs-app 18002:80".split(),
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )
    pf_pid = pf.pid
    time.sleep(3)

    health = curl("http://localhost:18002/api/health")
    if health and "healthy" in health:
        print("   ✓ Health OK")
        passed += 1
    else:
        print("   ✗ Health failed")

    # 4. Test readiness
    print("4. Testing readiness...")
    ready = curl("http://localhost:18002/api/ready")
    if ready and "ready" in ready:
        print("   ✓ Readiness OK")
        passed += 1
    else:
        print("   ✗ Readiness failed")

    # 5. Test homepage
    print("5. Testing homepage...")
    page = curl("http://localhost:18002/")
    if page and ("LearnFlow" in page or "html" in page.lower()):
        print("   ✓ Homepage renders")
        passed += 1
    else:
        print("   ✗ Homepage failed")

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
