#!/usr/bin/env python3
"""Verify Kafka deployment on Kubernetes."""
import subprocess
import json
import sys


def run(cmd, check=True):
    """Run a shell command and return stdout."""
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if check and result.returncode != 0:
        return None
    return result.stdout.strip()


def main():
    print("=== Kafka Verification ===\n")
    passed = 0
    total = 4

    # 1. Check pods
    print("1. Checking Kafka pods...")
    output = run("kubectl get pods -n kafka -o json")
    if output:
        pods = json.loads(output)["items"]
        running = sum(1 for p in pods if p["status"]["phase"] == "Running")
        if running > 0:
            print(f"   ✓ {running}/{len(pods)} pods running")
            passed += 1
        else:
            print(f"   ✗ {running}/{len(pods)} pods running")
    else:
        print("   ✗ Cannot reach kafka namespace")

    # 2. Check services
    print("2. Checking Kafka services...")
    output = run("kubectl get svc -n kafka -o json")
    if output:
        svcs = json.loads(output)["items"]
        print(f"   ✓ {len(svcs)} services found")
        passed += 1
    else:
        print("   ✗ No services found")

    # 3. Create test topic
    print("3. Creating test topic...")
    result = run(
        "kubectl exec kafka-0 -n kafka -- kafka-topics.sh "
        "--create --if-not-exists --topic verify-test "
        "--bootstrap-server localhost:9092 "
        "--partitions 1 --replication-factor 1 2>&1"
    )
    if result is not None:
        print("   ✓ Test topic created")
        passed += 1
    else:
        print("   ✗ Failed to create topic")

    # 4. List topics
    print("4. Listing topics...")
    result = run(
        "kubectl exec kafka-0 -n kafka -- kafka-topics.sh "
        "--list --bootstrap-server localhost:9092 2>&1"
    )
    if result and "verify-test" in result:
        print("   ✓ Topic 'verify-test' confirmed")
        passed += 1
    else:
        print("   ✗ Topic not found")

    # Summary
    print(f"\n=== {passed}/{total} checks passed ===")
    sys.exit(0 if passed == total else 1)


if __name__ == "__main__":
    main()
