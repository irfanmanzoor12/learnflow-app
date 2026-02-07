#!/bin/bash
set -e

APP_DIR="${1:-/tmp/mcp-code-execution}"

echo "=== Deploying MCP Code Execution Server ==="

# 1. Check prerequisites
echo "Checking prerequisites..."
minikube status > /dev/null 2>&1 || { echo "✗ Minikube not running"; exit 1; }
docker --version > /dev/null 2>&1 || { echo "✗ Docker not installed"; exit 1; }
echo "✓ Prerequisites OK"

# 2. Build and load image
echo "Building Docker image..."
docker build -t mcp-code-execution:latest "$APP_DIR" > /dev/null 2>&1
minikube image load mcp-code-execution:latest > /dev/null 2>&1
echo "✓ Image built and loaded"

# 3. Create namespace
echo "Creating namespace..."
kubectl create namespace mcp-server --dry-run=client -o yaml | kubectl apply -f - > /dev/null
echo "✓ Namespace ready"

# 4. Deploy
echo "Deploying to Kubernetes..."
cat <<EOF | kubectl apply -f - > /dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mcp-code-execution
  namespace: mcp-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mcp-code-execution
  template:
    metadata:
      labels:
        app: mcp-code-execution
    spec:
      containers:
      - name: mcp-server
        image: mcp-code-execution:latest
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
  name: mcp-code-execution
  namespace: mcp-server
spec:
  type: ClusterIP
  selector:
    app: mcp-code-execution
  ports:
  - port: 80
    targetPort: 8000
EOF

# 5. Wait
echo "Waiting for deployment..."
kubectl wait --for=condition=available deployment/mcp-code-execution -n mcp-server --timeout=300s > /dev/null 2>&1
echo "✓ Deployment ready"

echo ""
echo "=== ✓ MCP Code Execution server deployed ==="
echo "Service: mcp-code-execution.mcp-server.svc.cluster.local:80"
