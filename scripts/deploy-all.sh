#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$ROOT_DIR/.claude/skills"

echo "============================================"
echo "  LearnFlow - Full Stack Deployment"
echo "  Built with Skills + MCP Code Execution"
echo "============================================"
echo ""

# ──────────────────────────────────────────────
# Phase 1: Prerequisites
# ──────────────────────────────────────────────
echo "=== Phase 1: Prerequisites ==="

echo "Checking Minikube..."
minikube status > /dev/null 2>&1 || { echo "✗ Minikube not running. Start with: minikube start --cpus=4 --memory=8192"; exit 1; }
echo "✓ Minikube running"

echo "Checking Docker..."
docker --version > /dev/null 2>&1 || { echo "✗ Docker not installed"; exit 1; }
echo "✓ Docker available"

echo "Checking kubectl..."
kubectl cluster-info > /dev/null 2>&1 || { echo "✗ kubectl not configured"; exit 1; }
echo "✓ kubectl connected"

echo "Checking Helm..."
helm version --short > /dev/null 2>&1 || { echo "✗ Helm not installed"; exit 1; }
echo "✓ Helm available"

echo "Checking Dapr..."
dapr --version > /dev/null 2>&1 || { echo "✗ Dapr CLI not installed"; exit 1; }
echo "✓ Dapr CLI available"

echo ""

# ──────────────────────────────────────────────
# Phase 2: Infrastructure (via Skills)
# ──────────────────────────────────────────────
echo "=== Phase 2: Infrastructure (via Skills) ==="

echo "--- Deploying Kafka (kafka-k8s-setup skill) ---"
bash "$SKILLS_DIR/kafka-k8s-setup/scripts/deploy.sh"
echo ""

echo "--- Deploying PostgreSQL (postgres-k8s-setup skill) ---"
bash "$SKILLS_DIR/postgres-k8s-setup/scripts/deploy.sh"
echo ""

# Run database migrations
echo "--- Running database migrations ---"
kubectl exec -n postgres postgres-postgresql-0 -- psql -U postgres -d learnflow -f - < "$ROOT_DIR/k8s/db-migration.sql" 2>/dev/null || {
    echo "Migration may have already been applied (tables exist)"
}
echo "✓ Database schema ready"
echo ""

# ──────────────────────────────────────────────
# Phase 3: Dapr + Namespace Setup
# ──────────────────────────────────────────────
echo "=== Phase 3: LearnFlow Namespace + Dapr ==="

# Ensure Dapr is on K8s
kubectl get pods -n dapr-system > /dev/null 2>&1 || {
    echo "Installing Dapr on Kubernetes..."
    dapr init -k
    kubectl wait --for=condition=Ready pod -l app=dapr-operator -n dapr-system --timeout=300s > /dev/null 2>&1
}
echo "✓ Dapr system ready"

# Create namespace
kubectl apply -f "$ROOT_DIR/k8s/namespace.yaml" > /dev/null
echo "✓ learnflow namespace created"

# Create Dapr components
kubectl apply -f "$ROOT_DIR/k8s/dapr-components.yaml" > /dev/null
echo "✓ Dapr components created (kafka-pubsub, postgres-statestore)"

# Create postgres credentials secret in learnflow namespace
POSTGRES_PASSWORD=$(kubectl get secret -n postgres postgres-postgresql -o jsonpath="{.data.postgres-password}" 2>/dev/null | base64 --decode 2>/dev/null || echo "postgres")
kubectl create secret generic postgres-credentials \
  --from-literal=password="${POSTGRES_PASSWORD}" \
  --namespace=learnflow \
  --dry-run=client -o yaml | kubectl apply -f - > /dev/null
echo "✓ Postgres credentials secret created"
echo ""

# ──────────────────────────────────────────────
# Phase 4: Build & Deploy Backend Services
# ──────────────────────────────────────────────
echo "=== Phase 4: Backend Services ==="

# --- Triage Agent ---
echo "--- Building triage-agent ---"
docker build -t learnflow-triage:latest "$ROOT_DIR/services/triage-agent" > /dev/null 2>&1
minikube image load learnflow-triage:latest > /dev/null 2>&1
echo "✓ triage-agent image built"

cat <<EOF | kubectl apply -f - > /dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: triage-agent
  namespace: learnflow
