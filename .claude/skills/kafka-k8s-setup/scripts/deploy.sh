#!/bin/bash
set -e

echo "=== Kafka K8s Setup ==="

# 1. Check prerequisites
echo "Checking prerequisites..."
minikube status > /dev/null 2>&1 || { echo "✗ Minikube not running"; exit 1; }
kubectl cluster-info > /dev/null 2>&1 || { echo "✗ kubectl not configured"; exit 1; }
helm version --short > /dev/null 2>&1 || { echo "✗ Helm not installed"; exit 1; }
echo "✓ Prerequisites OK"

# 2. Add Bitnami Helm repository
echo "Adding Bitnami Helm repo..."
helm repo add bitnami https://charts.bitnami.com/bitnami 2>/dev/null || true
helm repo update > /dev/null
echo "✓ Helm repo ready"

# 3. Create namespace
echo "Creating kafka namespace..."
kubectl create namespace kafka --dry-run=client -o yaml | kubectl apply -f - > /dev/null
echo "✓ Namespace ready"

# 4. Install Kafka
echo "Installing Kafka via Helm (this may take a few minutes)..."
helm upgrade --install kafka bitnami/kafka \
  --namespace kafka \
  --set replicaCount=1 \
  --set zookeeper.replicaCount=1 \
  --set listeners.client.protocol=PLAINTEXT \
  --set listeners.controller.protocol=PLAINTEXT \
  --set listeners.interbroker.protocol=PLAINTEXT \
  --set persistence.enabled=false \
  --wait --timeout 5m

echo "✓ Kafka deployed to namespace 'kafka'"

# 5. Wait for pods
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=kafka -n kafka --timeout=300s > /dev/null 2>&1
echo "✓ All Kafka pods running"

echo ""
echo "=== ✓ Kafka deployment complete ==="
echo "Broker address: kafka.kafka.svc.cluster.local:9092"
