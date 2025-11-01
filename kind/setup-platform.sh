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

CLUSTER_NAME="spider-rainbows-$(date +%Y%m%d-%H%M%S)"
CLUSTER_CONFIG="$(dirname "$0")/cluster-config.yaml"
INGRESS_NGINX_VERSION="v1.9.4"

# GCP Configuration
GCP_PROJECT="demoo-ooclock"
GCP_REGION="us-east1"
GCP_MACHINE_TYPE="n1-standard-4"
GCP_NUM_NODES="1"

# Deployment mode (will be set by user prompt)
DEPLOYMENT_MODE=""
BASE_DOMAIN=""

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

prompt_deployment_mode() {
    echo ""
    log_info "Which cluster type do you want to deploy?"
    echo "  1) Kind (local)"
    echo "  2) GCP (cloud)"
    echo ""

    while true; do
        read -p "Enter choice [1-2]: " choice
        case $choice in
            1)
                DEPLOYMENT_MODE="kind"
                log_success "Selected: Kind (local)"
                break
                ;;
            2)
                DEPLOYMENT_MODE="gcp"
                log_success "Selected: GCP (cloud)"
                break
                ;;
            *)
                log_error "Invalid choice. Please enter 1 or 2."
                ;;
        esac
    done
    echo ""
}