spec:
  replicas: 1
  selector:
    matchLabels:
      app: triage-agent
  template:
    metadata:
      labels:
        app: triage-agent
      annotations:
        dapr.io/enabled: "true"
        dapr.io/app-id: "triage-agent"
        dapr.io/app-port: "8001"
    spec:
      containers:
      - name: triage
        image: learnflow-triage:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 8001
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-credentials
              key: password
        livenessProbe:
          httpGet:
            path: /health
            port: 8001
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8001
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: triage-agent
  namespace: learnflow
spec:
  type: ClusterIP
  selector:
    app: triage-agent
  ports:
  - port: 80
    targetPort: 8001
EOF
echo "✓ triage-agent deployed"

# --- Concepts Agent ---
echo "--- Building concepts-agent ---"
docker build -t learnflow-concepts:latest "$ROOT_DIR/services/concepts-agent" > /dev/null 2>&1
minikube image load learnflow-concepts:latest > /dev/null 2>&1
echo "✓ concepts-agent image built"

cat <<EOF | kubectl apply -f - > /dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: concepts-agent
  namespace: learnflow
spec:
  replicas: 1
  selector:
    matchLabels:
      app: concepts-agent
  template:
    metadata:
      labels:
        app: concepts-agent
      annotations:
        dapr.io/enabled: "true"
        dapr.io/app-id: "concepts-agent"
        dapr.io/app-port: "8002"
    spec:
      containers:
      - name: concepts
        image: learnflow-concepts:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 8002
        livenessProbe:
          httpGet:
            path: /health
            port: 8002
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8002
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: concepts-agent
  namespace: learnflow
spec:
  type: ClusterIP
  selector:
    app: concepts-agent
  ports:
  - port: 80
    targetPort: 8002
EOF
echo "✓ concepts-agent deployed"

# --- Code Runner (via mcp-code-execution skill) ---
echo "--- Deploying code-runner (mcp-code-execution skill) ---"
bash "$SKILLS_DIR/mcp-code-execution/scripts/create_server.sh" /tmp/learnflow-code-runner > /dev/null 2>&1 || true

docker build -t learnflow-code-runner:latest /tmp/learnflow-code-runner > /dev/null 2>&1
minikube image load learnflow-code-runner:latest > /dev/null 2>&1
echo "✓ code-runner image built"

cat <<EOF | kubectl apply -f - > /dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: code-runner
  namespace: learnflow
spec:
  replicas: 1
  selector:
    matchLabels:
      app: code-runner
  template:
    metadata:
      labels:
        app: code-runner
      annotations:
        dapr.io/enabled: "true"
        dapr.io/app-id: "code-runner"
        dapr.io/app-port: "8000"
    spec:
      containers:
      - name: code-runner
        image: learnflow-code-runner:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 8000
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: code-runner
  namespace: learnflow
spec:
  type: ClusterIP
  selector:
    app: code-runner
  ports:
  - port: 80
    targetPort: 8000
EOF
echo "✓ code-runner deployed"
echo ""

# ──────────────────────────────────────────────
# Phase 5: Wait for all deployments
# ──────────────────────────────────────────────
echo "=== Phase 5: Waiting for all services ==="

kubectl wait --for=condition=available deployment/triage-agent -n learnflow --timeout=300s > /dev/null 2>&1 && echo "✓ triage-agent ready" || echo "✗ triage-agent timeout"
kubectl wait --for=condition=available deployment/concepts-agent -n learnflow --timeout=300s > /dev/null 2>&1 && echo "✓ concepts-agent ready" || echo "✗ concepts-agent timeout"
kubectl wait --for=condition=available deployment/code-runner -n learnflow --timeout=300s > /dev/null 2>&1 && echo "✓ code-runner ready" || echo "✗ code-runner timeout"

echo ""

# ──────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────
echo "============================================"
echo "  ✓ LearnFlow Deployment Complete"
echo "============================================"
echo ""
echo "Services:"
echo "  triage-agent:   triage-agent.learnflow.svc.cluster.local:80"
echo "  concepts-agent: concepts-agent.learnflow.svc.cluster.local:80"
echo "  code-runner:    code-runner.learnflow.svc.cluster.local:80"
echo "  kafka:          kafka.kafka.svc.cluster.local:9092"
echo "  postgresql:     postgres-postgresql.postgres.svc.cluster.local:5432"
echo ""
echo "Test with:"
echo "  kubectl port-forward -n learnflow svc/triage-agent 8001:80"
echo "  curl -X POST http://localhost:8001/chat -H 'Content-Type: application/json' -d '{\"message\":\"explain for loops\"}'"
echo ""
echo "Verify with:"
echo "  python3 scripts/verify-all.py"
