#!/bin/bash

set -e

CLUSTER_NAME_PREFIX="spider-rainbows"
GCP_PROJECT="demoo-ooclock"
GCP_REGION="us-east1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}==>${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

echo ""
log_info "🕷️  Spider-Rainbows Cluster Cleanup"
log_info "======================================"
echo ""

# Initialize MCP cleanup flag
MCP_CLEANED=false

# Arrays to store found clusters
kind_clusters=()
gcp_clusters=()

# Check for Kind clusters (pattern match for timestamped names)
if command -v kind &> /dev/null; then
    while IFS= read -r cluster; do
        if [[ -n "$cluster" ]]; then
            kind_clusters+=("$cluster")
        fi
    done < <(kind get clusters 2>/dev/null | grep "^${CLUSTER_NAME_PREFIX}" || true)
fi

# Check for GCP clusters (pattern match for timestamped names)
if command -v gcloud &> /dev/null; then
    # List all clusters and filter for spider-rainbows pattern
    while IFS= read -r cluster; do
        if [[ -n "$cluster" ]]; then
            gcp_clusters+=("$cluster")
        fi
    done < <(gcloud container clusters list \
        --project "$GCP_PROJECT" \
        --filter="name~^${CLUSTER_NAME_PREFIX}" \
        --format="value(name)" 2>/dev/null || true)
fi

# If no clusters found, exit
if [ ${#kind_clusters[@]} -eq 0 ] && [ ${#gcp_clusters[@]} -eq 0 ]; then
    log_warning "No clusters found matching pattern '${CLUSTER_NAME_PREFIX}*'"
    exit 0
fi

# Display found clusters
log_info "Found the following clusters:"
for cluster in "${kind_clusters[@]}"; do
    echo "  - Kind cluster: $cluster"
done
for cluster in "${gcp_clusters[@]}"; do
    echo "  - GKE cluster: $cluster (project: $GCP_PROJECT, region: $GCP_REGION)"
done
echo ""

# Delete Kind clusters
for cluster in "${kind_clusters[@]}"; do
    read -p "Delete Kind cluster '$cluster'? [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Deleting Kind cluster '$cluster'..."
        if kind delete cluster --name "$cluster"; then
            log_success "Kind cluster deleted successfully"

            # Clean up MCP authentication files (symlink for Kind clusters)
            log_info "Cleaning up MCP authentication files..."
            rm -rf ~/.kube/config-dot-ai
            rm -rf /tmp/ca.crt
            rm -rf /tmp/dot-ai-token.txt
            log_success "MCP authentication files removed"

            # Set flag to remind about Claude Code restart
            MCP_CLEANED=true
        else
            log_error "Failed to delete Kind cluster"
            exit 1
        fi
    else
        log_info "Skipped Kind cluster deletion"
    fi
    echo ""
done

# Delete GCP clusters
for cluster in "${gcp_clusters[@]}"; do
    read -p "Delete GKE cluster '$cluster'? [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Deleting GKE cluster '$cluster' (this may take 2-5 minutes)..."
        if gcloud container clusters delete "$cluster" \
            --region "$GCP_REGION" \
            --project "$GCP_PROJECT" \
            --quiet; then
            log_success "GKE cluster deleted successfully"

            # Clean up kubeconfig
            log_info "Cleaning up kubeconfig..."
            CONTEXT_NAME="gke_${GCP_PROJECT}_${GCP_REGION}_${cluster}"

            kubectl config delete-context "$CONTEXT_NAME" 2>/dev/null || true
            kubectl config unset "users.$CONTEXT_NAME" 2>/dev/null || true
            kubectl config unset "clusters.$CONTEXT_NAME" 2>/dev/null || true

            log_success "Kubeconfig cleaned up"

            # Clean up MCP authentication files (including Docker-created directories)
            log_info "Cleaning up MCP authentication files..."
            rm -rf ~/.kube/config-dot-ai
            rm -rf /tmp/ca.crt
            rm -rf /tmp/dot-ai-token.txt
            log_success "MCP authentication files removed"

            # Set flag to remind about Claude Code restart
            MCP_CLEANED=true
        else
            log_error "Failed to delete GKE cluster"
            exit 1
        fi
    else
        log_info "Skipped GKE cluster deletion"
    fi
    echo ""
done

echo ""
log_success "=============================================="
log_success "✅ Cleanup complete"
log_success "=============================================="
echo ""

# Show MCP reminder if files were cleaned up
if [ "$MCP_CLEANED" = true ]; then
    log_info "⚠️  MCP Server Authentication Cleaned Up"
    log_info "Restart Claude Code if using dot-ai MCP server"
    echo ""
fi
