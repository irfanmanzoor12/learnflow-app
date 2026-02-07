#!/bin/bash
set -e

APP_DIR="${1:-/tmp/fastapi-dapr-agent}"

echo "=== Deploying FastAPI Dapr Agent ==="

# 1. Check prerequisites
echo "Checking prerequisites..."
minikube status > /dev/null 2>&1 || { echo "✗ Minikube not running"; exit 1; }
docker --version > /dev/null 2>&1 || { echo "✗ Docker not installed"; exit 1; }
dapr --version > /dev/null 2>&1 || { echo "✗ Dapr CLI not installed"; exit 1; }
echo "✓ Prerequisites OK"

# 2. Ensure Dapr is on K8s
echo "Checking Dapr on Kubernetes..."
kubectl get pods -n dapr-system > /dev/null 2>&1 || {
    echo "Installing Dapr on Kubernetes..."
    dapr init -k
    kubectl wait --for=condition=Ready pod -l app=dapr-operator -n dapr-system --timeout=300s > /dev/null 2>&1
}
echo "✓ Dapr ready"

# 3. Create namespace
echo "Creating namespace..."
kubectl create namespace fastapi-app --dry-run=client -o yaml | kubectl apply -f - > /dev/null
kubectl label namespace fastapi-app dapr.io/enabled=true --overwrite > /dev/null
echo "✓ Namespace ready"

# 4. Create Dapr components
echo "Creating Dapr components..."

# Kafka pubsub
cat <<EOF | kubectl apply -f - > /dev/null
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: kafka-pubsub
  namespace: fastapi-app
spec:
  type: pubsub.kafka
  version: v1
  metadata:
  - name: brokers
    value: "kafka.kafka.svc.cluster.local:9092"
  - name: authType
    value: "none"
  - name: consumerGroup
    value: "fastapi-consumer-group"
EOF

# PostgreSQL state store
POSTGRES_PASSWORD=$(kubectl get secret -n postgres postgres-postgresql -o jsonpath="{.data.postgres-password}" 2>/dev/null | base64 --decode 2>/dev/null || echo "postgres")

cat <<EOF | kubectl apply -f - > /dev/null
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: postgres-statestore
  namespace: fastapi-app
spec:
  type: state.postgresql
  version: v1
  metadata:
  - name: connectionString
    value: "host=postgres-postgresql.postgres.svc.cluster.local user=postgres password=${POSTGRES_PASSWORD} port=5432 database=postgres sslmode=disable"
  - name: tableName
    value: "dapr_state"
EOF
echo "✓ Dapr components created"

# 5. Build and load Docker image
echo "Building Docker image..."
docker build -t fastapi-dapr-agent:latest "$APP_DIR" > /dev/null 2>&1
minikube image load fastapi-dapr-agent:latest > /dev/null 2>&1
echo "✓ Image built and loaded"

# 6. Create postgres credentials secret
kubectl create secret generic postgres-credentials \
  --from-literal=password="${POSTGRES_PASSWORD}" \
  --namespace=fastapi-app \
  --dry-run=client -o yaml | kubectl apply -f - > /dev/null

# 7. Deploy to Kubernetes
echo "Deploying to Kubernetes..."
cat <<EOF | kubectl apply -f - > /dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fastapi-dapr-agent
  namespace: fastapi-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: fastapi-dapr-agent
  template:
    metadata:
      labels:
        app: fastapi-dapr-agent
      annotations:
        dapr.io/enabled: "true"
        dapr.io/app-id: "fastapi-dapr-agent"
        dapr.io/app-port: "8000"
    spec:
      containers:
      - name: fastapi
        image: fastapi-dapr-agent:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 8000
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-credentials
              key: password
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
  name: fastapi-dapr-agent
  namespace: fastapi-app
spec:
  type: ClusterIP
  selector:
    app: fastapi-dapr-agent
  ports:
  - port: 80
    targetPort: 8000
EOF

# 8. Wait for deployment
echo "Waiting for deployment..."
kubectl wait --for=condition=available deployment/fastapi-dapr-agent -n fastapi-app --timeout=300s > /dev/null 2>&1
echo "✓ Deployment ready"

echo ""
echo "=== ✓ FastAPI Dapr Agent deployed ==="
echo "Service: fastapi-dapr-agent.fastapi-app.svc.cluster.local:80"
