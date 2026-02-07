#!/bin/bash
set -e

echo "=== PostgreSQL K8s Setup ==="

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
echo "Creating postgres namespace..."
kubectl create namespace postgres --dry-run=client -o yaml | kubectl apply -f - > /dev/null
echo "✓ Namespace ready"

# 4. Install PostgreSQL
echo "Installing PostgreSQL via Helm..."
helm upgrade --install postgres bitnami/postgresql \
  --namespace postgres \
  --set auth.postgresPassword=postgres \
  --set auth.database=learnflow \
  --set primary.persistence.enabled=true \
  --set primary.persistence.size=1Gi \
  --wait --timeout 5m

echo "✓ PostgreSQL deployed to namespace 'postgres'"

# 5. Wait for pods
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=postgresql -n postgres --timeout=300s > /dev/null 2>&1
echo "✓ PostgreSQL pod running"

echo ""
echo "=== ✓ PostgreSQL deployment complete ==="
echo "Host: postgres-postgresql.postgres.svc.cluster.local:5432"
echo "Database: learnflow"
echo "User: postgres"
