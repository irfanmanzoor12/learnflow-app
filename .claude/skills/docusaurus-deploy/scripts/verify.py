#!/usr/bin/env python3
"""Verify Docusaurus deployment on Kubernetes."""
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
    print("=== Docusaurus Verification ===\n")
    passed = 0
    total = 4
    pf_pid = None

    # 1. Check pods
    print("1. Checking pods...")
    output = run("kubectl get pods -n docs -l app=docusaurus -o json")
    if output:
        pods = json.loads(output)["items"]
        running = sum(1 for p in pods if p["status"]["phase"] == "Running")
        if running > 0:
            print(f"   ✓ {running}/{len(pods)} pods running")
            passed += 1
        else:
            print("   ✗ No running pods")
    else:
        print("   ✗ Cannot find pods")

    # 2. Port forward
    print("2. Setting up port forward...")
    pf = subprocess.Popen(
        "kubectl port-forward -n docs svc/docusaurus 18003:80".split(),
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )
    pf_pid = pf.pid
    time.sleep(3)

    # 3. Test health
    print("3. Testing health endpoint...")
    health = curl("http://localhost:18003/health")
    if health and "healthy" in health:
        print("   ✓ Health OK")
        passed += 1
    else:
        print("   ✗ Health failed")

    # 4. Test homepage
    print("4. Testing homepage...")
    page = curl("http://localhost:18003/")
    if page and ("docusaurus" in page.lower() or "html" in page.lower() or "LearnFlow" in page):
        print("   ✓ Homepage loads")
        passed += 1
    else:
        print("   ✗ Homepage failed")

    # 5. Check replicas
    output = run("kubectl get deployment docusaurus -n docs -o json")
    if output:
        dep = json.loads(output)
        ready = dep["status"].get("readyReplicas", 0)
        if ready >= 2:
            print(f"   ✓ {ready} replicas (HA)")
            passed += 1
        else:
            print(f"   ✗ Only {ready} replicas")

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
