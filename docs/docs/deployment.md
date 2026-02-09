---
sidebar_position: 4
---

# Deployment

## Prerequisites

- Minikube running: `minikube start --cpus=4 --memory=8192`
- Docker installed
- kubectl configured
- Helm 3.x installed
- Dapr CLI installed

## Single Command Deploy

```bash
bash scripts/deploy-all.sh
```

This orchestrates the full stack:

| Phase | What | How |
|-------|------|-----|
| 1 | Prerequisites check | Verifies all tools installed |
| 2 | Kafka + PostgreSQL | Via `kafka-k8s-setup` and `postgres-k8s-setup` skills |
| 3 | Database migrations | Creates 4 tables + seed data |
| 4 | Dapr + namespace | Creates `learnflow` namespace with Dapr components |
| 5 | Backend services | Builds and deploys triage-agent, concepts-agent, code-runner |
| 6 | Frontend | Builds and deploys Next.js app |
| 7 | Wait | Waits for all deployments to be ready |

## Verify

```bash
python3 scripts/verify-all.py
```

Runs 10 checks: infrastructure, pods, health endpoints, chat flow, code execution.

## Access Services

```bash
# Frontend
kubectl port-forward -n learnflow svc/learnflow-frontend 3000:80
# Open http://localhost:3000

# Triage agent API
kubectl port-forward -n learnflow svc/triage-agent 8001:80

# Code runner API
kubectl port-forward -n learnflow svc/code-runner 8000:80
```

## Kubernetes Resources

After deployment:

```bash
kubectl get pods -n learnflow
# NAME                                 READY   STATUS
# triage-agent-xxx                     2/2     Running   (app + Dapr sidecar)
# concepts-agent-xxx                   2/2     Running
# code-runner-xxx                      2/2     Running
# learnflow-frontend-xxx               1/1     Running

kubectl get pods -n kafka
# kafka-0                              1/1     Running

kubectl get pods -n postgres
# postgres-postgresql-0                1/1     Running
```
