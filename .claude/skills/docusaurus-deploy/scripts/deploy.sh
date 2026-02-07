#!/bin/bash
set -e

APP_DIR="${1:-/tmp/docusaurus-site}"

echo "=== Deploying Docusaurus to Kubernetes ==="

# 1. Prerequisites
echo "Checking prerequisites..."
minikube status > /dev/null 2>&1 || { echo "✗ Minikube not running"; exit 1; }
docker --version > /dev/null 2>&1 || { echo "✗ Docker not installed"; exit 1; }
echo "✓ Prerequisites OK"

# 2. Install deps
echo "Installing dependencies..."
cd "$APP_DIR"
npm ci --silent > /dev/null 2>&1
echo "✓ Dependencies installed"

# 3. Build and load image
echo "Building Docker image (this may take a minute)..."
docker build -t docusaurus-site:latest "$APP_DIR" > /dev/null 2>&1
minikube image load docusaurus-site:latest > /dev/null 2>&1
echo "✓ Image built and loaded"

# 4. Create namespace
echo "Creating namespace..."
kubectl create namespace docs --dry-run=client -o yaml | kubectl apply -f - > /dev/null
echo "✓ Namespace ready"

# 5. Deploy
echo "Deploying to Kubernetes..."
cat <<EOF | kubectl apply -f - > /dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: docusaurus
  namespace: docs
spec:
  replicas: 2
  selector:
    matchLabels:
      app: docusaurus
  template:
    metadata:
      labels:
        app: docusaurus
    spec:
      containers:
      - name: docusaurus
        image: docusaurus-site:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 5
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "256Mi"
            cpu: "250m"
---
apiVersion: v1
kind: Service
metadata:
  name: docusaurus
  namespace: docs
spec:
  type: ClusterIP
  selector:
    app: docusaurus
  ports:
  - port: 80
    targetPort: 80
EOF

# 6. Wait
echo "Waiting for deployment..."
kubectl wait --for=condition=available deployment/docusaurus -n docs --timeout=300s > /dev/null 2>&1
echo "✓ Deployment ready"

echo ""
echo "=== ✓ Docusaurus deployed (2 replicas) ==="
echo "Service: docusaurus.docs.svc.cluster.local:80"
