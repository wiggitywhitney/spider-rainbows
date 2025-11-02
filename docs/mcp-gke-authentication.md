# dot-ai MCP Server with GKE Clusters

## Problem

GKE kubeconfigs use `gke-gcloud-auth-plugin` which isn't available inside Docker containers, causing:
```
error: "spawn gke-gcloud-auth-plugin ENOENT"
```

## Solution: Service Account Token Authentication

Use Kubernetes service account tokens instead of gcloud auth plugins.

### Quick Setup

1. **Create service account and token:**

```bash
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
```

2. **Generate token-based kubeconfig:**

```bash
# Extract token and CA cert
kubectl get secret dot-ai-token -n default -o jsonpath='{.data.token}' | base64 -d > /tmp/dot-ai-token.txt
kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > /tmp/ca.crt

# Get cluster server
CLUSTER_SERVER=$(kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.server}')

# Create kubeconfig
cat > ~/.kube/config-dot-ai <<EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority: /root/.kube/ca.crt
    server: ${CLUSTER_SERVER}
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
```

3. **Update docker-compose-dot-ai.yaml volumes:**

```yaml
volumes:
  - ~/.kube/config-dot-ai:/root/.kube/config:ro
  - /tmp/ca.crt:/root/.kube/ca.crt:ro
```

4. **Restart Claude Code**

### Verify

```bash
claude mcp list  # Should show dot-ai connected
```

Use `mcp__dot-ai__version` tool - should show `"kubernetes.connected": true`

## Security Note

⚠️ This uses `cluster-admin` for simplicity. For production, use a restricted Role with minimal permissions.

## Why This Works

Token authentication is standard Kubernetes - no external dependencies, works in containers, portable across all K8s clusters.
