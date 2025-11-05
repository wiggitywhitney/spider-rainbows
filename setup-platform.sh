#!/bin/bash
# Setup script for spider-rainbows GitOps demo environment
# Creates a Kind cluster with ArgoCD, ingress controller, and GitOps configuration
#
# Usage:
#   ./setup-platform.sh [kind|gcp]
#
# Arguments:
#   kind - Deploy to local Kind cluster (default if no argument provided)
#   gcp  - Deploy to Google Cloud Platform GKE cluster
#
# Prerequisites:
#   - kind (Kubernetes in Docker) for local deployment
#   - kubectl
#   - docker
#   - curl
#   - gcloud CLI (for GCP deployment)
#   - gh CLI (for GitHub webhook management)

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# =============================================================================
# Configuration Variables
# =============================================================================

CLUSTER_NAME="spider-rainbows-$(date +%Y%m%d-%H%M%S)"
CLUSTER_CONFIG="$(dirname "$0")/kind/cluster-config.yaml"
INGRESS_NGINX_VERSION="v1.9.4"

# GCP Configuration
GCP_PROJECT="demoo-ooclock"
GCP_REGION="us-east1"
GCP_MACHINE_TYPE="n1-standard-4"
GCP_NUM_NODES="1"

# GitHub Configuration (dynamically detected from git remote)
GITHUB_REPO=$(git config --get remote.origin.url 2>/dev/null | sed -E 's#.*github\.com[:/]([^/]+/[^.]+)(\.git)?$#\1#' || echo "")

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
        read -p "Enter choice [1-2]: " choice || {
            log_error "Input cancelled or error occurred"
            exit 1
        }
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
    else
        # Check kubectl version (v1.23+ required for MCP token wait functionality)
        local kubectl_version
        kubectl_version=$(kubectl version --client -o json 2>/dev/null | grep -o '"minor":"[0-9]*"' | grep -o '[0-9]*' || echo "0")
        if [ "$kubectl_version" -lt 23 ]; then
            log_warning "kubectl v1.23+ recommended (you have v1.$kubectl_version)"
            log_warning "MCP server token authentication may require manual wait times"
        fi
    fi

    if ! command -v docker &> /dev/null; then
        missing_tools+=("docker")
    fi

    if ! command -v curl &> /dev/null; then
        missing_tools+=("curl")
    fi

    if ! command -v openssl &> /dev/null; then
        missing_tools+=("openssl")
    fi

    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Please install missing tools and try again."
        exit 1
    fi

    # Check for recommended tools
    if ! command -v gh &> /dev/null; then
        log_warning "GitHub CLI (gh) not found - webhook will need manual setup"
        log_info "Install from: https://cli.github.com/"
    fi

    if ! command -v jq &> /dev/null; then
        log_warning "jq not found - webhook management may not work"
        log_info "Install from: https://jqlang.github.io/jq/"
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
    else
        # Check kubectl version (v1.23+ required for MCP token wait functionality)
        local kubectl_version
        kubectl_version=$(kubectl version --client -o json 2>/dev/null | grep -o '"minor":"[0-9]*"' | grep -o '[0-9]*' || echo "0")
        if [ "$kubectl_version" -lt 23 ]; then
            log_warning "kubectl v1.23+ recommended (you have v1.$kubectl_version)"
            log_warning "MCP server token authentication may require manual wait times"
        fi
    fi

    # Check curl
    if ! command -v curl &> /dev/null; then
        missing_tools+=("curl")
    fi

    # Check openssl
    if ! command -v openssl &> /dev/null; then
        missing_tools+=("openssl")
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

    # Check for recommended tools
    if ! command -v gh &> /dev/null; then
        log_warning "GitHub CLI (gh) not found - webhook will need manual setup"
        log_info "Install from: https://cli.github.com/"
    fi

    if ! command -v jq &> /dev/null; then
        log_warning "jq not found - webhook management may not work"
        log_info "Install from: https://jqlang.github.io/jq/"
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
    local ready_nodes=0

    while [ $elapsed -lt $timeout ]; do
        ready_nodes=$(kubectl get nodes --no-headers 2>/dev/null | grep -cw "Ready" || echo "0")

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
        if ! create_kind_cluster; then
            log_error "Cluster creation failed"
            echo ""
            read -p "Do you want to cleanup partial resources? [y/N]: " cleanup_choice
            if [[ "$cleanup_choice" =~ ^[Yy]$ ]]; then
                log_info "Running cleanup..."
                ./destroy.sh
            else
                log_info "Skipping cleanup - run ./destroy.sh manually if needed"
            fi
            exit 1
        fi
    elif [[ "$DEPLOYMENT_MODE" == "gcp" ]]; then
        if ! create_gke_cluster; then
            log_error "Cluster creation failed"
            echo ""
            read -p "Do you want to cleanup partial resources? [y/N]: " cleanup_choice
            if [[ "$cleanup_choice" =~ ^[Yy]$ ]]; then
                log_info "Running cleanup..."
                ./destroy.sh
            else
                log_info "Skipping cleanup - run ./destroy.sh manually if needed"
            fi
            exit 1
        fi
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
# MCP Server Configuration (Optional - for dot-ai)
# =============================================================================

