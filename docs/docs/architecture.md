---
sidebar_position: 2
---

# Architecture

## System Overview

LearnFlow runs on Kubernetes with Dapr service mesh providing pub/sub messaging and state management.

```
┌──────────────────────────────────────────────────────────┐
│                   KUBERNETES CLUSTER                      │
│                                                           │
│  ┌──────────────┐    ┌──────────────┐   ┌─────────────┐ │
│  │ Triage Agent │───►│  Concepts    │   │ Code Runner │ │
│  │ (FastAPI)    │    │  Agent       │   │ (MCP Server)│ │
│  │ +Dapr sidecar│    │ (FastAPI)    │   │ +Dapr       │ │
│  │ Port: 8001   │    │ +Dapr        │   │ Port: 8000  │ │
│  └──────┬───────┘    │ Port: 8002   │   └─────────────┘ │
│         │            └──────────────┘                    │
│         ▼                                                │
│  ┌─────────────────────────────────────────────────┐    │
│  │                    KAFKA                         │    │
│  │  learning.routed | learning.response | code.*    │    │
│  └─────────────────────────────────────────────────┘    │
│         │                                                │
│         ▼                                                │
│  ┌──────────────┐          ┌──────────────────────────┐ │
│  │ PostgreSQL   │          │ Dapr Components          │ │
│  │ (learnflow)  │          │ • kafka-pubsub           │ │
│  │ 4 tables     │          │ • postgres-statestore    │ │
│  └──────────────┘          └──────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

## Communication Flow

1. **Student sends message** via Next.js frontend
2. **Triage Agent** classifies intent (concept question vs code execution)
3. Routes to **Concepts Agent** or **Code Runner** via Dapr service invocation
4. Publishes event to **Kafka** topic `learning.routed`
5. Specialist agent processes and responds
6. Response stored in **PostgreSQL** and returned to student

## Database Schema

| Table | Purpose |
|-------|---------|
| `users` | Student/teacher accounts |
| `conversations` | Chat history per user and agent |
| `progress` | Mastery tracking per module/topic (0-100%) |
| `code_submissions` | Code execution history with output |

## Namespaces

| Namespace | Services |
|-----------|----------|
| `learnflow` | triage-agent, concepts-agent, code-runner, frontend |
| `kafka` | Kafka broker (Bitnami Helm) |
| `postgres` | PostgreSQL (Bitnami Helm) |
| `dapr-system` | Dapr operator, sidecar injector |

## Technology Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Next.js 14 + Monaco Editor |
| Backend | FastAPI + Dapr sidecars |
| Messaging | Apache Kafka |
| Database | PostgreSQL |
| Service Mesh | Dapr (pub/sub, state, invocation) |
| Code Execution | MCP Server (sandboxed Python) |
| Orchestration | Kubernetes (Minikube) |
