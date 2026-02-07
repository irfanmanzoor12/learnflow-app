#!/bin/bash
set -e

APP_DIR="${1:-/tmp/nextjs-k8s-app}"

echo "=== Deploying Next.js to Kubernetes ==="

# 1. Prerequisites
echo "Checking prerequisites..."
minikube status > /dev/null 2>&1 || { echo "✗ Minikube not running"; exit 1; }
docker --version > /dev/null 2>&1 || { echo "✗ Docker not installed"; exit 1; }
echo "✓ Prerequisites OK"

# 2. Install deps and build
echo "Installing dependencies..."
cd "$APP_DIR"
npm ci --silent > /dev/null 2>&1
echo "✓ Dependencies installed"

# 3. Build and load image
echo "Building Docker image (this may take a minute)..."
docker build -t nextjs-k8s-app:latest "$APP_DIR" > /dev/null 2>&1
minikube image load nextjs-k8s-app:latest > /dev/null 2>&1
echo "✓ Image built and loaded"

# 4. Create namespace
echo "Creating namespace..."
kubectl create namespace nextjs-app --dry-run=client -o yaml | kubectl apply -f - > /dev/null
echo "✓ Namespace ready"

# 5. Deploy
echo "Deploying to Kubernetes..."
cat <<EOF | kubectl apply -f - > /dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nextjs-app
  namespace: nextjs-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nextjs-app
  template:
    metadata:
      labels:
        app: nextjs-app
    spec:
      containers:
      - name: nextjs
        image: nextjs-k8s-app:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 3000
        livenessProbe:
          httpGet:
            path: /api/health
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /api/ready
            port: 3000
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
  name: nextjs-app
  namespace: nextjs-app
spec:
  type: ClusterIP
  selector:
    app: nextjs-app
  ports:
  - port: 80
    targetPort: 3000
EOF

# 6. Wait
echo "Waiting for deployment..."
kubectl wait --for=condition=available deployment/nextjs-app -n nextjs-app --timeout=300s > /dev/null 2>&1
echo "✓ Deployment ready"

echo ""
echo "=== ✓ Next.js deployed (2 replicas) ==="
echo "Service: nextjs-app.nextjs-app.svc.cluster.local:80"
