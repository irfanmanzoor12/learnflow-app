#!/bin/bash
set -e

APP_DIR="${1:-/tmp/fastapi-dapr-agent}"

echo "=== Creating FastAPI Dapr Agent Application ==="

mkdir -p "$APP_DIR/app"

# 1. Create main application
cat <<'PYEOF' > "$APP_DIR/app/main.py"
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import httpx
import os
import logging
from typing import Dict, Any, Optional
import asyncpg

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="FastAPI Dapr Agent", version="1.0.0")

DAPR_HTTP_PORT = os.getenv("DAPR_HTTP_PORT", "3500")
DAPR_URL = f"http://localhost:{DAPR_HTTP_PORT}"
PUBSUB_NAME = "kafka-pubsub"
TOPIC_NAME = "agent-events"
STATE_STORE_NAME = "postgres-statestore"

PG_HOST = os.getenv("POSTGRES_HOST", "postgres-postgresql.postgres.svc.cluster.local")
PG_PORT = os.getenv("POSTGRES_PORT", "5432")
PG_USER = os.getenv("POSTGRES_USER", "postgres")
PG_PASSWORD = os.getenv("POSTGRES_PASSWORD", "postgres")
PG_DATABASE = os.getenv("POSTGRES_DATABASE", "postgres")

db_pool: Optional[asyncpg.Pool] = None

class EventData(BaseModel):
    message: str
    metadata: Dict[str, Any] = {}

class StateData(BaseModel):
    key: str
    value: Dict[str, Any]

@app.on_event("startup")
async def startup_event():
    global db_pool
    try:
        db_pool = await asyncpg.create_pool(
            host=PG_HOST, port=int(PG_PORT), user=PG_USER,
            password=PG_PASSWORD, database=PG_DATABASE,
            min_size=2, max_size=10
        )
        logger.info("PostgreSQL connection pool created")
    except Exception as e:
        logger.error(f"Failed to connect to PostgreSQL: {e}")

@app.on_event("shutdown")
async def shutdown_event():
    global db_pool
    if db_pool:
        await db_pool.close()

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "fastapi-dapr-agent"}

@app.get("/ready")
async def readiness():
    checks = {"api": "ok", "database": "unknown", "dapr": "unknown"}
    try:
        if db_pool:
            async with db_pool.acquire() as conn:
                await conn.fetchval("SELECT 1")
            checks["database"] = "ok"
    except Exception as e:
        checks["database"] = f"error: {str(e)}"
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.get(f"{DAPR_URL}/v1.0/healthz")
            checks["dapr"] = "ok" if resp.status_code == 204 else f"status: {resp.status_code}"
    except Exception as e:
        checks["dapr"] = f"error: {str(e)}"
    return checks

@app.post("/publish")
async def publish_event(event: EventData):
    async with httpx.AsyncClient() as client:
        resp = await client.post(
            f"{DAPR_URL}/v1.0/publish/{PUBSUB_NAME}/{TOPIC_NAME}",
            json=event.dict()
        )
        resp.raise_for_status()
    return {"status": "published", "topic": TOPIC_NAME}

@app.post("/subscribe")
async def subscribe_handler(event: Dict[str, Any]):
    logger.info(f"Received event: {event}")
    return {"status": "processed"}

@app.get("/dapr/subscribe")
async def dapr_subscribe():
    return [{"pubsubname": PUBSUB_NAME, "topic": TOPIC_NAME, "route": "/subscribe"}]

@app.post("/state")
async def save_state(state: StateData):
    async with httpx.AsyncClient() as client:
        resp = await client.post(
            f"{DAPR_URL}/v1.0/state/{STATE_STORE_NAME}",
            json=[{"key": state.key, "value": state.value}]
        )
        resp.raise_for_status()
    return {"status": "saved", "key": state.key}

@app.get("/state/{key}")
async def get_state(key: str):
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{DAPR_URL}/v1.0/state/{STATE_STORE_NAME}/{key}")
        if resp.status_code == 204:
            raise HTTPException(status_code=404, detail="Not found")
        resp.raise_for_status()
    return {"key": key, "value": resp.json()}

@app.delete("/state/{key}")
async def delete_state(key: str):
    async with httpx.AsyncClient() as client:
        resp = await client.delete(f"{DAPR_URL}/v1.0/state/{STATE_STORE_NAME}/{key}")
        resp.raise_for_status()
    return {"status": "deleted", "key": key}

@app.get("/db/query")
async def execute_query():
    if not db_pool:
        raise HTTPException(status_code=503, detail="DB pool not initialized")
    async with db_pool.acquire() as conn:
        version = await conn.fetchval("SELECT version()")
        table_count = await conn.fetchval(
            "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public'"
        )
    return {"status": "ok", "postgres_version": version.split(",")[0], "table_count": table_count}

@app.get("/")
async def root():
    return {"service": "FastAPI Dapr Agent", "version": "1.0.0"}
PYEOF

# 2. Create requirements.txt
cat <<'EOF' > "$APP_DIR/requirements.txt"
fastapi==0.104.1
uvicorn[standard]==0.24.0
httpx==0.25.1
pydantic==2.5.0
asyncpg==0.29.0
EOF

# 3. Create Dockerfile
cat <<'EOF' > "$APP_DIR/Dockerfile"
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app/ ./app/
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

echo "✓ FastAPI Dapr Agent application created at ${APP_DIR}"
