# Next.js K8s Deploy - Reference

## Configuration

- **Framework**: Next.js 14.2.3 with App Router
- **Build**: Standalone output (minimal container)
- **Namespace**: nextjs-app
- **Port**: 3000 (container), 80 (service)
- **Replicas**: 2 (for HA)
- **User**: Non-root (UID 1001)

## Standalone Output

The `output: 'standalone'` config in next.config.js creates a self-contained build:
- No `node_modules` needed in production image
- Just `server.js` + `.next/static` files
- Dramatically smaller container (~100MB vs 1GB+)

## Multi-Stage Dockerfile

```
Stage 1 (builder): npm ci → npm run build → produces .next/standalone
Stage 2 (runner):  Copy standalone + static → node server.js
```

## Customization

### Adding Monaco Editor (for LearnFlow)
```bash
npm install @monaco-editor/react
```

### Environment Variables
Pass via Kubernetes env in the deployment manifest or ConfigMap.

### Scaling
```bash
kubectl scale deployment nextjs-app -n nextjs-app --replicas=3
```

## Agent Hints

- **Build issues**: Ensure `npm ci` runs before Docker build
- **Image size**: Standalone output keeps images small
- **Static files**: Must copy `.next/static` separately in Dockerfile

## Cleanup

```bash
kubectl delete namespace nextjs-app
minikube image rm nextjs-k8s-app:latest
rm -rf /tmp/nextjs-k8s-app
```

## References

- Next.js Standalone: https://nextjs.org/docs/app/api-reference/config/next-config-js/output
- Next.js Docker: https://github.com/vercel/next.js/tree/canary/examples/with-docker
