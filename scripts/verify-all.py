#!/usr/bin/env python3
"""Verify the complete LearnFlow stack deployment."""
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


def check_pods(namespace, label):
    output = run(f"kubectl get pods -n {namespace} -l app={label} -o json")
    if not output:
        return False
    pods = json.loads(output)["items"]
    return any(p["status"]["phase"] == "Running" for p in pods)


def main():
    print("=" * 50)
    print("  LearnFlow - Full Stack Verification")
    print("=" * 50)
    print()

    passed = 0
    total = 10
    pf_pids = []

    # ── Infrastructure ──
    print("=== Infrastructure ===\n")

    # 1. Kafka
    print("1. Kafka pods...")
    if check_pods("kafka", "kafka"):
        print("   ✓ Kafka running")
        passed += 1
    else:
        print("   ✗ Kafka not running")

    # 2. PostgreSQL
    print("2. PostgreSQL pods...")
    if run("kubectl get pods -n postgres -l app.kubernetes.io/name=postgresql -o jsonpath='{.items[0].status.phase}'") == "Running":
        print("   ✓ PostgreSQL running")
        passed += 1
    else:
        print("   ✗ PostgreSQL not running")

    # 3. Database tables
    print("3. Database schema...")
    tables = run(
        "kubectl exec -n postgres postgres-postgresql-0 -- "
        "psql -U postgres -d learnflow -t -c \"SELECT count(*) FROM information_schema.tables WHERE table_schema='public'\" 2>/dev/null"
    )
    if tables and int(tables.strip()) >= 4:
        print(f"   ✓ {tables.strip()} tables found")
        passed += 1
    else:
        print(f"   ✗ Expected 4+ tables, got: {tables}")

    # ── LearnFlow Services ──
    print("\n=== LearnFlow Services ===\n")

    # 4. Triage agent pod
    print("4. Triage agent pod...")
    if check_pods("learnflow", "triage-agent"):
        print("   ✓ Running")
        passed += 1
    else:
        print("   ✗ Not running")

    # 5. Concepts agent pod
    print("5. Concepts agent pod...")
    if check_pods("learnflow", "concepts-agent"):
        print("   ✓ Running")
        passed += 1
    else:
        print("   ✗ Not running")

    # 6. Code runner pod
    print("6. Code runner pod...")
    if check_pods("learnflow", "code-runner"):
        print("   ✓ Running")
        passed += 1
    else:
        print("   ✗ Not running")

    # ── Endpoint Tests ──
    print("\n=== Endpoint Tests ===\n")

    # Port forward services
    print("   Setting up port forwards...")
    for svc, port in [("triage-agent", 18010), ("concepts-agent", 18011), ("code-runner", 18012)]:
        pf = subprocess.Popen(
            f"kubectl port-forward -n learnflow svc/{svc} {port}:80".split(),
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
        pf_pids.append(pf.pid)
    time.sleep(4)

    # 7. Triage health
    print("7. Triage agent health...")
    health = curl("http://localhost:18010/health")
    if health and "healthy" in health:
        print("   ✓ Health OK")
        passed += 1
    else:
        print("   ✗ Health failed")

    # 8. Concepts agent health
    print("8. Concepts agent health...")
    health = curl("http://localhost:18011/health")
    if health and "healthy" in health:
        print("   ✓ Health OK")
        passed += 1
    else:
        print("   ✗ Health failed")

    # 9. Chat flow (triage → concepts)
    print("9. Chat flow test...")
    chat = curl(
        "http://localhost:18010/chat", "POST",
        '{"message":"explain for loops in Python","user_id":1}'
    )
    if chat:
        data = json.loads(chat)
        agent = data.get("agent", "")
        intent = data.get("intent", "")
        has_response = len(data.get("response", "")) > 10
        if has_response:
            print(f"   ✓ Chat works (intent={intent}, agent={agent})")
            passed += 1
        else:
            print(f"   ✗ Empty response (agent={agent})")
    else:
        print("   ✗ Chat endpoint failed")

    # 10. Code execution
    print("10. Code execution test...")
    code_result = curl(
        "http://localhost:18012/execute", "POST",
        '{"code":"print(2+2)","language":"python","timeout":5}'
    )
    if code_result:
        data = json.loads(code_result)
        stdout = data.get("stdout", "").strip()
        if stdout == "4":
            print("   ✓ Code execution: print(2+2) = 4")
            passed += 1
        else:
            print(f"   ✗ Unexpected output: {stdout}")
    else:
        print("   ✗ Code execution failed")

    # ── Cleanup ──
    for pid in pf_pids:
        try:
            subprocess.run(f"kill {pid}", shell=True, capture_output=True)
        except Exception:
            pass

    # ── Summary ──
    print()
    print("=" * 50)
    status = "PASS" if passed == total else "PARTIAL"
    print(f"  {status}: {passed}/{total} checks passed")
    print("=" * 50)

    if passed < total:
        print("\nTip: Run 'kubectl get pods -n learnflow' to check pod status")
        print("     Run 'kubectl logs -n learnflow -l app=<name>' for logs")

    sys.exit(0 if passed == total else 1)


if __name__ == "__main__":
    main()
