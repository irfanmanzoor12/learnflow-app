# Kafka K8s Setup - Reference

## Configuration

- **Chart**: bitnami/kafka
- **Namespace**: kafka
- **Broker address**: kafka.kafka.svc.cluster.local:9092
- **Protocol**: PLAINTEXT (no auth/encryption for local dev)
- **Persistence**: Disabled (ephemeral data for dev)
- **Replicas**: 1 Kafka + 1 Zookeeper

## Production Configuration

For production, modify the Helm install:
```bash
helm install kafka bitnami/kafka \
  --namespace kafka \
  --set replicaCount=3 \
  --set zookeeper.replicaCount=3 \
  --set persistence.enabled=true \
  --set persistence.size=10Gi \
  --set listeners.client.protocol=SASL_PLAINTEXT
```

## Common Pitfalls

- If `helm repo add` fails, repo may already exist (safe to continue)
- Interactive consumer (`-it`) may not work in non-TTY environments - use `--timeout-ms 5000`
- Port-forward runs in background - kill with `pkill -f "port-forward.*kafka"`

## Agent Hints

- **Wait for pods**: `kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=kafka -n kafka --timeout=300s`
- **Non-interactive testing**: Use `--timeout-ms 5000 --max-messages 1` for consumer
- **Idempotency**: Playbook can be re-run; `helm upgrade --install` handles existing releases

## Manual Topic Commands

```bash
# Create topic
kubectl exec kafka-0 -n kafka -- kafka-topics.sh \
  --create --topic <name> --bootstrap-server localhost:9092 \
  --partitions 1 --replication-factor 1

# Produce message
echo "message" | kubectl exec -i kafka-0 -n kafka -- kafka-console-producer.sh \
  --topic <name> --bootstrap-server localhost:9092

# Consume message
kubectl exec kafka-0 -n kafka -- kafka-console-consumer.sh \
  --topic <name> --from-beginning --max-messages 1 \
  --bootstrap-server localhost:9092 --timeout-ms 5000
```

## Cleanup

```bash
helm uninstall kafka -n kafka
kubectl delete namespace kafka
```

## References

- Bitnami Kafka Helm Chart: https://github.com/bitnami/charts/tree/main/bitnami/kafka
- Apache Kafka Documentation: https://kafka.apache.org/documentation/