configure_mcp_authentication() {
    log_info "Configuring MCP server authentication (optional)..."

    # Only configure if .mcp.json exists (MCP server is being used)
    if [ ! -f ".mcp.json" ]; then
        log_info "No .mcp.json found - skipping MCP authentication setup"
        return 0
    fi

    # For Kind clusters, clean up any stale GCP MCP configuration and create symlink
    if [ "$DEPLOYMENT_MODE" != "gcp" ]; then
        log_info "Kind cluster detected - MCP works with default config"

        # Defensively remove any stale GCP MCP auth files (including Docker-created directories)
        if [ -e ~/.kube/config-dot-ai ] || [ -e /tmp/ca.crt ] || [ -e /tmp/dot-ai-token.txt ]; then
            log_info "Cleaning up stale GCP MCP authentication files..."
            rm -rf ~/.kube/config-dot-ai
            rm -rf /tmp/ca.crt
            rm -rf /tmp/dot-ai-token.txt
            log_success "Stale MCP authentication files removed"
        fi

        # Create symlink so docker-compose can mount Kind's kubeconfig
        log_info "Configuring MCP to use Kind cluster kubeconfig..."
        ln -sf ~/.kube/config ~/.kube/config-dot-ai
        log_success "MCP configured to use Kind cluster kubeconfig"
        MCP_CONFIGURED=true  # Set flag to remind about Claude Code restart

        return 0
    fi

    log_info "Creating service account for dot-ai MCP server..."

    # Create service account and token
    kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dot-ai
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dot-ai-cluster-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: dot-ai
  namespace: default
---
apiVersion: v1
kind: Secret
metadata:
  name: dot-ai-token
  namespace: default
  annotations:
    kubernetes.io/service-account.name: dot-ai
type: kubernetes.io/service-account-token
EOF

    log_info "Waiting for token to be generated..."
    # Note: kubectl wait --for=jsonpath requires kubectl v1.23+ (Nov 2021)
    # On older versions, this command will fail silently (error output is suppressed)
    # and fall back to the 5-second sleep below
    if ! kubectl wait --for=jsonpath='{.data.token}' secret/dot-ai-token -n default --timeout=30s &>/dev/null; then
        log_warning "Token not immediately available, waiting additional time..."
        sleep 5
    fi

    # Extract token and CA cert with error handling
    log_info "Extracting token and CA certificate..."

    # Clean up any existing files/directories to avoid conflicts
    rm -rf /tmp/dot-ai-token.txt /tmp/ca.crt

    local token_extracted=false
    local ca_extracted=false
    local token_valid=false
    local ca_valid=false

    if kubectl get secret dot-ai-token -n default -o jsonpath='{.data.token}' | base64 -d > /tmp/dot-ai-token.txt; then
        token_extracted=true
        if [ -s /tmp/dot-ai-token.txt ]; then
            token_valid=true
        fi
    fi

    if kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > /tmp/ca.crt; then
        ca_extracted=true
        if [ -s /tmp/ca.crt ]; then
            ca_valid=true
        fi
    fi

    # Check for failures and provide appropriate error messages
    if [ "$token_extracted" = false ] || [ "$token_valid" = false ]; then
        if [ "$token_extracted" = false ]; then
            log_error "Failed to extract dot-ai token from secret"
        else
            log_error "Token file is empty - secret may not be ready yet"
        fi
        return 1
    fi

    if [ "$ca_extracted" = false ] || [ "$ca_valid" = false ]; then
        if [ "$ca_extracted" = false ]; then
            log_error "Failed to extract CA certificate"
        else
            log_error "CA certificate file is empty"
        fi
        return 1
    fi

    # Get cluster server
    local cluster_server
    cluster_server=$(kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.server}')

    # Ensure ~/.kube directory exists with proper permissions
    mkdir -p ~/.kube
    chmod 700 ~/.kube

    # Create token-based kubeconfig
    # Note: CA cert path references /root/.kube/ca.crt (container path)
    # Docker Compose mounts /tmp/ca.crt (host) -> /root/.kube/ca.crt (container)
    cat > ~/.kube/config-dot-ai <<EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority: /root/.kube/ca.crt
    server: ${cluster_server}
  name: gke-cluster
contexts:
- context:
    cluster: gke-cluster
    user: dot-ai
  name: dot-ai-context
current-context: dot-ai-context
users:
- name: dot-ai
  user:
    token: $(cat /tmp/dot-ai-token.txt)
EOF

    log_success "MCP server authentication configured"

    # Set flag to show reminder at the end
    MCP_CONFIGURED=true
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

configure_argocd_webhook_secret() {
    log_info "Configuring ArgoCD webhook secret for instant GitHub sync..."

    # Wait for argocd-server to be ready before configuring webhook
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=60s

    # Generate a secure random webhook secret
    local webhook_secret
    webhook_secret=$(openssl rand -base64 32)

    # Add webhook secret to argocd-secret
    kubectl patch secret argocd-secret -n argocd --type=strategic \
        -p "{\"stringData\":{\"webhook.github.secret\":\"$webhook_secret\"}}"

    log_success "ArgoCD webhook secret configured"

    # Note: ArgoCD server automatically detects secret changes and restarts itself
    # No manual restart needed - server will reload configuration automatically

    # Save webhook secret to .env file (must be run from repository root)
    local env_file=".env"

    # Verify .env is in .gitignore (defensive check)
    if [ -f ".gitignore" ] && ! grep -q "^\.env$" ".gitignore"; then
        log_warning ".env is not in .gitignore - secrets may be committed to git!"
        log_warning "Add '.env' to .gitignore before proceeding"
    fi

    # Escape special characters in webhook_secret for sed (/, &, \)
    local webhook_secret_escaped
    webhook_secret_escaped=$(printf '%s\n' "$webhook_secret" | sed 's/[\/&]/\\&/g')

    if grep -q "^ARGOCD_WEBHOOK_SECRET=" "$env_file" 2>/dev/null; then
        # Update existing entry with escaped secret (portable sed syntax)
        if sed --version >/dev/null 2>&1; then
            # GNU sed (Linux)
            sed -i "s|^ARGOCD_WEBHOOK_SECRET=.*|ARGOCD_WEBHOOK_SECRET=$webhook_secret_escaped|" "$env_file"
        else
            # BSD sed (macOS)
            sed -i.bak "s|^ARGOCD_WEBHOOK_SECRET=.*|ARGOCD_WEBHOOK_SECRET=$webhook_secret_escaped|" "$env_file"
            rm -f "${env_file}.bak"
        fi
    else
        # Append new entry
        echo "" >> "$env_file"
        echo "# ArgoCD Webhook Secret for GitHub instant sync" >> "$env_file"
        echo "ARGOCD_WEBHOOK_SECRET=$webhook_secret" >> "$env_file"
    fi

    log_success "Webhook secret saved to $env_file"

    # Store webhook configuration for display at the end
    WEBHOOK_SECRET="$webhook_secret"
    WEBHOOK_URL="https://argocd.${BASE_DOMAIN}/api/webhook"

    # Create GitHub webhook
    log_info "Creating GitHub webhook for instant ArgoCD sync..."

    # Webhook creation is optional - script can continue without it
    if ! command -v gh &> /dev/null; then
        log_warning "GitHub CLI (gh) not found - skipping webhook creation"
        log_info "Webhook can be configured manually after setup completes"
        log_info "Install gh CLI from: https://cli.github.com/"
        return
    fi

    # Validate GitHub repository is detected
    if [ -z "$GITHUB_REPO" ]; then
        log_warning "Could not detect GitHub repository from git remote"
        log_info "Webhook can be configured manually after setup completes"
        return
    fi

    # Check if webhook already exists
    log_info "Checking for existing webhook..."
    existing_webhook=$(gh api "repos/${GITHUB_REPO}/hooks" 2>/dev/null | jq -r ".[] | select(.config.url == \"$WEBHOOK_URL\") | .id" 2>/dev/null || echo "")

    # Validate that we got a numeric webhook ID, not error JSON
    if [ -n "$existing_webhook" ] && [[ "$existing_webhook" =~ ^[0-9]+$ ]]; then
        log_info "Webhook already exists (ID: $existing_webhook)"
        log_success "Using existing GitHub webhook"

        # Store webhook ID for future management
        if [ -f ".env" ]; then
            if grep -q "^ARGOCD_WEBHOOK_ID=" ".env" 2>/dev/null; then
                if sed --version >/dev/null 2>&1; then
                    sed -i "s|^ARGOCD_WEBHOOK_ID=.*|ARGOCD_WEBHOOK_ID=$existing_webhook|" ".env"
                else
                    sed -i.bak "s|^ARGOCD_WEBHOOK_ID=.*|ARGOCD_WEBHOOK_ID=$existing_webhook|" ".env"
                    rm -f ".env.bak"
                fi
            else
                echo "ARGOCD_WEBHOOK_ID=$existing_webhook" >> ".env"
            fi
        fi
        return
    fi

    # Create new webhook (redirect stderr to prevent secret exposure)
    log_info "Creating new webhook..."
    webhook_response=$(gh api "repos/${GITHUB_REPO}/hooks" -X POST \
        -f name=web \
        -f config[url]="$WEBHOOK_URL" \
        -f config[content_type]=json \
        -f config[insecure_ssl]=0 \
        -f config[secret]="$WEBHOOK_SECRET" \
        -F events[]=push \
        -F active=true 2>/dev/null) || {
        log_warning "Failed to create GitHub webhook"
        log_info "Webhook can be configured manually after setup completes"
        log_info "Visit: https://github.com/${GITHUB_REPO}/settings/hooks"
        return
    }

    # Extract webhook ID from response
    webhook_id=$(echo "$webhook_response" | jq -r '.id' 2>/dev/null || echo "")

    if [ -n "$webhook_id" ]; then
        log_success "GitHub webhook created successfully (ID: $webhook_id)"

        # Store webhook ID in .env for future management
        if [ -f ".env" ]; then
            if grep -q "^ARGOCD_WEBHOOK_ID=" ".env" 2>/dev/null; then
                # Update existing entry
                if sed --version >/dev/null 2>&1; then
                    sed -i "s|^ARGOCD_WEBHOOK_ID=.*|ARGOCD_WEBHOOK_ID=$webhook_id|" ".env"
                else
                    sed -i.bak "s|^ARGOCD_WEBHOOK_ID=.*|ARGOCD_WEBHOOK_ID=$webhook_id|" ".env"
                    rm -f ".env.bak"
                fi
            else
                # Append new entry
                echo "ARGOCD_WEBHOOK_ID=$webhook_id" >> ".env"
            fi
            log_success "Webhook ID saved to .env"
        fi
    else
        log_success "GitHub webhook created successfully"
    fi
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

apply_spider_rainbows_ingress() {
    log_info "Applying spider-rainbows ingress with domain: spider-rainbows.${BASE_DOMAIN}"

    # Apply ingress directly to cluster (infrastructure-specific, not managed by ArgoCD)
    kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: spider-rainbows
  namespace: default
  labels:
    app: spider-rainbows
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
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

    log_success "Ingress applied with domain: spider-rainbows.${BASE_DOMAIN}"
}

deploy_spider_rainbows_app() {
    log_info "Deploying spider-rainbows application via ArgoCD..."

    local app_file
    app_file="$(dirname "$0")/gitops/applications/spider-rainbows-app.yaml"

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
    log_info "🕷️  Spider-Rainbows Demo Setup"
    log_info "==============================="
    echo ""

    # Verify we're running from the repository root
    if [ ! -f "package.json" ] || [ ! -d "src/components" ]; then
        log_error "Must run this script from the repository root"
        log_info "Expected to find: package.json and src/components/"
        exit 1
    fi

    # Initialize MCP configuration flag
    MCP_CONFIGURED=false

    # Parse command-line arguments for cluster type
    if [ $# -gt 0 ]; then
        case "$1" in
            kind)
                DEPLOYMENT_MODE="kind"
                log_success "Cluster type: Kind (local)"
                ;;
            gcp)
                DEPLOYMENT_MODE="gcp"
                log_success "Cluster type: GCP (cloud)"
                ;;
            *)
                log_error "Invalid cluster type: $1"
                log_info "Usage: $0 [kind|gcp]"
                exit 1
                ;;
        esac
    else
        # Prompt for deployment mode if no argument provided
        prompt_deployment_mode
    fi

    # Phase 1: Cluster and Ingress
    check_prerequisites
    create_cluster
    configure_mcp_authentication  # Configure MCP server auth if needed
    install_ingress_controller

    # Phase 2: ArgoCD Installation
    install_argocd
    configure_argocd_password
    configure_argocd_sync_interval
    configure_argocd_webhook_secret
    install_argocd_ingress
    validate_argocd_health

    # Phase 3: GitOps Repository Connection & App Deployment
    deploy_spider_rainbows_app
    validate_app_sync
    apply_spider_rainbows_ingress  # Apply environment-specific ingress (not managed by ArgoCD)
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
        if [[ "$DEPLOYMENT_MODE" == "kind" ]]; then
            log_info "Context: kind-$CLUSTER_NAME"
        elif [[ "$DEPLOYMENT_MODE" == "gcp" ]]; then
            local current_context
            current_context=$(kubectl config current-context)
            log_info "Context: $current_context"
        fi
        echo ""
        log_info "ArgoCD Access:"
        log_info "  URL: https://argocd.${BASE_DOMAIN}"
        log_info "  Username: admin"
        log_info "  Password: admin123"
        echo ""
        log_info "GitHub Webhook (for instant sync):"
        if command -v gh &> /dev/null; then
            log_success "  ✓ Automatically configured"
            log_info "  URL: ${WEBHOOK_URL}"
            log_info "  View at: https://github.com/wiggitywhitney/spider-rainbows/settings/hooks"
        else
            log_warning "  Manual setup required (gh CLI not installed)"
            log_info "  URL: ${WEBHOOK_URL}"
            log_info "  Secret: See ARGOCD_WEBHOOK_SECRET in .env"
            log_info "  Content type: application/json"
            log_info "  Events: Push events"
            log_info "  Configure at: https://github.com/wiggitywhitney/spider-rainbows/settings/hooks"
        fi
        echo ""
        log_info "Spider-Rainbows App:"
        log_info "  URL: http://spider-rainbows.${BASE_DOMAIN}"
        log_info "  Health: http://spider-rainbows.${BASE_DOMAIN}/health"
        echo ""
        log_info "Demo is ready! 🎉"
        log_info ""
        log_info "Next steps:"
        log_info "  - Open ArgoCD UI to view application status"
        log_info "  - Test app at http://spider-rainbows.${BASE_DOMAIN}"
        log_info "  - Make code changes to trigger CI/CD workflow"
        echo ""

        # Show MCP reminder if it was configured
        if [ "$MCP_CONFIGURED" = true ]; then
            log_info "⚠️  MCP Server Authentication Updated"
            log_info "Restart Claude Code to connect dot-ai MCP server to this cluster"
            echo ""
        fi
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

        # Offer cleanup on validation failure
        read -p "Setup failed. Do you want to cleanup the partial cluster? [y/N]: " cleanup_choice
        if [[ "$cleanup_choice" =~ ^[Yy]$ ]]; then
            log_info "Running cleanup..."
            ./destroy.sh
        else
            log_info "Cluster preserved for troubleshooting - run ./destroy.sh when ready"
        fi
        exit 1
    fi
}

main "$@"
