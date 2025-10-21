#!/bin/bash
# Setup script for spider-rainbows GitOps demo environment
# Creates a Kind cluster with ArgoCD, ingress controller, and GitOps configuration
#
# Usage: ./kind/setup-argocd.sh
#
# Prerequisites:
#   - kind (Kubernetes in Docker)
#   - kubectl
#   - docker
#   - curl

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# =============================================================================
# Configuration Variables
# =============================================================================

CLUSTER_NAME="spider-rainbows-gitops"
CLUSTER_CONFIG="$(dirname "$0")/cluster-config.yaml"
INGRESS_NGINX_VERSION="v1.9.4"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# Helper Functions
# =============================================================================

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

check_prerequisites() {
    log_info "Checking prerequisites..."

    local missing_tools=()

    if ! command -v kind &> /dev/null; then
        missing_tools+=("kind")
    fi

    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi

    if ! command -v docker &> /dev/null; then
        missing_tools+=("docker")
    fi

    if ! command -v curl &> /dev/null; then
        missing_tools+=("curl")
    fi

    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Please install missing tools and try again."
        exit 1
    fi

    # Check if Docker daemon is running
    if ! docker ps &> /dev/null; then
        log_error "Docker daemon is not running"
        log_info "Please start Docker and try again."
        exit 1
    fi

    log_success "All prerequisites satisfied"
}

wait_for_pods() {
    local namespace=$1
    local label=$2
    local timeout=${3:-300}  # Default 5 minutes

    log_info "Waiting for pods in namespace '$namespace' with label '$label' (timeout: ${timeout}s)..."

    if kubectl wait --for=condition=ready pod \
        -l "$label" \
        -n "$namespace" \
        --timeout="${timeout}s" &> /dev/null; then
        log_success "Pods are ready in namespace '$namespace'"
        return 0
    else
        log_error "Pods in namespace '$namespace' did not become ready in time"
        return 1
    fi
}

# =============================================================================
# Phase 1: Create Kind Cluster with Ingress
# =============================================================================

create_cluster() {
    log_info "Creating Kind cluster '$CLUSTER_NAME'..."

    # Check if cluster already exists
    if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
        log_warning "Cluster '$CLUSTER_NAME' already exists"
        log_info "Delete it with: kind delete cluster --name $CLUSTER_NAME"
        exit 1
    fi

    # Create cluster using config file
    if kind create cluster --config "$CLUSTER_CONFIG"; then
        log_success "Kind cluster '$CLUSTER_NAME' created"
    else
        log_error "Failed to create Kind cluster"
        exit 1
    fi

    # Verify cluster is accessible
    if kubectl cluster-info --context "kind-${CLUSTER_NAME}" &> /dev/null; then
        log_success "Cluster is accessible via kubectl"
    else
        log_error "Cannot access cluster via kubectl"
        exit 1
    fi
}

install_ingress_controller() {
    log_info "Installing NGINX Ingress Controller..."

    # Apply NGINX Ingress Controller manifest
    kubectl apply -f "https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-${INGRESS_NGINX_VERSION}/deploy/static/provider/kind/deploy.yaml"

    log_success "NGINX Ingress Controller manifest applied"

    # Wait for ingress controller to be ready (longer timeout for first-time image pulls)
    wait_for_pods "ingress-nginx" "app.kubernetes.io/component=controller" 300
}

validate_cluster_health() {
    log_info "Validating cluster health..."

    # Check cluster nodes
    if kubectl get nodes | grep -q "Ready"; then
        log_success "Cluster nodes are Ready"
    else
        log_error "Cluster nodes are not Ready"
        exit 1
    fi

    # Check ingress controller pods
    local ingress_ready
    ingress_ready=$(kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}')

    if [[ "$ingress_ready" == "True" ]]; then
        log_success "Ingress controller is healthy"
    else
        log_error "Ingress controller is not healthy"
        exit 1
    fi
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    echo ""
    log_info "🕷️  Spider-Rainbows GitOps Demo Setup"
    log_info "======================================"
    echo ""

    # Phase 1: Cluster and Ingress
    check_prerequisites
    create_cluster
    install_ingress_controller
    validate_cluster_health

    # Success summary
    echo ""
    log_success "=========================================="
    log_success "Phase 1 Complete: Cluster with Ingress"
    log_success "=========================================="
    echo ""
    log_info "Cluster: $CLUSTER_NAME"
    log_info "Context: kind-$CLUSTER_NAME"
    echo ""
    log_info "Next steps:"
    log_info "  - Phase 2: Install ArgoCD (coming soon)"
    log_info "  - Phase 3: Configure GitOps repository connection"
    log_info "  - Phase 4: Deploy spider-rainbows application"
    echo ""
}

main "$@"
