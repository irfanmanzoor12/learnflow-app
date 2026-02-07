# Docusaurus Deploy - Reference

## Configuration

- **Framework**: Docusaurus v3.1.0
- **Server**: Nginx Alpine
- **Namespace**: docs
- **Port**: 80
- **Replicas**: 2 (HA)
- **Caching**: 1-year for static assets
- **Compression**: Gzip enabled

## Nginx Features

- SPA routing (`try_files`)
- Static asset caching (1 year, immutable)
- Gzip compression for text/CSS/JS
- Custom `/health` endpoint
- Security headers ready

## Adding Content

```bash
# Create new doc
echo "---\nsidebar_position: 3\n---\n# My Page\nContent here" > docs/my-page.md

# Rebuild
npm run build
docker build -t docusaurus-site:latest .
minikube image load docusaurus-site:latest
kubectl rollout restart deployment/docusaurus -n docs
```

## Customization

- **Theme**: Edit `src/css/custom.css`
- **Config**: Edit `docusaurus.config.js`
- **Sidebar**: Edit `sidebars.js`
- **Plugins**: Add search, analytics, etc.

## Agent Hints

- **Build time**: First build may take 60-90s (downloading deps)
- **Rebuild**: After content changes, rebuild image and restart deployment
- **Static files**: Served directly by Nginx (no Node.js runtime needed)

## Cleanup

```bash
kubectl delete namespace docs
minikube image rm docusaurus-site:latest
rm -rf /tmp/docusaurus-site
```

## References

- Docusaurus: https://docusaurus.io/docs
- Docusaurus Deployment: https://docusaurus.io/docs/deployment
