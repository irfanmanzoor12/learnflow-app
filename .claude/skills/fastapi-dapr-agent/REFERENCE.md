# FastAPI Dapr Agent - Reference

## API Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/health` | Liveness probe |
| GET | `/ready` | Readiness with dependency checks |
| POST | `/publish` | Publish event to Kafka via Dapr |
| POST | `/subscribe` | Handle Kafka events via Dapr |
| POST | `/state` | Save state to PostgreSQL via Dapr |
| GET | `/state/{key}` | Retrieve state via Dapr |
| DELETE | `/state/{key}` | Delete state via Dapr |
| GET | `/db/query` | Direct PostgreSQL connection test |

## Dapr Components

### Kafka Pub/Sub (`kafka-pubsub`)
- Broker: `kafka.kafka.svc.cluster.local:9092`
- Auth: none (dev)
- Consumer group: `fastapi-consumer-group`
- Topic: `agent-events`

### PostgreSQL State Store (`postgres-statestore`)
- Host: `postgres-postgresql.postgres.svc.cluster.local:5432`
- Table: `dapr_state`
- Database: `postgres`

## Configuration

- **Dapr HTTP port**: 3500
- **App port**: 8000
- **Service port**: 80 (ClusterIP)
- **Resources**: 128Mi-512Mi memory, 100m-500m CPU
- **Namespace**: `fastapi-app`

## Common Pitfalls

- Kafka and PostgreSQL must be deployed before this service
- Dapr components must be in the same namespace as the application
- PostgreSQL password must be extracted from the postgres namespace secret
- Image must be loaded into Minikube with `minikube image load`

## Agent Hints

- **Multi-container pods**: Use `-c fastapi` for app logs, `-c daprd` for Dapr logs
- **Debugging**: `kubectl logs -n fastapi-app -l app=fastapi-dapr-agent -c fastapi --tail=50`
- **Dapr logs**: `kubectl logs -n fastapi-app -l app=fastapi-dapr-agent -c daprd --tail=50`

## Cleanup

```bash
kubectl delete namespace fastapi-app
minikube image rm fastapi-dapr-agent:latest
rm -rf /tmp/fastapi-dapr-agent
```

## References

- Dapr: https://docs.dapr.io/
- FastAPI: https://fastapi.tiangolo.com/
- Dapr Kafka Component: https://docs.dapr.io/reference/components-reference/supported-pubsub/setup-apache-kafka/
- Dapr PostgreSQL Component: https://docs.dapr.io/reference/components-reference/supported-state-stores/setup-postgresql/
