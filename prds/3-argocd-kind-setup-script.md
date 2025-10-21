# PRD: ArgoCD + Kind Setup Script for GitOps Conference Demo

**GitHub Issue**: [#3](https://github.com/wiggitywhitney/spider-rainbows/issues/3)
**Status**: Ready for Implementation
**Created**: 2025-10-21
**Last Updated**: 2025-10-21

---

## Problem Statement

Need a reproducible, reliable setup script for a conference demo that shows the complete GitOps CI/CD workflow. The demo compares GenAI assistance vs programmatic execution at each stage of the software delivery pipeline (steps 0-9: feature completion → push → PR → CI → review → merge → CD → ArgoCD sync → cluster deployment → observability).

Currently, the existing `kind/deploy.sh` only handles basic deployment without ArgoCD or GitOps patterns. For the conference talk, we need a production-realistic GitOps environment that:
- Uses ArgoCD to manage deployments declaratively
- Demonstrates automatic synchronization from Git to cluster
- Provides reliable ingress access via `nip.io` domains
- Can be set up quickly and consistently before/during demo prep

---

## Solution Overview

Create a single monolithic setup script (`kind/setup-argocd.sh`) that provisions a complete GitOps environment:

1. **Kind cluster** with ingress controller and proper port mappings for `*.nip.io` access
2. **ArgoCD** installed with self-management capability (manages itself via GitOps)
3. **GitOps repository connection** pointing to a separate public config repo
4. **Spider-rainbows application** deployed via ArgoCD with auto-sync enabled
5. **Health validation** ensuring all components are ready before script completes

The script creates the environment once; the conference demo then shows a developer workflow where code changes flow through CI/CD and into the cluster automatically.

---

## User Journey

### Setup Phase (Pre-Demo)
1. **Presenter** clones spider-rainbows repo
2. **Presenter** runs `./kind/setup-argocd.sh`
3. **Script** creates kind cluster, installs ArgoCD, connects to GitOps repo
4. **Script** validates health and outputs access URLs:
   - ArgoCD UI: `https://argocd.127.0.0.1.nip.io`
   - Spider-rainbows app: `http://spider-rainbows.127.0.0.1.nip.io`
5. **Presenter** verifies app is accessible in browser
6. Environment is ready for conference demo

### Demo Phase (During Talk)
1. **Developer** (presenter) makes code change to spider-rainbows
2. **Demo** walks through each CI/CD stage (0-9), discussing GenAI vs programmatic approaches
3. **ArgoCD** automatically syncs changes from GitOps repo to cluster (step 7)
4. **Audience** sees changes propagate in real-time via ArgoCD UI and app URL

### Cleanup Phase (Post-Demo)
1. **Presenter** runs `./kind/destroy.sh` (existing script)
2. Cluster is deleted cleanly

---

## Success Criteria

### Must Have
- [ ] Single command (`./kind/setup-argocd.sh`) creates entire environment without manual intervention
- [ ] ArgoCD UI accessible at `https://argocd.127.0.0.1.nip.io` without port-forwarding
- [ ] Spider-rainbows app accessible at `http://spider-rainbows.127.0.0.1.nip.io`
- [ ] ArgoCD configured with auto-sync enabled for spider-rainbows application
- [ ] Script validates all components are healthy before completion (cluster, ArgoCD, app pods, ingress)
- [ ] App `/health` endpoint returns 200 OK via ingress
- [ ] Script completes in under 5 minutes on typical hardware
- [x] Clear console output showing progress at each major step
- [ ] Works with public GitOps repository (no auth required)

### Should Have
- [x] Script is idempotent (can detect existing cluster and skip/update gracefully)
- [x] Helpful error messages if prerequisites missing (kind, kubectl, docker)
- [ ] ArgoCD admin password displayed at end for UI login
- [ ] Fallback instructions if `nip.io` DNS fails on conference wifi

### Won't Have (Out of Scope)
- CI/CD pipeline setup (GitHub Actions) - separate concern
- CD process for updating GitOps repo manifests - handled separately
- ArgoCD Image Updater - not needed for demo
- Multiple environments (dev/staging/prod) - single demo environment only
- Helm charts - using plain Kubernetes manifests

---

## Technical Scope

### Components to Install/Configure

1. **Kind Cluster Configuration**
   - Single control-plane node with ingress-ready label
   - Extra port mappings: 80 (HTTP), 443 (HTTPS)
   - Custom cluster name: `spider-rainbows-gitops`

2. **Ingress Controller**
   - NGINX Ingress Controller (kind's standard)
   - Configured for `*.nip.io` wildcard domains
   - Ingress resources for ArgoCD and spider-rainbows app

3. **ArgoCD Installation**
   - Install via official manifests or Helm chart
   - Configure for self-management (ArgoCD manages ArgoCD)
   - Expose UI via Ingress with HTTPS
   - Set up admin password (known value for demos)

4. **GitOps Repository Connection**
   - Configure ArgoCD to watch external public GitOps repo
   - Create ArgoCD `Application` CR pointing to spider-rainbows manifests in GitOps repo
   - Enable auto-sync and self-heal

5. **Application Deployment**
   - Spider-rainbows deployed via ArgoCD (not kubectl directly)
   - Uses image from DockerHub: `wiggitywhitney/spider-rainbows:*`
   - Ingress resource for app access via `nip.io`

### Files to Create/Modify

**New Files:**
- `kind/setup-argocd.sh` - Main setup script
- `kind/cluster-config.yaml` - Kind cluster configuration with ingress
- `kind/argocd-ingress.yaml` - Ingress for ArgoCD UI
- `kind/spider-rainbows-app.yaml` - ArgoCD Application CR
- `kind/spider-rainbows-ingress.yaml` - Ingress for app

**Files to Delete:**
- `kind/deployment.yaml` - Replaced by GitOps repo manifests (avoiding confusion)

**Files to Keep:**
- `kind/destroy.sh` - Still useful for cleanup

### GitOps Repository Structure (Separate Repo)

The `spider-rainbows-platform-config` repository should contain:
```
/
├── argocd/
│   └── self-management-app.yaml   # ArgoCD Application managing ArgoCD itself
├── spider-rainbows/
│   ├── deployment.yaml             # Spider-rainbows Deployment
│   ├── service.yaml                # Spider-rainbows Service
│   └── ingress.yaml                # Spider-rainbows Ingress
└── README.md
```

### Health Checks

Script validates:
1. Kind cluster nodes are Ready
2. Ingress controller pods are Running
3. ArgoCD pods are Running and Healthy
4. ArgoCD Application status is Synced and Healthy
5. Spider-rainbows pods are Ready
6. Ingress endpoints respond (curl checks):
   - `https://argocd.127.0.0.1.nip.io` returns ArgoCD login page
   - `http://spider-rainbows.127.0.0.1.nip.io/health` returns 200 OK

---

## Integration Points

### With Existing Spider-Rainbows Repo
- Script lives in `kind/` directory alongside existing scripts
- Uses existing `Dockerfile` and `server.js` (no changes needed)
- Assumes container images already pushed to DockerHub
- No changes to application code required

### With GitOps Repository
- Script references GitOps repo URL (configurable variable)
- No write access needed (public repo, read-only)
- GitOps repo must exist before running script
- GitOps repo manifests must reference valid Docker images

### With Conference Demo Workflow
- **Pre-demo**: Run setup script to create environment
- **During demo**: Manual code changes → CI/CD workflow → ArgoCD auto-sync
- **Post-demo**: Run destroy script for cleanup
- Script must be reliable enough to run day-of if needed

---

## Implementation Plan

### Phase 1: Kind Cluster with Ingress
**Goal**: Create kind cluster that supports ingress with `nip.io` domains

**Tasks**:
- Create `kind/cluster-config.yaml` with control-plane node configuration
- Add `extraPortMappings` for ports 80 and 443
- Add node labels for ingress-ready
- Update `setup-argocd.sh` to create cluster using config file
- Install NGINX Ingress Controller
- Validate ingress controller is running

**Validation**: `kubectl get pods -n ingress-nginx` shows running pods

---

### Phase 2: ArgoCD Installation
**Goal**: Install ArgoCD and make it accessible via ingress

**Tasks**:
- Install ArgoCD in `argocd` namespace (kubectl apply or helm)
- Wait for ArgoCD pods to be healthy
- Create `kind/argocd-ingress.yaml` for UI access
- Configure known admin password for demos
- Test ArgoCD UI login at `https://argocd.127.0.0.1.nip.io`

**Validation**: ArgoCD UI loads and accepts admin credentials

---

### Phase 3: GitOps Repository Connection
**Goal**: Connect ArgoCD to external GitOps repository

**Tasks**:
- Document GitOps repo structure requirements (in PRD or README)
- Create `kind/spider-rainbows-app.yaml` (ArgoCD Application CR)
- Configure Application to point to GitOps repo URL
- Enable auto-sync and self-heal
- Apply Application manifest to cluster
- Wait for ArgoCD to sync application

**Validation**: ArgoCD UI shows spider-rainbows application as Synced and Healthy

---

### Phase 4: Application Ingress
**Goal**: Make spider-rainbows accessible via `nip.io` domain

**Tasks**:
- Create `kind/spider-rainbows-ingress.yaml`
- Apply ingress resource (or include in GitOps repo)
- Test app access at `http://spider-rainbows.127.0.0.1.nip.io`
- Test health endpoint at `http://spider-rainbows.127.0.0.1.nip.io/health`

**Validation**: App loads in browser, health check returns 200

---

### Phase 5: Health Checks & Validation
**Goal**: Script validates all components before completion

**Tasks**:
- Add bash functions for health checks
- Check cluster node readiness
- Check pod statuses for all namespaces
- Curl ingress endpoints
- Display summary with access URLs and admin password
- Add error handling for failed checks

**Validation**: Script exits with success only when all checks pass

---

### Phase 6: Documentation & Cleanup
**Goal**: Complete documentation and remove deprecated files

**Tasks**:
- Delete `kind/deployment.yaml` (no longer needed, GitOps is source of truth)
- Update main `README.md` with ArgoCD setup instructions
- Document GitOps repository setup process
- Document `nip.io` fallback if DNS issues occur
- Add troubleshooting section for common issues
- Test full setup from scratch on clean machine

**Validation**: Someone else can follow docs and successfully set up environment

---

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| `nip.io` DNS fails on conference wifi | High - demo breaks | Medium | Test on conference network beforehand; document port-forward fallback |
| Script takes >5 minutes to run | Medium - wastes demo time | Low | Run during conference setup, not live; optimize wait times |
| GitOps repo structure mismatch | High - app won't deploy | Medium | Clear documentation; validate repo structure in script |
| ArgoCD self-management chicken-egg problem | Medium - setup complexity | Medium | Bootstrap ArgoCD imperatively first, then hand over to self-management |
| Image pull failures from DockerHub | High - no app | Low | Pre-pull images or use `kind load` as backup |
| Ingress controller doesn't start | High - no access | Low | Add retry logic; validate ingress controller before continuing |

---

## Milestones

- [x] **Milestone 1**: Kind cluster with working ingress controller created and validated
- [ ] **Milestone 2**: ArgoCD installed, accessible via `nip.io` ingress, and healthy
- [ ] **Milestone 3**: ArgoCD connected to GitOps repo and spider-rainbows application synced
- [ ] **Milestone 4**: Spider-rainbows app accessible via `nip.io` domain with health check passing
- [ ] **Milestone 5**: Health validation and script completion reporting working reliably
- [ ] **Milestone 6**: Documentation complete and deprecated files removed; ready for conference demo

---

## Design Decisions

### Decision 1: GitOps Repository Naming
**Date**: 2025-10-21
**Decision**: Use `spider-rainbows-platform-config` as the GitOps repository name
**Rationale**:
- "platform" indicates infrastructure/platform-level configs (cluster, ArgoCD, ingress)
- "config" accurately describes contents (both platform and app configuration)
- Scales well for future platform concerns beyond just application manifests
- Professional naming for conference demo narrative
**Impact**: Updates all references to GitOps repo throughout PRD and implementation

### Decision 2: ArgoCD Installation Method
**Date**: 2025-10-21
**Decision**: Use kubectl apply with official ArgoCD manifests (not Helm)
**Rationale**:
- Simpler approach with fewer dependencies (no Helm required)
- Better migration path to Crossplane: plain manifests → Crossplane Object resources
- Avoids unnecessary abstraction layer (Helm) between kubectl and Crossplane
- More transparent - see exactly what's being installed
- Aligns with eventual Crossplane migration strategy
**Impact**: Script will use `kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml`

### Decision 3: ArgoCD Admin Password
**Date**: 2025-10-21
**Decision**: Hardcode admin password as `admin123`
**Rationale**:
- Easy to remember during conference demo
- Consistent across all demo runs
- Simplifies documentation and demo instructions
- Security not a concern for local ephemeral demo clusters
**Impact**: Script will patch argocd-secret to set known password; README documents login credentials

### Decision 4: Self-Management Bootstrap Timing
**Date**: 2025-10-21
**Decision**: Bootstrap ArgoCD self-management as separate step after ArgoCD is healthy
**Rationale**:
- Easier to troubleshoot if issues occur during conference setup
- Can verify ArgoCD works before adding self-management complexity
- Clearer separation: imperative bootstrap → declarative GitOps handover
- Better reliability for live demo environment
**Impact**: Script will have distinct phases: (1) Install ArgoCD + validate health, (2) Apply self-management Application

### Decision 5: Error Handling Philosophy
**Date**: 2025-10-21
**Decision**: Strict error handling with `set -e` (fail fast)
**Rationale**:
- Fails immediately on any error - no ambiguous half-working states
- More reliable for conference demo (either works completely or fails clearly)
- Easier to debug - know exactly where failure occurred
- Re-running entire script is acceptable for demo setup scenario
**Impact**: Script uses `set -e` and `set -o pipefail`; no silent failures or warning-only errors

---

## Dependencies

### External Tools Required
- `kind` (Kubernetes in Docker)
- `kubectl` (Kubernetes CLI)
- `docker` (Container runtime)
- `curl` (for health checks)

### External Services
- DockerHub (for pulling spider-rainbows images)
- `nip.io` DNS service (external wildcard DNS)
- GitHub (for hosting GitOps repository)

### Repository Dependencies
- GitOps repository must exist before running script
- GitOps repository must contain valid Kubernetes manifests
- Docker images must be pushed to DockerHub before deployment

---

## Progress Log

### 2025-10-21: Initial PRD Creation and Design Decisions
**Duration**: ~1.5 hours
**Focus**: Requirements gathering and design decision-making

**Completed Activities**:
- Completed comprehensive requirements gathering through Q&A (8 questions)
- Defined conference demo use case: GenAI vs programmatic CI/CD workflow (steps 0-9)
- Identified all technical components and integration points
- Created 6-milestone implementation structure
- Documented risks and open questions
- Resolved all 5 open questions through systematic decision-making process
- Created GitHub issue #3 with PRD label
- Updated PRD with Design Decisions section

**Key Decisions Made**:
1. GitOps repository naming: `spider-rainbows-platform-config`
2. ArgoCD installation: kubectl apply with official manifests (better Crossplane migration path)
3. Admin password: Hardcoded as `admin123` for demo simplicity
4. Self-management timing: Separate bootstrap step for better troubleshooting
5. Error handling: Strict fail-fast approach for reliability

**Strategic Insights**:
- Chose kubectl over Helm to avoid unnecessary abstraction layer before Crossplane migration
- Prioritized demo reliability over production realism (hardcoded password, strict errors)
- Separated bootstrap phases for easier troubleshooting during conference setup

**Next Steps**:
- Create `spider-rainbows-platform-config` repository with documented structure
- Begin Milestone 1: Kind cluster with ingress controller implementation
- Start implementing `kind/setup-argocd.sh` script with decided approaches

### 2025-10-21: Phase 1 Implementation - Cluster with Ingress Controller
**Duration**: ~45 minutes
**Status**: Phase 1 Complete ✅

**Completed Activities**:
- Created `kind/cluster-config.yaml` with ingress-ready configuration
  - Single control-plane node with proper labels
  - Port mappings for HTTP (80) and HTTPS (443) traffic
  - Cluster name: `spider-rainbows-gitops`
- Created `kind/setup-argocd.sh` script with Phase 1 functionality
  - Prerequisite validation (kind, kubectl, docker, curl)
  - Docker daemon health check
  - Cluster creation using config file
  - NGINX Ingress Controller installation (v1.9.4)
  - Health validation for cluster nodes and ingress pods
  - Color-coded console output with clear progress messages
  - Strict error handling with fail-fast behavior (`set -euo pipefail`)
- Tested Phase 1 end-to-end successfully
  - Cluster creation verified
  - Ingress controller ready and healthy
  - All validation checks passing

**Milestone Completed**:
- ✅ **Milestone 1**: Kind cluster with working ingress controller created and validated

**Success Criteria Completed**:
- ✅ Clear console output showing progress at each major step
- ✅ Script is idempotent (can detect existing cluster and skip/update gracefully)
- ✅ Helpful error messages if prerequisites missing (kind, kubectl, docker)

**Next Session Priorities**:
- Phase 2: Install ArgoCD and configure ingress access
- Create ArgoCD ingress resource for `https://argocd.127.0.0.1.nip.io`
- Configure admin password and validate UI accessibility

---

## Future Enhancements (Post-Demo)

These are intentionally out of scope for the conference demo but could be valuable later:

- **CI/CD Pipeline**: Add GitHub Actions for automated image builds and GitOps repo updates
- **ArgoCD Image Updater**: Automatically update image tags when new versions are pushed
- **Monitoring Stack**: Add Prometheus/Grafana for observability demonstrations
- **Multi-environment**: Support dev/staging/prod namespaces
- **Helm Charts**: Convert manifests to Helm charts for parameterization
- **Secrets Management**: Demonstrate sealed-secrets or external-secrets operator
- **Progressive Delivery**: Add Argo Rollouts for canary/blue-green deployments
