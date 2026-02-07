#!/usr/bin/env python3
"""Verify PostgreSQL deployment on Kubernetes."""
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
    print("=== PostgreSQL Verification ===\n")
    passed = 0
    total = 4

    # 1. Check pods
    print("1. Checking PostgreSQL pods...")
    output = run("kubectl get pods -n postgres -o json")
    if output:
        pods = json.loads(output)["items"]
        running = sum(1 for p in pods if p["status"]["phase"] == "Running")
        if running > 0:
            print(f"   ✓ {running}/{len(pods)} pods running")
            passed += 1
        else:
            print(f"   ✗ {running}/{len(pods)} pods running")
    else:
        print("   ✗ Cannot reach postgres namespace")

    # 2. Check service
    print("2. Checking PostgreSQL service...")
    output = run("kubectl get svc -n postgres -o json")
    if output:
        svcs = json.loads(output)["items"]
        svc_names = [s["metadata"]["name"] for s in svcs]
        print(f"   ✓ Services: {', '.join(svc_names)}")
        passed += 1
    else:
        print("   ✗ No services found")

    # 3. Test database connection
    print("3. Testing database connection...")
    result = run(
        "kubectl exec -n postgres postgres-postgresql-0 -- "
        "psql -U postgres -d learnflow -c 'SELECT version();' 2>&1"
    )
    if result and "PostgreSQL" in result:
        version_line = [l for l in result.split("\n") if "PostgreSQL" in l]
        if version_line:
            print(f"   ✓ Connected: {version_line[0].strip()[:60]}")
        passed += 1
    else:
        print("   ✗ Database connection failed")

    # 4. Test table creation
    print("4. Testing table operations...")
    result = run(
        "kubectl exec -n postgres postgres-postgresql-0 -- "
        "psql -U postgres -d learnflow -c "
        "\"CREATE TABLE IF NOT EXISTS _verify_test (id serial PRIMARY KEY, msg text); "
        "INSERT INTO _verify_test (msg) VALUES ('ok'); "
        "SELECT count(*) FROM _verify_test; "
        "DROP TABLE _verify_test;\" 2>&1"
    )
    if result and "DROP TABLE" in result:
        print("   ✓ Table create/insert/query/drop successful")
        passed += 1
    else:
        print("   ✗ Table operations failed")

    # Summary
    print(f"\n=== {passed}/{total} checks passed ===")
    sys.exit(0 if passed == total else 1)


if __name__ == "__main__":
    main()