check_kind_prerequisites() {
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

    # Check if required ports are available
    log_info "Checking port availability..."
    local ports_in_use=()

    # Check if port 80 is listening on localhost or all interfaces
    if lsof -nP -iTCP:80 -sTCP:LISTEN 2>/dev/null | grep -E '(127.0.0.1:80|0.0.0.0:80|\*:80)' >/dev/null; then
        ports_in_use+=("80")
    fi

    # Check if port 443 is listening on localhost or all interfaces
    if lsof -nP -iTCP:443 -sTCP:LISTEN 2>/dev/null | grep -E '(127.0.0.1:443|0.0.0.0:443|\*:443)' >/dev/null; then
        ports_in_use+=("443")
    fi

    if [ ${#ports_in_use[@]} -ne 0 ]; then
        log_error "Required ports are already in use: ${ports_in_use[*]}"
        log_info "Kind cluster requires ports 80 and 443 to be available."
        log_info "Please stop services using these ports and try again."
        log_info "Check with: lsof -nP -iTCP:80 -sTCP:LISTEN && lsof -nP -iTCP:443 -sTCP:LISTEN"
        exit 1
    fi

    log_success "All prerequisites satisfied"
}

check_gcp_prerequisites() {
    log_info "Checking GCP prerequisites..."

    local missing_tools=()

    # Check gcloud CLI
    if ! command -v gcloud &> /dev/null; then
        missing_tools+=("gcloud")
    fi

    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi

    # Check curl
    if ! command -v curl &> /dev/null; then
        missing_tools+=("curl")
    fi

    # Check gke-gcloud-auth-plugin - auto-add to PATH if gcloud is installed
    if ! command -v gke-gcloud-auth-plugin &> /dev/null; then
        if command -v gcloud &> /dev/null; then
            # Try to find and add gcloud SDK bin directory to PATH
            local gcloud_sdk_bin
            gcloud_sdk_bin="$(gcloud info --format='value(installation.sdk_root)' 2>/dev/null)/bin"
            if [ -d "$gcloud_sdk_bin" ] && [ -x "$gcloud_sdk_bin/gke-gcloud-auth-plugin" ]; then
                export PATH="$gcloud_sdk_bin:$PATH"
                log_success "Added gcloud SDK to PATH"
            else
                missing_tools+=("gke-gcloud-auth-plugin")
            fi
        else
            missing_tools+=("gke-gcloud-auth-plugin")
        fi
    fi

    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Please install missing tools and try again."
        log_info "Install gcloud: https://cloud.google.com/sdk/docs/install"
        log_info "Install gke-gcloud-auth-plugin: gcloud components install gke-gcloud-auth-plugin"
        exit 1
    fi

    # Check gcloud authentication
    log_info "Checking GCP authentication..."
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q .; then
        log_error "Not authenticated with gcloud"
        log_info "Please run: gcloud auth login"
        exit 1
    fi

    # Check project access
    log_info "Checking GCP project access..."
    if ! gcloud projects describe "$GCP_PROJECT" &>/dev/null; then
        log_error "Cannot access GCP project: $GCP_PROJECT"
        log_info "Please verify project exists and you have access"
        exit 1
    fi

    log_success "All GCP prerequisites satisfied"
}

check_prerequisites() {
    if [[ "$DEPLOYMENT_MODE" == "kind" ]]; then
        check_kind_prerequisites
    elif [[ "$DEPLOYMENT_MODE" == "gcp" ]]; then
        check_gcp_prerequisites
    else
        log_error "Invalid deployment mode: $DEPLOYMENT_MODE"
        exit 1
    fi
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
# Phase 1: Create Cluster (Kind or GCP)
# =============================================================================

create_kind_cluster() {
    log_info "Creating Kind cluster '$CLUSTER_NAME'..."

    # Check if cluster already exists
    if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
        log_warning "Cluster '$CLUSTER_NAME' already exists"
        log_info "Delete it with: kind delete cluster --name $CLUSTER_NAME"
        exit 1
    fi

    # Create cluster using config file with explicit name
    if kind create cluster --name "$CLUSTER_NAME" --config "$CLUSTER_CONFIG"; then
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

    # Set BASE_DOMAIN for Kind
    BASE_DOMAIN="127.0.0.1.nip.io"
    log_info "Using domain: $BASE_DOMAIN"
}

create_gke_cluster() {
    log_info "Creating GKE cluster '$CLUSTER_NAME'..."

    # Check if cluster already exists
    if gcloud container clusters describe "$CLUSTER_NAME" --region "$GCP_REGION" --project "$GCP_PROJECT" &>/dev/null; then
        log_warning "Cluster '$CLUSTER_NAME' already exists in project $GCP_PROJECT"
        log_info "Delete it with: gcloud container clusters delete $CLUSTER_NAME --region $GCP_REGION --project $GCP_PROJECT"
        exit 1
    fi

    # Create GKE cluster
    log_info "Creating cluster (this may take 5-10 minutes)..."
    if gcloud container clusters create "$CLUSTER_NAME" \
        --project "$GCP_PROJECT" \
        --region "$GCP_REGION" \
        --machine-type "$GCP_MACHINE_TYPE" \
        --num-nodes "$GCP_NUM_NODES" \
        --quiet; then
        log_success "GKE cluster '$CLUSTER_NAME' created"
    else
        log_error "Failed to create GKE cluster"
        exit 1
    fi

    # Get credentials for kubectl
    log_info "Configuring kubectl access..."
    if gcloud container clusters get-credentials "$CLUSTER_NAME" \
        --region "$GCP_REGION" \
        --project "$GCP_PROJECT"; then
        log_success "kubectl configured for GKE cluster"
    else
        log_error "Failed to get cluster credentials"
        exit 1
    fi

    # Verify cluster is accessible
    if kubectl cluster-info &> /dev/null; then
        log_success "Cluster is accessible via kubectl"
    else
        log_error "Cannot access cluster via kubectl"
        exit 1
    fi

    # Wait for ALL GKE nodes to become Ready
    log_info "Waiting for all GKE nodes to become Ready..."
    local timeout=180
    local elapsed=0
    local interval=5
    local total_nodes
    total_nodes=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')

    while [ $elapsed -lt $timeout ]; do
        local ready_nodes
        ready_nodes=$(kubectl get nodes --no-headers 2>/dev/null | grep -c "Ready" || echo "0")

        if [ "$ready_nodes" -eq "$total_nodes" ] && [ "$ready_nodes" -gt 0 ]; then
            log_success "All GKE nodes are Ready ($ready_nodes/$total_nodes nodes)"
            break
        fi

        sleep $interval
        elapsed=$((elapsed + interval))
    done

    if [ "$ready_nodes" -ne "$total_nodes" ]; then
        log_error "Not all GKE nodes became Ready after ${timeout}s ($ready_nodes/$total_nodes)"
        kubectl get nodes
        exit 1
    fi
}

create_cluster() {
    if [[ "$DEPLOYMENT_MODE" == "kind" ]]; then
        create_kind_cluster
    elif [[ "$DEPLOYMENT_MODE" == "gcp" ]]; then
        create_gke_cluster
    else
        log_error "Invalid deployment mode: $DEPLOYMENT_MODE"
        exit 1
    fi
}

install_kind_ingress() {
    log_info "Installing NGINX Ingress Controller for Kind..."

    # Apply NGINX Ingress Controller manifest for Kind
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

install_gcp_ingress() {
    log_info "Installing NGINX Ingress Controller for GCP..."

    # Apply NGINX Ingress Controller manifest for cloud
    kubectl apply -f "https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-${INGRESS_NGINX_VERSION}/deploy/static/provider/cloud/deploy.yaml"

    log_success "NGINX Ingress Controller manifest applied"

    # Wait for ingress controller to be ready
    wait_for_pods "ingress-nginx" "app.kubernetes.io/component=controller" 600

    # Wait for LoadBalancer to get external IP
    log_info "Waiting for LoadBalancer to get external IP (this may take 2-5 minutes)..."

    local max_attempts=60
    local attempt=0
    local external_ip=""

    while [ $attempt -lt $max_attempts ]; do
        external_ip=$(kubectl get service ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

        if [[ -n "$external_ip" ]]; then
            log_success "LoadBalancer external IP: $external_ip"
            BASE_DOMAIN="${external_ip}.nip.io"
            log_success "Using domain: $BASE_DOMAIN"
            break
        fi

        attempt=$((attempt + 1))
        sleep 5
    done

    if [[ -z "$external_ip" ]]; then
        log_error "Failed to get LoadBalancer external IP after ${max_attempts} attempts"
        log_info "Check service status: kubectl get svc -n ingress-nginx"
        exit 1
    fi
}

install_ingress_controller() {
    if [[ "$DEPLOYMENT_MODE" == "kind" ]]; then
        install_kind_ingress
    elif [[ "$DEPLOYMENT_MODE" == "gcp" ]]; then
        install_gcp_ingress
    else
        log_error "Invalid deployment mode: $DEPLOYMENT_MODE"
        exit 1
    fi
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

configure_argocd_sync_interval() {
    log_info "Configuring ArgoCD sync interval to 5 seconds..."

    # Configure ArgoCD to sync every 5 seconds
    kubectl patch configmap argocd-cm -n argocd --type merge \
        -p '{"data":{"timeout.reconciliation":"5s"}}'

    log_success "ArgoCD sync interval set to 5 seconds"

    # Restart argocd-application-controller to apply the new setting
    log_info "Restarting ArgoCD application controller..."
    kubectl rollout restart statefulset argocd-application-controller -n argocd

    # Wait for the restart to complete
    kubectl rollout status statefulset argocd-application-controller -n argocd --timeout=120s

    log_success "ArgoCD application controller restarted"
}

install_argocd_ingress() {
    log_info "Installing ArgoCD ingress..."

    # Create ingress dynamically with correct domain
    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  ingressClassName: nginx
  rules:
  - host: argocd.${BASE_DOMAIN}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              name: https
EOF

    log_success "ArgoCD ingress applied with domain: argocd.${BASE_DOMAIN}"

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
        if curl -k -s -o /dev/null -w "%{http_code}" "https://argocd.${BASE_DOMAIN}" | grep -q "200\|302\|307"; then
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
# Phase 3: GitOps Repository Connection
# =============================================================================

deploy_spider_rainbows_app() {
    log_info "Deploying spider-rainbows application via ArgoCD..."

    local app_file
    app_file="$(dirname "$0")/spider-rainbows-app.yaml"

    if [ ! -f "$app_file" ]; then
        log_error "ArgoCD Application file not found: $app_file"
        exit 1
    fi

    # Apply the ArgoCD Application CR
    kubectl apply -f "$app_file"

    log_success "ArgoCD Application CR applied"
}

validate_app_sync() {
    log_info "Waiting for ArgoCD to sync spider-rainbows application..."

    # Wait for Application to exist
    local timeout=60
    local elapsed=0
    local interval=2

    while [ $elapsed -lt $timeout ]; do
        if kubectl get application spider-rainbows -n argocd &>/dev/null; then
            break
        fi
        sleep $interval
        elapsed=$((elapsed + interval))
    done

    if ! kubectl get application spider-rainbows -n argocd &>/dev/null; then
        log_error "ArgoCD Application 'spider-rainbows' not found after ${timeout}s"
        exit 1
    fi

    # Wait for sync to complete (timeout 5 minutes for image pulls)
    timeout=300
    elapsed=0
    interval=5

    while [ $elapsed -lt $timeout ]; do
        local sync_status
        local health_status

        sync_status=$(kubectl get application spider-rainbows -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
        health_status=$(kubectl get application spider-rainbows -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")

        if [[ "$sync_status" == "Synced" ]] && [[ "$health_status" == "Healthy" ]]; then
            log_success "Application synced and healthy"
            break
        fi

        if [[ "$health_status" == "Degraded" ]]; then
            log_error "Application health is Degraded"
            kubectl get application spider-rainbows -n argocd -o yaml
            exit 1
        fi

        sleep $interval
        elapsed=$((elapsed + interval))
    done

    if [[ "$sync_status" != "Synced" ]] || [[ "$health_status" != "Healthy" ]]; then
        log_error "Application did not become healthy after ${timeout}s"
        log_error "Sync Status: $sync_status, Health Status: $health_status"
        kubectl get application spider-rainbows -n argocd
        exit 1
    fi

    # Wait for spider-rainbows pods to be ready
    wait_for_pods "default" "app=spider-rainbows" 300

    log_success "Spider-rainbows pods are running"

    # Create spider-rainbows ingress dynamically with correct domain
    log_info "Creating spider-rainbows ingress with dynamic domain..."

    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: spider-rainbows
  namespace: default
spec:
  ingressClassName: nginx
  rules:
  - host: spider-rainbows.${BASE_DOMAIN}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: spider-rainbows
            port:
              number: 80
EOF

    log_success "Spider-rainbows ingress created with domain: spider-rainbows.${BASE_DOMAIN}"
}

validate_app_access() {
    log_info "Testing spider-rainbows app access..."

    # Wait a moment for ingress to be fully ready
    sleep 5

    local max_attempts=30
    local attempt=0
    local app_accessible=false

    while [ $attempt -lt $max_attempts ]; do
        local http_code
        http_code=$(curl -s -o /dev/null -w "%{http_code}" "http://spider-rainbows.${BASE_DOMAIN}/health" 2>/dev/null || echo "000")

        if [[ "$http_code" == "200" ]]; then
            app_accessible=true
            break
        fi

        attempt=$((attempt + 1))
        sleep 2
    done

    if [ "$app_accessible" = true ]; then
        log_success "Spider-rainbows app is accessible via ingress"
    else
        log_error "Spider-rainbows app is not accessible after ${max_attempts} attempts"
        log_error "Check ingress and service configuration"
        kubectl get ingress -n default
        kubectl get svc -n default
        exit 1
    fi
}

# =============================================================================
# Phase 5: Final Comprehensive Health Validation
# =============================================================================

validate_all_components() {
    log_info "Running final health validation across all components..."
    echo ""

    local failures=0

    # 1. Cluster Health
    log_info "[1/6] Validating cluster..."
    if kubectl get nodes --no-headers 2>/dev/null | grep -q "Ready"; then
        local node_count
        node_count=$(kubectl get nodes --no-headers 2>/dev/null | grep "Ready" | wc -l | tr -d ' ')
        log_success "  ✓ Cluster nodes: $node_count Ready"
    else
        log_error "  ✗ Cluster nodes: Not Ready"
        failures=$((failures + 1))
    fi

    # 2. Ingress Controller
    log_info "[2/6] Validating ingress controller..."
    local ingress_ready
    ingress_ready=$(kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
    if [[ "$ingress_ready" == "True" ]]; then
        log_success "  ✓ Ingress controller: Healthy"
    else
        log_error "  ✗ Ingress controller: Not Healthy"
        failures=$((failures + 1))
    fi

    # 3. ArgoCD Pods
    log_info "[3/6] Validating ArgoCD components..."
    local argocd_pod_count
    local argocd_ready_count
    argocd_pod_count=$(kubectl get pods -n argocd --no-headers 2>/dev/null | grep -v "Completed" | wc -l | tr -d ' ')
    argocd_ready_count=$(kubectl get pods -n argocd --no-headers 2>/dev/null | grep -v "Completed" | grep "1/1\|2/2" | wc -l | tr -d ' ')

    if [[ "$argocd_pod_count" -eq "$argocd_ready_count" ]] && [[ "$argocd_pod_count" -gt 0 ]]; then
        log_success "  ✓ ArgoCD pods: $argocd_ready_count/$argocd_pod_count ready"
    else
        log_error "  ✗ ArgoCD pods: $argocd_ready_count/$argocd_pod_count ready"
        failures=$((failures + 1))
    fi

    # 4. ArgoCD UI Access
    log_info "[4/6] Validating ArgoCD UI access..."
    local argocd_http_code
    argocd_http_code=$(curl -k -s -o /dev/null -w "%{http_code}" --max-time 5 "https://argocd.${BASE_DOMAIN}" 2>/dev/null || echo "000")
    if [[ "$argocd_http_code" =~ ^(200|302|307)$ ]]; then
        log_success "  ✓ ArgoCD UI: Accessible (HTTP $argocd_http_code)"
    else
        log_error "  ✗ ArgoCD UI: Not accessible (HTTP $argocd_http_code)"
        failures=$((failures + 1))
    fi

    # 5. ArgoCD Application Status
    log_info "[5/6] Validating spider-rainbows ArgoCD Application..."
    local sync_status
    local health_status
    sync_status=$(kubectl get application spider-rainbows -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
    health_status=$(kubectl get application spider-rainbows -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")

    if [[ "$sync_status" == "Synced" ]] && [[ "$health_status" == "Healthy" ]]; then
        log_success "  ✓ ArgoCD Application: Synced and Healthy"
    else
        log_error "  ✗ ArgoCD Application: $sync_status / $health_status"
        failures=$((failures + 1))
    fi

    # 6. Spider-Rainbows App Access
    log_info "[6/6] Validating spider-rainbows app access..."
    local app_pod_count
    local app_ready_count
    app_pod_count=$(kubectl get pods -n default -l app=spider-rainbows --no-headers 2>/dev/null | wc -l | tr -d ' ')
    app_ready_count=$(kubectl get pods -n default -l app=spider-rainbows --no-headers 2>/dev/null | grep "1/1" | wc -l | tr -d ' ')

    if [[ "$app_pod_count" -eq "$app_ready_count" ]] && [[ "$app_pod_count" -gt 0 ]]; then
        log_success "  ✓ Spider-rainbows pods: $app_ready_count/$app_pod_count ready"
    else
        log_error "  ✗ Spider-rainbows pods: $app_ready_count/$app_pod_count ready"
        failures=$((failures + 1))
    fi

    local health_http_code
    health_http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://spider-rainbows.${BASE_DOMAIN}/health" 2>/dev/null || echo "000")
    if [[ "$health_http_code" == "200" ]]; then
        log_success "  ✓ Spider-rainbows /health endpoint: HTTP 200"
    else
        log_error "  ✗ Spider-rainbows /health endpoint: HTTP $health_http_code"
        failures=$((failures + 1))
    fi

    echo ""

    # Return failure count
    return $failures
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    echo ""
    log_info "🕷️  Spider-Rainbows GitOps Demo Setup"
    log_info "======================================"
    echo ""

    # Prompt for deployment mode
    prompt_deployment_mode

    # Phase 1: Cluster and Ingress
    check_prerequisites
    create_cluster
    install_ingress_controller
    validate_cluster_health

    # Phase 2: ArgoCD Installation
    install_argocd
    configure_argocd_password
    configure_argocd_sync_interval
    install_argocd_ingress
    validate_argocd_health

    # Phase 3: GitOps Repository Connection & App Deployment
    deploy_spider_rainbows_app
    validate_app_sync
    validate_app_access

    # Phase 5: Final Comprehensive Health Check
    echo ""
    log_info "======================================"
    log_info "Final System Health Validation"
    log_info "======================================"
    echo ""

    if validate_all_components; then
        # Success summary
        echo ""
        log_success "=============================================="
        log_success "✅ Setup Complete: GitOps Demo Ready"
        log_success "=============================================="
        echo ""
        log_info "Cluster: $CLUSTER_NAME"
        log_info "Context: kind-$CLUSTER_NAME"
        echo ""
        log_info "ArgoCD Access:"
        log_info "  URL: https://argocd.${BASE_DOMAIN}"
        log_info "  Username: admin"
        log_info "  Password: admin123"
        echo ""
        log_info "Spider-Rainbows App:"
        log_info "  URL: http://spider-rainbows.${BASE_DOMAIN}"
        log_info "  Health: http://spider-rainbows.${BASE_DOMAIN}/health"
        echo ""
        log_info "Demo is ready! 🎉"
        log_info ""
        log_info "Next steps:"
        log_info "  - Open ArgoCD UI to view application status"
        log_info "  - Test app at http://spider-rainbows.127.0.0.1.nip.io"
        log_info "  - Make code changes to trigger CI/CD workflow (Phase 4)"
        echo ""
    else
        # Validation failed
        echo ""
        log_error "=============================================="
        log_error "⚠️  Setup completed with validation failures"
        log_error "=============================================="
        echo ""
        log_warning "Some components may not be fully healthy."
        log_warning "Review the validation output above and troubleshoot before using for demo."
        echo ""
        log_info "Troubleshooting commands:"
        log_info "  kubectl get nodes"
        log_info "  kubectl get pods -A"
        log_info "  kubectl get application spider-rainbows -n argocd"
        echo ""
        exit 1
    fi
}

main "$@"
