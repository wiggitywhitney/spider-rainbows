#!/bin/bash

set -e

CLUSTER_NAME="spider-rainbows"
NAMESPACE="default"

echo "======================================"
echo "Spider Rainbows - Kind Cluster Deploy"
echo "======================================"
echo ""

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo "❌ Error: kind is not installed"
    echo "Install with: brew install kind"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl is not installed"
    echo "Install with: brew install kubectl"
    exit 1
fi

# Create kind cluster
echo "🚀 Creating kind cluster: $CLUSTER_NAME"
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "⚠️  Cluster already exists. Deleting..."
    kind delete cluster --name $CLUSTER_NAME
fi

kind create cluster --name $CLUSTER_NAME

# Wait for cluster to be ready
echo ""
echo "⏳ Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=60s

# Deploy spider-rainbows
echo ""
echo "📦 Deploying spider-rainbows application..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kubectl apply -f "$SCRIPT_DIR/deployment.yaml"

# Wait for deployment to be ready
echo ""
echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=Ready pods -l app=spider-rainbows --timeout=120s

# Show deployment status
echo ""
echo "✅ Deployment complete!"
echo ""
kubectl get deployments
echo ""
kubectl get pods -l app=spider-rainbows
echo ""
kubectl get services spider-rainbows

# Port forward
echo ""
echo "======================================"
echo "🌈 Starting port forward to localhost:8080"
echo "======================================"
echo ""
echo "Access the app at: http://localhost:8080"
echo "Health endpoint: http://localhost:8080/health"
echo ""
echo "Press Ctrl+C to stop port forwarding"
echo "To delete the cluster when done, run: ./kind/destroy.sh"
echo ""

# Port forward (blocks until Ctrl+C)
kubectl port-forward service/spider-rainbows 8080:80
