#!/bin/bash

set -e

CLUSTER_NAME="spider-rainbows"

echo "======================================"
echo "Spider Rainbows - Cluster Cleanup"
echo "======================================"
echo ""

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo "❌ Error: kind is not installed"
    exit 1
fi

# Check if cluster exists
if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "⚠️  Cluster '$CLUSTER_NAME' does not exist"
    exit 0
fi

# Delete the cluster
echo "🧹 Deleting kind cluster: $CLUSTER_NAME"
kind delete cluster --name $CLUSTER_NAME

echo ""
echo "✅ Cluster deleted successfully"
