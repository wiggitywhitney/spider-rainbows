#!/bin/bash

set -e

CLUSTER_NAME="spider-rainbows"
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

# Check what clusters exist
kind_exists=false
gcp_exists=false
clusters_found=()

# Check for Kind cluster
if command -v kind &> /dev/null; then
    if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
        kind_exists=true
        clusters_found+=("Kind cluster: $CLUSTER_NAME")
    fi
fi

# Check for GCP cluster
if command -v gcloud &> /dev/null; then
    if gcloud container clusters describe "$CLUSTER_NAME" --region "$GCP_REGION" --project "$GCP_PROJECT" &>/dev/null; then
        gcp_exists=true
        clusters_found+=("GKE cluster: $CLUSTER_NAME (project: $GCP_PROJECT, region: $GCP_REGION)")
    fi
fi

# If no clusters found, exit
if [ ${#clusters_found[@]} -eq 0 ]; then
    log_warning "No clusters found with name '$CLUSTER_NAME'"
    exit 0
fi

# Display found clusters
log_info "Found the following clusters:"
for cluster in "${clusters_found[@]}"; do
    echo "  - $cluster"
done
echo ""

# Delete Kind cluster if exists
if [ "$kind_exists" = true ]; then
    read -p "Delete Kind cluster '$CLUSTER_NAME'? [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Deleting Kind cluster..."
        if kind delete cluster --name "$CLUSTER_NAME"; then
            log_success "Kind cluster deleted successfully"
        else
            log_error "Failed to delete Kind cluster"
            exit 1
        fi
    else
        log_info "Skipped Kind cluster deletion"
    fi
    echo ""
fi

# Delete GCP cluster if exists
if [ "$gcp_exists" = true ]; then
    read -p "Delete GKE cluster '$CLUSTER_NAME'? [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Deleting GKE cluster (this may take 2-5 minutes)..."
        if gcloud container clusters delete "$CLUSTER_NAME" \
            --region "$GCP_REGION" \
            --project "$GCP_PROJECT" \
            --quiet; then
            log_success "GKE cluster deleted successfully"

            # Clean up kubeconfig
            log_info "Cleaning up kubeconfig..."
            CONTEXT_NAME="gke_${GCP_PROJECT}_${GCP_REGION}_${CLUSTER_NAME}"

            kubectl config delete-context "$CONTEXT_NAME" 2>/dev/null || true
            kubectl config unset "users.$CONTEXT_NAME" 2>/dev/null || true
            kubectl config unset "clusters.$CONTEXT_NAME" 2>/dev/null || true

            log_success "Kubeconfig cleaned up"
        else
            log_error "Failed to delete GKE cluster"
            exit 1
        fi
    else
        log_info "Skipped GKE cluster deletion"
    fi
    echo ""
fi

echo ""
log_success "=============================================="
log_success "✅ Cleanup complete"
log_success "=============================================="
echo ""
