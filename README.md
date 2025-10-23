# Spider Rainbows

**A GitOps CI/CD demonstration platform** for conference talks comparing GenAI-assisted vs programmatic automation approaches across the complete software delivery pipeline.

## What Is This?

This repository demonstrates a complete end-to-end GitOps workflow using a simple React application (spider rainbows animation) as the deployment target. The demo shows how code changes automatically flow through:

1. **Feature Development** → Code changes pushed to GitHub
2. **CI Pipeline** → Automated build and Docker image creation
3. **GitOps Update** → CI/CD updates deployment manifests in config repo
4. **ArgoCD Sync** → ArgoCD detects changes and syncs to cluster
5. **Live Deployment** → Application automatically updates in Kubernetes

Perfect for conference demos, workshops, or learning GitOps patterns with ArgoCD.

**Tech Stack**: React 19 + Vite + Express.js + Docker + Kubernetes + ArgoCD

---

## Quick Start (Demo Environment)

Experience the complete GitOps workflow in ~3 minutes:

### Prerequisites

- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) - Kubernetes in Docker
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
- [docker](https://docs.docker.com/get-docker/) - Running and accessible
- Ports 80 and 443 available

### Setup

Create the complete GitOps platform with one command:

```bash
./kind/setup-platform.sh
```

The script creates:
- Kind cluster with ingress controller
- ArgoCD managing deployments
- Spider-rainbows app deployed via GitOps
- Auto-sync enabled for continuous deployment

### Access

**ArgoCD UI** (view deployment status):
- https://argocd.127.0.0.1.nip.io
- Username: `admin` / Password: `admin123`

**Spider-Rainbows App** (the deployed application):
- http://spider-rainbows.127.0.0.1.nip.io
- Health check: http://spider-rainbows.127.0.0.1.nip.io/health

### See GitOps in Action

The app is already deployed! Now watch automatic updates:

1. Make a code change to `src/App.jsx`
2. Push to `main` branch
3. Watch GitHub Actions build and push new image
4. See ArgoCD automatically sync the changes
5. Refresh the app URL to see your changes live

GitOps configuration lives in: [spider-rainbows-platform-config](https://github.com/wiggitywhitney/spider-rainbows-platform-config)

### Cleanup

```bash
./kind/destroy.sh
```

## Troubleshooting

### nip.io DNS Issues

If `*.nip.io` domains don't resolve (common on conference wifi or corporate networks), use port-forwarding:

```bash
# ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8081:443
# Then access: https://localhost:8081

# Spider-rainbows app
kubectl port-forward svc/spider-rainbows -n default 8080:80
# Then access: http://localhost:8080
```

### Port Conflicts

If ports 80/443 are already in use:

```bash
# Check what's using the ports
lsof -i :80 -i :443

# Stop conflicting services or use port-forwarding (see above)
```

### Platform Reset

To completely reset the environment:

```bash
./kind/destroy.sh
./kind/setup-platform.sh
```

---

## Developer Reference

### Local Development

For working on the React app itself (not the GitOps platform):

**Prerequisites**: Node.js 18+ and npm

```bash
npm install
npm run dev
```

App runs at `http://localhost:8080`

### Docker Development

```bash
# Build locally
docker build -t spider-rainbows .

# Run locally
docker run -p 8080:8080 spider-rainbows

# Health check
curl http://localhost:8080/health
```

### Legacy Kind Deployment

Simple Kind cluster without GitOps (for basic testing):

```bash
./kind/deploy.sh  # Creates cluster with port-forwarding
./kind/destroy.sh # Cleanup
```

---

## Technical Architecture

### Container Design

- **Single process per container**: Follows Kubernetes best practices
- **Production server**: Express.js serves optimized React build from `dist/`
- **Health endpoint**: Dedicated `/health` route for liveness/readiness probes
- **Graceful shutdown**: SIGTERM/SIGINT handlers for zero-downtime deployments

### Project Structure

```
├── public/              # Static assets (images, fonts)
├── src/
│   ├── components/      # React components
│   ├── utils/           # Utility functions
│   ├── App.jsx          # Main application
│   └── main.jsx         # Entry point
├── server.js            # Production Express server
├── Dockerfile           # Multi-stage Docker build
└── vite.config.js       # Vite configuration
```

### NPM Scripts

- `npm run dev` - Start Vite dev server (port 8080)
- `npm run build` - Create production build
- `npm start` - Run production Express server
- `npm run preview` - Preview production build with Vite

---

## License

MIT
