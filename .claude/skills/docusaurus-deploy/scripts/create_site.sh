#!/bin/bash
set -e

APP_DIR="${1:-/tmp/docusaurus-site}"

echo "=== Creating Docusaurus Site ==="

mkdir -p "$APP_DIR/docs" "$APP_DIR/src/pages" "$APP_DIR/static/img"

# 1. package.json
cat <<'EOF' > "$APP_DIR/package.json"
{
  "name": "learnflow-docs",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "docusaurus": "docusaurus",
    "start": "docusaurus start",
    "build": "docusaurus build",
    "serve": "docusaurus serve"
  },
  "dependencies": {
    "@docusaurus/core": "3.1.0",
    "@docusaurus/preset-classic": "3.1.0",
    "prism-react-renderer": "^2.3.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  }
}
EOF

# 2. docusaurus.config.js
cat <<'EOF' > "$APP_DIR/docusaurus.config.js"
/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'LearnFlow Docs',
  tagline: 'AI-Powered Python Tutoring Platform',
  url: 'http://localhost',
  baseUrl: '/',
  onBrokenLinks: 'warn',
  favicon: 'img/favicon.ico',
  presets: [
    ['classic', {
      docs: { sidebarPath: './sidebars.js' },
      theme: { customCss: './src/css/custom.css' },
    }],
  ],
};
module.exports = config;
EOF

# 3. sidebars.js
cat <<'EOF' > "$APP_DIR/sidebars.js"
module.exports = {
  docs: [
    'intro',
    { type: 'category', label: 'Skills', items: ['skills/overview', 'skills/creating'] },
    { type: 'category', label: 'Architecture', items: ['architecture/overview'] },
  ],
};
EOF

# 4. Docs content
cat <<'EOF' > "$APP_DIR/docs/intro.md"
---
slug: /
sidebar_position: 1
---
# Welcome to LearnFlow

LearnFlow is an AI-powered Python tutoring platform built with cloud-native technologies.

## Quick Start
1. Deploy infrastructure with Skills
2. Launch backend services
3. Access the frontend
EOF

mkdir -p "$APP_DIR/docs/skills" "$APP_DIR/docs/architecture"

cat <<'EOF' > "$APP_DIR/docs/skills/overview.md"
---
sidebar_position: 1
---
# Skills Overview

Skills use the MCP Code Execution pattern: SKILL.md + scripts/ + REFERENCE.md.
EOF

cat <<'EOF' > "$APP_DIR/docs/skills/creating.md"
---
sidebar_position: 2
---
# Creating Skills

Each skill follows: SKILL.md (~100 tokens) + scripts (0 tokens) + REFERENCE.md (on-demand).
EOF

cat <<'EOF' > "$APP_DIR/docs/architecture/overview.md"
---
sidebar_position: 1
---
# Architecture

LearnFlow uses Kubernetes, Kafka, Dapr, FastAPI, and Next.js.
EOF

# 5. Custom CSS
mkdir -p "$APP_DIR/src/css"
cat <<'EOF' > "$APP_DIR/src/css/custom.css"
:root { --ifm-color-primary: #2e8555; }
EOF

# 6. Nginx config
cat <<'EOF' > "$APP_DIR/nginx.conf"
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    location /health {
        access_log off;
        return 200 '{"status":"healthy","service":"docusaurus"}';
        add_header Content-Type application/json;
    }

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml;
}
EOF

# 7. Dockerfile
cat <<'DOCKERFILE' > "$APP_DIR/Dockerfile"
FROM node:18-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine AS runner
COPY --from=builder /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
RUN chown -R nginx:nginx /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
DOCKERFILE

echo "✓ Docusaurus site created at ${APP_DIR}"
