# Spider Rainbows

Interactive React demo application featuring a rainbow with spider interaction functionality.

**Tech Stack**: React 19 + Vite + Express.js + Docker

---

## Prerequisites

- Node.js 18+ and npm
- Docker (for containerized deployment)

---

## Local Development

Install dependencies and start the development server:

```bash
npm install
npm run dev
```

The app will be available at `http://localhost:8080`

---

## Production Build

Build and run the production server locally:

```bash
npm run build
npm start
```

The production server serves the optimized React build on port 8080 with a health endpoint at `/health`.

---

## Docker

### Quick Start (Pull from DockerHub)

```bash
docker pull wiggitywhitney/spider-rainbows:latest
docker run -p 8080:8080 wiggitywhitney/spider-rainbows:latest
```

### Build Locally

```bash
docker build -t spider-rainbows .
docker run -p 8080:8080 spider-rainbows
```

### Health Endpoint

The container exposes a health check endpoint:

```bash
curl http://localhost:8080/health
```

Returns:
```json
{
  "status": "healthy",
  "timestamp": "2025-10-17T05:37:51.824Z",
  "uptime": 33.439
}
```

---

## Local Kubernetes with Kind

For quick local testing in a Kubernetes environment, use the automated kind deployment scripts.

### Prerequisites

- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) - Kubernetes in Docker
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)

### Deploy to Kind Cluster

This script creates a kind cluster, deploys the app from DockerHub, and sets up port forwarding:

```bash
./kind/deploy.sh
```

The app will be available at `http://localhost:8080`. 

### Delete the Cluster

Press **Ctrl+C** to stop port forwarding.

Delete the cluster:

```bash
./kind/destroy.sh
```

---

## Kubernetes Deployment

### Basic Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: spider-rainbows
spec:
  replicas: 2
  selector:
    matchLabels:
      app: spider-rainbows
  template:
    metadata:
      labels:
        app: spider-rainbows
    spec:
      containers:
      - name: spider-rainbows
        image: wiggitywhitney/spider-rainbows:1.0.0
        ports:
        - containerPort: 8080
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: spider-rainbows
spec:
  selector:
    app: spider-rainbows
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  type: LoadBalancer
```

Apply the configuration:

```bash
kubectl apply -f deployment.yaml
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
