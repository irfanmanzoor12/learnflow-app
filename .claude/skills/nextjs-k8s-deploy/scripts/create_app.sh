#!/bin/bash
set -e

APP_DIR="${1:-/tmp/nextjs-k8s-app}"

echo "=== Creating Next.js Application ==="

mkdir -p "$APP_DIR/src/app/api/health" "$APP_DIR/src/app/api/ready"

# 1. package.json
cat <<'EOF' > "$APP_DIR/package.json"
{
  "name": "nextjs-k8s-app",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "next": "14.2.3",
    "react": "^18.3.0",
    "react-dom": "^18.3.0"
  },
  "devDependencies": {
    "@types/node": "^20",
    "@types/react": "^18",
    "typescript": "^5"
  }
}
EOF

# 2. next.config.js (standalone output for minimal container)
cat <<'EOF' > "$APP_DIR/next.config.js"
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
};
module.exports = nextConfig;
EOF

# 3. tsconfig.json
cat <<'EOF' > "$APP_DIR/tsconfig.json"
{
  "compilerOptions": {
    "target": "es5",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{"name": "next"}],
    "paths": {"@/*": ["./src/*"]}
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx"],
  "exclude": ["node_modules"]
}
EOF

# 4. Home page
cat <<'EOF' > "$APP_DIR/src/app/page.tsx"
export default function Home() {
  return (
    <main style={{ padding: '2rem', fontFamily: 'system-ui' }}>
      <h1>LearnFlow</h1>
      <p>AI-Powered Python Tutoring Platform</p>
      <p>Deployed on Kubernetes via Skills</p>
    </main>
  );
}
EOF

# 5. Layout
cat <<'EOF' > "$APP_DIR/src/app/layout.tsx"
export const metadata = { title: 'LearnFlow', description: 'AI-Powered Python Tutoring' };
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="en"><body>{children}</body></html>;
}
EOF

# 6. Health API
cat <<'EOF' > "$APP_DIR/src/app/api/health/route.ts"
import { NextResponse } from 'next/server';
export async function GET() {
  return NextResponse.json({ status: 'healthy', service: 'nextjs-k8s-app' });
}
EOF

# 7. Ready API
cat <<'EOF' > "$APP_DIR/src/app/api/ready/route.ts"
import { NextResponse } from 'next/server';
export async function GET() {
  return NextResponse.json({ status: 'ready', timestamp: new Date().toISOString() });
}
EOF

# 8. Dockerfile (multi-stage, standalone)
cat <<'DOCKERFILE' > "$APP_DIR/Dockerfile"
FROM node:18-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:18-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
RUN addgroup --system --gid 1001 nodejs && adduser --system --uid 1001 nextjs
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
USER nextjs
EXPOSE 3000
ENV PORT=3000
CMD ["node", "server.js"]
DOCKERFILE

echo "✓ Next.js application created at ${APP_DIR}"
