# PRD: Cloud Demo Environment with Custom Domain

**Status**: Draft
**Created**: 2025-10-28
**GitHub Issue**: [#10](https://github.com/wiggitywhitney/spider-rainbows/issues/10)
**Priority**: Medium

---

## Related Resources

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [AKS Documentation](https://learn.microsoft.com/en-us/azure/aks/)
- [GoDaddy API Documentation](https://developer.godaddy.com/doc/endpoint/domains)
- [Current setup-platform.sh](../kind/setup-platform.sh) (Kind version to mirror)
- [ArgoCD Installation Guide](https://argo-cd.readthedocs.io/en/stable/getting_started/)

---

## Problem Statement

The current Kind-based demo environment requires local setup before each presentation and provides only temporary, session-based URLs. This prevents:
- **Persistent accessibility**: Cannot share a stable URL that's always available
- **Personal branding**: Cannot showcase work via custom domain (whitneylee.com)
- **Pre-demo sharing**: Cannot send URL in advance of presentations
- **Portfolio presence**: Cannot use demo as persistent part of professional portfolio

**Current State**:
- Demo runs on Kind (local Kubernetes)
- Setup required before each presentation
- URLs are temporary and session-specific
- No custom domain integration
- Requires local machine to be running

**User Impact**:
- Cannot include demo in email signatures, LinkedIn, portfolio sites
- Cannot share stable URL with potential employers/clients
- Must recreate environment for each demo
- Professional branding opportunity missed

---

## Solution Overview

Create flexible deployment scripts that support both local (Kind) and cloud (GKE) Kubernetes clusters with the complete spider-rainbows GitOps demo environment. The script prompts users to choose their deployment type, then provisions the appropriate cluster. Both options use nip.io for automatic DNS resolution, eliminating the need for manual DNS management. Consolidate the ArgoCD configuration repository into this repository to simplify setup.

**Key Features**:
1. Setup script prompts user at start: "Choose deployment: (1) Kind (2) GCP?"
2. Creates appropriate Kubernetes cluster (Kind or GKE)
3. Deploys full stack: spider-rainbows app, ArgoCD, ingress-nginx
4. For cloud: Configures LoadBalancer with public IP
5. For cloud: Constructs nip.io domain from public IP (e.g., `spider-rainbows.<IP>.nip.io`)
6. Consolidates ArgoCD config into `argocd-config/` directory (no separate repo needed)
7. Destroy script tears down all resources cleanly
8. Same workflow for both deployment methods

**Architecture**:

**Option A - Local (Kind)**:
```
[Host Machine]
  ├─ Kind Cluster
  │   ├─ Ingress-nginx (NodePort with host port mapping)
  │   ├─ ArgoCD (local access)
  │   ├─ Spider-rainbows app (2 replicas)
  │   └─ Access: http://spider-rainbows.127.0.0.1.nip.io
  └─ GitOps Config (in spider-rainbows/argocd-config/)
```

**Option B - Cloud (GCP)**:
```
[Cloud Kubernetes Cluster (GKE)]
  ├─ Ingress-nginx (LoadBalancer with public IP)
  ├─ ArgoCD (GitOps management)
  ├─ Spider-rainbows app (2 replicas)
  └─ Public IP: X.X.X.X

[nip.io DNS Resolution]
  spider-rainbows.<IP>.nip.io → Automatic via nip.io
  argocd.<IP>.nip.io → Automatic via nip.io

[Spider-rainbows Repository]
  └─ argocd-config/ (GitOps manifests - no separate repo)

[GitHub Actions CI/CD]
  Build → Push → Update spider-rainbows repo → ArgoCD syncs
```

---

## Goals & Success Criteria

### Primary Goals
- [ ] Setup script supports both Kind (local) and GCP (cloud) deployment
- [ ] Script prompts user at start: "Which cluster? (1) Kind (2) GCP?"
- [ ] Kind deployment works quickly (already working in PRD #3)
- [ ] GCP deployment creates complete cloud environment in <15 minutes
- [ ] Automatic nip.io DNS resolution for GCP deployments
- [ ] Consolidated ArgoCD config (no separate repository needed)
- [ ] Full GitOps workflow with ArgoCD
- [ ] Destroy script cleanly removes all resources
- [ ] Cost-efficient resource sizing for demo workloads

### Success Metrics
- [ ] spider-rainbows.<IP>.nip.io resolves and loads app within 5 minutes of setup
- [ ] CI/CD pipeline successfully deploys to cloud cluster
- [ ] ArgoCD syncs and manages deployments automatically
- [ ] Setup/destroy scripts are idempotent and reliable
- [ ] nip.io DNS works immediately upon LoadBalancer IP assignment

### Non-Goals
- Cost optimization (user will manage personally)
- Multi-region deployment
- High availability / production SLAs
- Custom cloud networking (VPCs, service mesh)
- Backup/disaster recovery

---

## User Stories & Use Cases

### Primary User Story
**As a** developer/presenter with whitneylee.com domain
**I want** a persistent cloud demo at spiders.whitneylee.com
**So that** I can showcase my work via professional custom domain and share stable URL

**Acceptance Criteria**:
- Run setup script once
- Cluster provisions and configures automatically
- spiders.whitneylee.com is immediately accessible
- URL remains stable and accessible indefinitely
- Can include URL in portfolio, email signature, LinkedIn
- CI/CD updates deploy automatically via ArgoCD

### Use Case 1: Portfolio Integration
**Context**: Adding demo to professional portfolio
**Flow**:
1. Run `./cloud/setup-cloud-platform.sh`
2. Script completes, displays: "✅ Demo live at https://spiders.whitneylee.com"
3. Add URL to portfolio website, LinkedIn, resume
4. URL remains accessible for months/years
5. Make code changes → CI/CD deploys → visitors see updates

### Use Case 2: Pre-Demo Sharing
**Context**: Conference presentation next week
**Flow**:
1. Setup cloud demo 5 days before conference
2. Share spiders.whitneylee.com in presentation slides/materials
3. Attendees can access before, during, and after presentation
4. Demo remains live for follow-up questions
5. Destroy after conference when no longer needed

### Use Case 3: Job Interview Demo
**Context**: Technical interview showcasing live project
**Flow**:
1. Send spiders.whitneylee.com link in advance
2. Interviewer explores demo before interview
3. During interview, make live changes and deploy via CI/CD
4. Interviewer sees real-time GitOps workflow
5. Demo remains accessible for follow-up discussions

---

## Technical Approach

### Deployment Options

**Primary Implementation**: Single unified script with interactive mode selection
- Script: `./kind/setup-platform.sh`
- Interactive prompt at start: "Which cluster? (1) Kind (2) GCP?"
- Git integration: Work from feature branch for PRD #10

**Option A: Local Kind Deployment**:
- Uses existing `setup-platform.sh` workflow
- No changes needed - already functional in PRD #3
- Access: http://spider-rainbows.127.0.0.1.nip.io (localhost)
- Good for: Quick demo prep, offline work

**Option B: GCP Cloud Deployment**:
- Provider: Google Cloud Kubernetes Engine (GKE)
- CLI: `gcloud` container clusters create
- Authentication: `gcloud auth login` (beforehand)
- LoadBalancer: Automatically provisions external IP
- DNS: nip.io automatic resolution using LoadBalancer IP
- Cost: ~$0.10/hour for e2-medium nodes
- Good for: 24/7 accessible demo, persistent portfolio link

### Config Repository Consolidation

**Current State** (PRD #3):
- Separate repository: `spider-rainbows-platform-config`
- Lives outside spider-rainbows repo
- Requires separate setup

**New State** (PRD #10):
- Consolidated into: `argocd-config/` directory
- Lives inside spider-rainbows repository
- Single source of truth
- Easier setup and maintenance

**Repository Structure**:
```
spider-rainbows/
├── src/                          # React app
├── kind/                         # Deployment scripts
├── argocd-config/               # NEW: GitOps manifests (consolidated)
│   ├── argocd/
│   │   └── spider-rainbows-app.yaml    # ArgoCD Application CR
│   └── spider-rainbows/
│       ├── deployment.yaml
│       ├── service.yaml
│       └── ingress.yaml
├── Dockerfile
└── ...
```

### Architecture Components

**1. Kubernetes Cluster**
- Single-node or minimal node pool (demo workload is light)
- Standard cluster configuration
- Public endpoint access
- Automatic node/version management

**2. Ingress Controller**
- nginx-ingress-controller
- Service type: LoadBalancer (gets public IP automatically)
- Configured for external access

**3. ArgoCD**
- Deployed via official manifests
- GitOps repository connection to spider-rainbows-platform-config
- Auto-sync enabled
- Custom domain: argocd.spiders.whitneylee.com (optional)

**4. Spider-Rainbows Application**
- Deployed via ArgoCD
- 2 replicas (like Kind setup)
- Service + Ingress configuration
- Health endpoints configured

**5. DNS Configuration**
- nip.io automatic DNS resolution
- No manual DNS management required
- Immediate availability upon LoadBalancer IP assignment
- Pattern: spider-rainbows.<IP>.nip.io and argocd.<IP>.nip.io

### Implementation Details

**Setup Script Flow**:
```bash
1. Prompt user: "Which cluster? (1) Kind (2) GCP?"
2. Check prerequisites (based on selection)
3. Create Kubernetes cluster (Kind or GKE)
4. Configure kubectl context
5. Install ingress-nginx (NodePort for Kind, LoadBalancer for GCP)
6. For GCP: Wait for LoadBalancer IP assignment
7. Install ArgoCD
8. Configure ArgoCD Application for spider-rainbows
9. Validate access via nip.io domain
10. Display success message with URLs
```

**Destroy Script Flow**:
```bash
1. Confirm deletion (prevent accidents)
2. Delete Kubernetes cluster (removes all resources)
3. Display confirmation
```

**DNS Resolution via nip.io**:
- No API calls needed
- Automatic resolution for any IP: `<domain>.<IP>.nip.io`
- Examples:
  - `spider-rainbows.34.23.45.67.nip.io`
  - `argocd.34.23.45.67.nip.io`
- No DNS propagation delays

### Technical Considerations

**DNS Resolution via nip.io**:
- Immediate availability upon IP assignment
- No propagation delays
- No external API dependencies
- Works for any IP address pattern

**Cloud Provider Quotas**:
- Document required quotas (IPs, CPUs, LoadBalancers)
- Handle quota exceeded errors gracefully
- Provide clear error messages

**Authentication**:
- Require cloud CLI authentication before running (for GCP)
- For Kind: No additional auth needed beyond Docker
- Document credential setup clearly

**Idempotency**:
- Setup script checks if cluster exists
- Graceful handling of partial failures
- Resume/retry capability for interrupted setups

---

## Implementation Milestones

### Milestone 1: Interactive Mode Selection and Cloud Provider Foundation
**Goal**: Script prompts user for deployment type, then creates appropriate cluster

**Tasks**:
- Add interactive prompt: "Which cluster? (1) Kind (2) GCP?"
- Implement mode-specific prerequisite checking
- Create cluster provisioning logic for both modes
- Implement cluster deletion for both modes
- Add error handling and logging throughout

**Success Criteria**:
- User prompted and can select Kind or GCP
- Script validates all prerequisites based on selection
- Kind cluster creation works as before
- GCP cluster creation works with gcloud
- Destroy script cleanly removes resources for both modes
- No manual cloud console interaction needed

---

### Milestone 2: Ingress and LoadBalancer Configuration
**Goal**: Public IP exposed and accessible, with nip.io DNS ready

**Tasks**:
- Install nginx-ingress-controller (same for both modes)
- Configure NodePort for Kind (existing behavior)
- Configure LoadBalancer service for GCP
- Wait for and capture external IP (GCP only)
- Construct nip.io domain from IP
- Validate HTTP access via nip.io domain
- Handle IP assignment failures/timeouts

**Success Criteria**:
- Kind: Works as before with 127.0.0.1.nip.io
- GCP: LoadBalancer gets public IP
- nip.io domain works immediately (e.g., spider-rainbows.34.23.45.67.nip.io)
- Script displays assigned domain clearly
- Timeout handling for slow provisioning

---

### Milestone 3: ArgoCD and GitOps Integration
**Goal**: Full GitOps workflow operational in both environments

**Tasks**:
- Install ArgoCD via manifests (same for both modes)
- Configure ArgoCD ingress with dynamic nip.io hostname
- Consolidate config into `argocd-config/` directory
- Configure ArgoCD Application CR for spider-rainbows
- Verify auto-sync functionality
- Set ArgoCD admin password

**Success Criteria**:
- ArgoCD successfully deployed in both modes
- Spider-rainbows app syncs and deploys
- GitOps workflow functional (push to repo → auto-deploy)
- App accessible via nip.io domain (both modes)
- ArgoCD UI accessible via nip.io domain

---

### Milestone 4: Validation and Documentation
**Goal**: Complete, tested, documented solution for both deployment types

**Tasks**:
- Add comprehensive validation checks for both modes
- Test complete setup/destroy cycles (Kind and GCP)
- Document prerequisites for each mode
- Create mode-specific setup walkthroughs
- Add troubleshooting guide
- Document cleanup procedures
- Update README with cloud deployment option
- Test CI/CD pipeline integration

**Success Criteria**:
- Setup script completes end-to-end for both modes
- All validation checks pass
- Documentation enables reproduction
- Common issues documented with solutions
- Destroy script works reliably for both modes

---

## Dependencies & Integration Points

### External Dependencies

**Cloud Provider (GKE)**:
- Google Cloud account with billing enabled
- `gcloud` CLI tools installed
- Sufficient quotas for resources (IPs, CPUs, LoadBalancers)
- Authentication configured

**Existing Infrastructure**:
- GitHub Actions CI/CD pipeline
- spider-rainbows-platform-config GitOps repository
- Docker Hub for images
- nip.io for automatic DNS (no additional setup needed)

### Internal Dependencies

**Scripts**:
- Current setup-platform.sh as reference
- Destroy/cleanup logic patterns

**Configuration**:
- ArgoCD Application manifests
- Ingress configurations
- Service definitions

### Integration with Existing Systems

**CI/CD Pipeline**:
- No changes required to build-push.yml
- GitOps repo update still triggers ArgoCD sync
- Cloud cluster works identically to Kind from CI/CD perspective

**GitOps Repository**:
- Uses same spider-rainbows-platform-config
- May need separate overlay for cloud-specific config (optional)
- LoadBalancer vs NodePort differences

**DNS Management**:
- nip.io provides automatic DNS resolution
- No external DNS services required
- No additional configuration needed

---

## Risks & Mitigation

### Technical Risks

**Risk 1: Cloud Provider API Failures**
- **Impact**: High - Cannot create cluster
- **Likelihood**: Low - Cloud APIs are reliable
- **Mitigation**:
  - Comprehensive error handling
  - Clear error messages with resolution steps
  - Manual fallback instructions documented

**Risk 2: LoadBalancer IP Assignment Delays**
- **Impact**: Medium - Demo not immediately accessible
- **Likelihood**: Low - Usually assigns within 1-2 minutes
- **Mitigation**:
  - Retry logic with backoff
  - Timeout handling (max 10 minutes)
  - Display IP address once assigned
  - Document expected wait times

**Risk 3: Resource Quotas**
- **Impact**: High - Cluster creation fails
- **Likelihood**: Medium - New accounts have low quotas
- **Mitigation**:
  - Document required quotas upfront
  - Clear error messages when quota exceeded
  - Instructions for requesting quota increases
  - Minimal resource sizing to reduce quota needs

**Risk 4: Cost Surprises**
- **Impact**: Medium - Unexpected charges
- **Likelihood**: Medium - Easy to forget running resources
- **Mitigation**:
  - Display estimated cost during setup
  - Reminder at end: "Remember to destroy when done"
  - Log cluster details for tracking
  - Optional: Budget alerts via cloud provider

### Process Risks

**Risk 5: Incomplete Cleanup**
- **Impact**: Medium - Orphaned resources continue costing
- **Likelihood**: Medium - Cloud resources can be tricky
- **Mitigation**:
  - Comprehensive destroy script
  - Tag all resources for easy identification
  - Verification after deletion
  - Document manual cleanup if needed

**Risk 6: Mode Selection Confusion**
- **Impact**: Low - User creates wrong cluster type
- **Likelihood**: Low - Clear prompt provided
- **Mitigation**:
  - Clear interactive prompt with options
  - Confirmation before cluster creation
  - Easy destroy instructions for both modes

---

## Timeline & Phases

### Phase 1: Interactive Mode Selection and Cloud Foundation (Days 1-2)
- Add interactive prompt for user mode selection
- Implement GCP prerequisite checking
- Implement GKE cluster creation/destruction
- Prove out concept with minimal cluster

### Phase 2: Ingress and LoadBalancer Configuration (Days 3-4)
- Add ingress-nginx with LoadBalancer for GCP
- Implement nip.io domain construction
- Get end-to-end flow working (setup → LoadBalancer IP → domain access)
- Handle IP assignment failures and timeouts

### Phase 3: ArgoCD and GitOps Integration (Days 5-6)
- Deploy ArgoCD to cloud cluster
- Configure dynamic ingress with nip.io domains
- Consolidate config into `argocd-config/`
- Verify CI/CD pipeline integration

### Phase 4: Validation and Documentation (Days 7-8)
- Add comprehensive validation for both modes
- Test setup/destroy cycles (Kind and GCP)
- Write mode-specific documentation
- Create troubleshooting guide
- Update README

**Total Estimated Time**: 8 days

---

## Resolved Decisions

### Decision 1: Interactive Mode Selection
**Status**: ✅ Resolved
- **Decision**: Script prompts user at start instead of using `--mode` flag
- **Rationale**: Better UX, clearer user intent, more discoverable
- **Implementation**: Interactive prompt: "Which cluster? (1) Kind (2) GCP?"

### Decision 2: DNS Strategy
**Status**: ✅ Resolved
- **Decision**: Use nip.io instead of GoDaddy API
- **Rationale**: Eliminates external dependencies, reduces setup complexity, immediate availability
- **Implementation**: Construct domains like `spider-rainbows.<IP>.nip.io` from LoadBalancer IP

### Decision 3: Cloud Provider
**Status**: ✅ Resolved
- **Decision**: Start with GKE only (not AKS)
- **Rationale**: Aligns with user's current setup preferences
- **Implementation**: GKE cluster creation via gcloud CLI

### Decision 4: Script Organization
**Status**: ✅ Resolved
- **Decision**: Modify existing `kind/setup-platform.sh` (not create new cloud script)
- **Rationale**: Consolidates deployment logic, reduces duplication, maintains single entry point
- **Implementation**: Add mode selection branch at script start

## Open Questions

1. **Cluster Sizing**: What's the minimal viable configuration for GCP?
   - Single node sufficient?
   - Node size (e.g., 2 CPU / 4GB RAM)?
   - Auto-scaling or fixed size?

2. **Persistent Storage**: Does anything need persistent volumes?
   - ArgoCD state?
   - Application data?
   - Or all stateless?

3. **HTTPS/TLS**: Should setup script also configure cert-manager + Let's Encrypt?
   - Or just HTTP for now?
   - Manual cert setup instructions?

4. **Multiple Environments**: Support for dev/staging/prod in different clusters?
   - Or just single demo cluster?

5. **Future Provider Support**: When should AKS support be added?
   - Post-GKE validation?
   - Or skip for now?

---

## Progress Log

### 2025-10-28: PRD Created
- Initial PRD drafted based on user requirements
- Core milestones defined for cloud deployment
- GoDaddy API integration approach outlined
- Open questions identified for implementation

### 2025-10-31: PRD Updated - Design Decisions Applied
- **Decision 1**: Interactive mode selection (no `--mode` flag)
- **Decision 2**: Use nip.io instead of GoDaddy API for DNS
- **Decision 3**: Focus on GKE (not AKS initially)
- **Decision 4**: Modify existing setup-platform.sh instead of creating new cloud script
- Updated all milestones from 5 to 4 (removed GoDaddy milestone)
- Updated timeline from 12 days to 8 days
- Removed all GoDaddy-specific dependencies and risks
- Updated DNS strategy to use nip.io

### 2025-10-31: Milestone 1 Implementation - 95% Complete (1 Blocker Remaining)

**Status**: In Progress - Awaiting verification of ignoreDifferences solution

**Implementation Time**: ~8 hours

**Completed Features**:
1. ✅ **Interactive Mode Selection** - Script prompts: "Which cluster? (1) Kind (2) GCP?"
   - Location: `kind/setup-platform.sh:60-86`
   - User selects deployment type, script branches accordingly

2. ✅ **GCP Prerequisites with Auto-PATH Fix** - Checks for gcloud, kubectl, gke-gcloud-auth-plugin
   - Location: `kind/setup-platform.sh:147-190`
   - Automatically adds gcloud SDK to PATH if plugin not found
   - Updated `~/.zshrc` with PATH fix

3. ✅ **GKE Cluster Creation** - Creates cluster with user's standard config
   - Location: `kind/setup-platform.sh:276-351`
   - GCP project: `demoo-ooclock`, region: `us-east1`, machine type: `n1-standard-4`, 3 nodes
   - Waits for ALL nodes to become Ready (not just one)

4. ✅ **Dynamic Cluster Naming** - Format: `spider-rainbows-YYYYMMDD-HHMMSS`
   - Location: `kind/setup-platform.sh:19`
   - Prevents name conflicts, starts with letter (GKE requirement)

5. ✅ **LoadBalancer and nip.io DNS** - Waits for external IP, constructs domain
   - Location: `kind/setup-platform.sh:387-417`
   - Example: `35.237.9.195.nip.io`
   - Sets `BASE_DOMAIN` variable used throughout script

6. ✅ **Dynamic ArgoCD Ingress** - Creates ingress with correct domain based on mode
   - Location: `kind/setup-platform.sh:524-557`
   - Kind: `argocd.127.0.0.1.nip.io`
   - GCP: `argocd.<LoadBalancer-IP>.nip.io`

7. ✅ **ArgoCD 5-Second Sync** - Configures fast reconciliation
   - Location: `kind/setup-platform.sh:506-522`
   - Sets `timeout.reconciliation: 5s` in argocd-cm ConfigMap

8. ✅ **Destroy Script Enhancements** - Auto-detects clusters, cleans up kubeconfig
   - Location: `kind/destroy.sh`
   - Detects both Kind and GKE clusters
   - Cleans up kubeconfig to prevent bloat

**Testing Results**:
- ✅ Kind Mode: Works perfectly, full backward compatibility verified
- ⚠️ GCP Mode: Partial success
  - ✅ Cluster creation: Working
  - ✅ LoadBalancer IP assignment: Working
  - ✅ ArgoCD UI accessible: `https://argocd.34.74.53.101.nip.io` (200 OK)
  - ❌ Spider-rainbows app: Returns 404 due to ingress domain conflict

**Remaining Blocker**:
- **Problem**: Spider-rainbows app ingress has wrong domain
  - ArgoCD syncs ingress from external Git repo (`spider-rainbows-platform-config`) with hardcoded `127.0.0.1.nip.io`
  - Script creates ingress with correct domain (`spider-rainbows.<LoadBalancer-IP>.nip.io`)
  - ArgoCD's `selfHeal: true` reverts script's ingress every 5 seconds

- **Attempted Solution**: Added `ignoreDifferences` config to ArgoCD Application
  - Location: `kind/spider-rainbows-app.yaml:22-28`
  - Config tells ArgoCD to ignore ingress `.spec` field
  - Added `RespectIgnoreDifferences: true` to syncOptions
  - **Status**: Implemented but not yet verified working

**Test Clusters Created** (all cleaned up):
1. `spider-rainbows-gitops` - Before name fix
2. `20251031-180201-spider-rainbows` - Invalid (starts with number)
3. `spider-rainbows-20251031-180227` - Valid, tested
4. `spider-rainbows-20251031-181553` - Valid, tested
5. `spider-rainbows-20251031-184716` - Valid, tested
6. `spider-rainbows-20251031-190337` - Valid, tested (ArgoCD worked, app didn't)
7. `spider-rainbows-20251031-195105` - Valid, deleted

**Files Modified**:
- `kind/setup-platform.sh` - Major additions for GCP support
- `kind/destroy.sh` - Enhanced with auto-detection and cleanup
- `kind/spider-rainbows-app.yaml` - Added ignoreDifferences config
- `kind/cluster-config.yaml` - Removed hardcoded cluster name
- `~/.zshrc` - Added gcloud SDK to PATH

**Documentation Created**:
- `MILESTONE-1-STATUS.md` - Comprehensive status document with:
  - Complete implementation history
  - 3 current problems with root causes
  - 5 possible solutions with pros/cons analysis
  - Test cluster history
  - Clear next steps for verification
  - Architecture decisions made
  - Key learnings

**Next Steps**:
1. Deploy fresh GCP cluster to verify ignoreDifferences solution
2. Observe ArgoCD behavior for 10+ seconds to confirm ingress persists
3. Test app accessibility: `curl http://spider-rainbows.<IP>.nip.io/health`
4. If successful, re-test Kind mode for backward compatibility
5. Mark Milestone 1 complete once both modes verified working

**Note**: Milestone 1 is NOT marked complete per explicit user instruction: "do NOT mark milestone 1 as complete. Not until the final script is proven to work with both kind and GCP"

---

## Success Metrics

### Technical Metrics
- Setup script success rate: >95%
- Setup completion time: <15 minutes
- DNS propagation time: <5 minutes average
- Destroy completion time: <3 minutes
- Zero manual cloud console steps required

### User Experience Metrics
- spiders.whitneylee.com accessible 24/7
- CI/CD deploys work without manual intervention
- Portfolio integration successful
- Professional branding achieved

### Documentation Metrics
- Setup instructions followed successfully by test user
- Troubleshooting guide covers all common issues
- Prerequisites clearly documented
