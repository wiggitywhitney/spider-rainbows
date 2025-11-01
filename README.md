# Spider Rainbows

**A GitOps CI/CD demonstration platform** showing how code changes automatically flow from developer commit to live Kubernetes deployment.

## What Is This?

A complete end-to-end GitOps workflow demo using a simple React spider animation app. 

**Tech Stack**: React 19 + Vite + Express.js + Docker + Kubernetes + ArgoCD + GitHub Actions

---

## The Main Workflow (Conference Demo)

This is the star of the show - demonstrating complete GitOps automation:

### 1. Initial Setup

Create the GitOps platform with one command:

```bash
./setup-platform.sh
```

The script will prompt you to choose between:
1. **Kind (local)** - Local Kubernetes cluster for development
2. **GCP (cloud)** - Google Kubernetes Engine cluster for demos

This creates:
- **Kubernetes cluster** - Kind (local) or GKE (cloud)
- **Ingress-nginx** - Routes traffic via nip.io domains
- **ArgoCD** - GitOps continuous delivery tool
- **Spider-rainbows app** - Already deployed and managed by ArgoCD

The app configuration lives in the `gitops/` folder of this repository

**Access the live app:** http://spider-rainbows.127.0.0.1.nip.io

### 2. Develop a New Feature

Run the development script to update the spider design:

```bash
./develop-next-version.sh
```

This modifies React components to reference the next spider version:
- v1 → v2 (cheesy grins)
- v2 → v3 (realistic fangs)

### 3. Commit and Push

```bash
git add src/
git commit -m "feat: update spider design"
git push origin main
```

### 4. Automated CI/CD Pipeline (GitHub Actions)

**Workflow defined in:** `.github/workflows/build-push.yml` (this repo)

The push triggers automation:
1. **Build** - GitHub Actions builds new Docker image using `Dockerfile`
2. **Tag** - Image tagged with commit SHA (e.g., `main-abc1234`)
3. **Push** - Image pushed to DockerHub: `wiggitywhitney/spider-rainbows`
4. **Update Config** - Workflow updates deployment manifest in `gitops/manifests/spider-rainbows/deployment.yaml` with new image tag

### 5. GitOps Sync (ArgoCD)

ArgoCD automatically:
1. Detects manifest change in config repo
2. Pulls new Docker image from DockerHub
3. Updates deployment in Kubernetes cluster
4. App goes live with new spider version

### 6. See the Results

**Refresh:** http://spider-rainbows.127.0.0.1.nip.io

New spider version appears instantly! 🎉

### Reset to v1

```bash
./reset-to-v1.sh  # Back to baseline (no teeth)
```

### Cleanup

```bash
./destroy.sh
```

---

## Prerequisites

**For Kind (local) deployments:**
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) - Kubernetes in Docker
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) - Kubernetes CLI
- [docker](https://docs.docker.com/get-docker/) - Running and accessible
- Ports 80 and 443 available on your machine

**For GCP (cloud) deployments:**
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) - Kubernetes CLI
- [gcloud](https://cloud.google.com/sdk/docs/install) - Google Cloud SDK
- GCP account with billing enabled
- Configured GCP project (update `GCP_PROJECT` variable in script)

---

## Access Points

**Spider-Rainbows App:**
- URL: http://spider-rainbows.127.0.0.1.nip.io
- Health: http://spider-rainbows.127.0.0.1.nip.io/health

**ArgoCD UI** (view sync status):
- URL: https://argocd.127.0.0.1.nip.io (Kind) or https://argocd.{LOADBALANCER_IP}.nip.io (GCP)
- Username: `admin` / Password: `admin123`

**GitOps Manifests:**
- Located in `gitops/` directory of this repository

---

## Troubleshooting

### nip.io DNS Issues

If `*.nip.io` domains don't resolve, use port-forwarding:

```bash
# ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8081:443
# Then access: https://localhost:8081

# Spider-rainbows app
kubectl port-forward svc/spider-rainbows -n default 8080:80
# Then access: http://localhost:8080
```

### Platform Reset

To completely reset the environment:

```bash
./destroy.sh  # Destroys Kind or GCP clusters
./setup-platform.sh
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
