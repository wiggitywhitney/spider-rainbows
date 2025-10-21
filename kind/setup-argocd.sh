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

    # First, wait for at least one pod to exist (kubectl wait fails immediately if no pods match)
    local elapsed=0
    local interval=5
    while [ $elapsed -lt $timeout ]; do
        if kubectl get pods -n "$namespace" -l "$label" --no-headers 2>/dev/null | grep -q .; then
            break
        fi
        sleep $interval
        elapsed=$((elapsed + interval))
    done

    if [ $elapsed -ge $timeout ]; then
        log_error "No pods with label '$label' appeared in namespace '$namespace' within ${timeout}s"
        return 1
    fi

    # Now wait for the pod(s) to be ready
    local remaining=$((timeout - elapsed))
    if kubectl wait --for=condition=ready pod \
        -l "$label" \
        -n "$namespace" \
        --timeout="${remaining}s" &> /dev/null; then
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

    # Patch the service to use the correct NodePorts that match Kind's extraPortMappings
    kubectl patch service ingress-nginx-controller -n ingress-nginx --type='json' \
        -p='[{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 30080},
             {"op": "replace", "path": "/spec/ports/1/nodePort", "value": 30443}]'

    log_success "Ingress controller service patched with correct NodePorts"

    # Wait for ingress controller to be ready (longer timeout for first-time image pulls)
    wait_for_pods "ingress-nginx" "app.kubernetes.io/component=controller" 600
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
# Phase 2: ArgoCD Installation
# =============================================================================

install_argocd() {
    log_info "Installing ArgoCD..."

    # Create argocd namespace
    kubectl create namespace argocd || true

    # Install ArgoCD using official manifests
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

    log_success "ArgoCD manifests applied"

    # Wait for ArgoCD pods to be ready (longer timeout for first-time image pulls)
    wait_for_pods "argocd" "app.kubernetes.io/name=argocd-server" 600
}

configure_argocd_password() {
    log_info "Configuring ArgoCD admin password..."

    # Wait for argocd-server to be ready before password change
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=60s

    # Hash the password using bcrypt (ArgoCD expects bcrypt hashed passwords)
    # Using argocd CLI inside the pod to generate the hash
    local password_hash
    password_hash=$(kubectl exec -n argocd deployment/argocd-server -- argocd account bcrypt --password admin123)

    # Update the argocd-secret with the new password
    kubectl patch secret argocd-secret -n argocd \
        -p "{\"stringData\": {\"admin.password\": \"$password_hash\", \"admin.passwordMtime\": \"$(date +%FT%T%Z)\"}}"

    log_success "ArgoCD admin password configured"
}

install_argocd_ingress() {
    log_info "Installing ArgoCD ingress..."

    local ingress_file="$(dirname "$0")/argocd-ingress.yaml"

    if [ ! -f "$ingress_file" ]; then
        log_error "ArgoCD ingress file not found: $ingress_file"
        exit 1
    fi

    kubectl apply -f "$ingress_file"

    log_success "ArgoCD ingress applied"

    # Give ingress a moment to be recognized
    sleep 5
}

validate_argocd_health() {
    log_info "Validating ArgoCD health..."

    # Wait for all ArgoCD pods to be ready (with timeout)
    local timeout=300  # 5 minutes should be enough after argocd-server is already ready
    local elapsed=0
    local interval=5
    local all_ready=false

    while [ $elapsed -lt $timeout ]; do
        local argocd_pods_ready
        argocd_pods_ready=$(kubectl get pods -n argocd --no-headers 2>/dev/null | grep -v "Completed" | awk '{print $2}')

        all_ready=true
        for pod_status in $argocd_pods_ready; do
            if [[ "$pod_status" != "1/1" ]] && [[ "$pod_status" != "2/2" ]]; then
                all_ready=false
                break
            fi
        done

        if [ "$all_ready" = true ]; then
            break
        fi

        sleep $interval
        elapsed=$((elapsed + interval))
    done

    if [ "$all_ready" = true ]; then
        log_success "All ArgoCD pods are healthy"
    else
        log_error "Some ArgoCD pods are not ready after ${timeout}s"
        kubectl get pods -n argocd
        exit 1
    fi

    # Check ArgoCD UI is accessible via ingress
    log_info "Testing ArgoCD UI access..."

    local max_attempts=30
    local attempt=0
    local ui_accessible=false

    while [ $attempt -lt $max_attempts ]; do
        if curl -k -s -o /dev/null -w "%{http_code}" https://argocd.127.0.0.1.nip.io | grep -q "200\|302\|307"; then
            ui_accessible=true
            break
        fi
        attempt=$((attempt + 1))
        sleep 2
    done

    if [ "$ui_accessible" = true ]; then
        log_success "ArgoCD UI is accessible via ingress"
    else
        log_error "ArgoCD UI is not accessible via ingress after ${max_attempts} attempts"
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

    # Phase 2: ArgoCD Installation
    install_argocd
    configure_argocd_password
    install_argocd_ingress
    validate_argocd_health

    # Success summary
    echo ""
    log_success "=========================================="
    log_success "Phase 2 Complete: ArgoCD Installed"
    log_success "=========================================="
    echo ""
    log_info "Cluster: $CLUSTER_NAME"
    log_info "Context: kind-$CLUSTER_NAME"
    echo ""
    log_info "ArgoCD Access:"
    log_info "  URL: https://argocd.127.0.0.1.nip.io"
    log_info "  Username: admin"
    log_info "  Password: admin123"
    echo ""
    log_info "Next steps:"
    log_info "  - Phase 3: Configure GitOps repository connection"
    log_info "  - Phase 4: Deploy spider-rainbows application"
    echo ""
}

main "$@"
