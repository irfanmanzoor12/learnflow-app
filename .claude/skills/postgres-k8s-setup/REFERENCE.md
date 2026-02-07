# PostgreSQL K8s Setup - Reference

## Configuration

- **Chart**: bitnami/postgresql
- **Namespace**: postgres
- **Host**: postgres-postgresql.postgres.svc.cluster.local
- **Port**: 5432
- **Database**: learnflow
- **User**: postgres
- **Password**: postgres (dev only)
- **Persistence**: 1Gi PVC

## Connection String

```
postgresql://postgres:postgres@postgres-postgresql.postgres.svc.cluster.local:5432/learnflow
```

## Getting Password from Secret

```bash
kubectl get secret -n postgres postgres-postgresql -o jsonpath="{.data.postgres-password}" | base64 --decode
```

## Production Configuration

```bash
helm install postgres bitnami/postgresql \
  --namespace postgres \
  --set auth.postgresPassword=<secure-password> \
  --set auth.database=learnflow \
  --set primary.persistence.size=50Gi \
  --set primary.resources.requests.memory=256Mi \
  --set primary.resources.limits.memory=1Gi \
  --set metrics.enabled=true
```

## Common Pitfalls

- Password is stored in a Kubernetes Secret (base64 encoded)
- PVC must be available (Minikube provides default storage class)
- Pod name is `postgres-postgresql-0` (StatefulSet naming)

## Agent Hints

- **Wait for pod**: `kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=postgresql -n postgres --timeout=300s`
- **Quick test**: `kubectl exec -n postgres postgres-postgresql-0 -- psql -U postgres -c "SELECT 1"`
- **Cross-namespace access**: Other services reference `postgres-postgresql.postgres.svc.cluster.local:5432`

## psql Commands

```bash
# Connect interactively
kubectl exec -it -n postgres postgres-postgresql-0 -- psql -U postgres -d learnflow

# Run single command
kubectl exec -n postgres postgres-postgresql-0 -- psql -U postgres -d learnflow -c "SELECT * FROM table_name"

# List databases
kubectl exec -n postgres postgres-postgresql-0 -- psql -U postgres -c "\l"

# List tables
kubectl exec -n postgres postgres-postgresql-0 -- psql -U postgres -d learnflow -c "\dt"
```

## Cleanup

```bash
helm uninstall postgres -n postgres
kubectl delete namespace postgres
```

## References

- Bitnami PostgreSQL Chart: https://github.com/bitnami/charts/tree/main/bitnami/postgresql
- PostgreSQL Documentation: https://www.postgresql.org/docs/
