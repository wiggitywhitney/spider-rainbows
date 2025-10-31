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

Create cloud-based deployment scripts that provision a fully-managed Kubernetes cluster (GKE or AKS) with the complete spider-rainbows GitOps demo environment. Automatically configure DNS via GoDaddy API to expose the demo at **spiders.whitneylee.com**.

**Key Features**:
1. Setup script creates cloud Kubernetes cluster
2. Deploys full stack: spider-rainbows app, ArgoCD, ingress-nginx
3. Configures LoadBalancer with public IP
4. Automatically updates GoDaddy DNS to point spiders.whitneylee.com to cluster
5. Destroy script tears down all resources
6. Mirrors current Kind setup workflow

**Architecture**:
```
[Cloud Kubernetes Cluster (GKE/AKS)]
  ├─ Ingress-nginx (LoadBalancer with public IP)
  ├─ ArgoCD (GitOps management)
  ├─ Spider-rainbows app (2 replicas)
  └─ Public IP: X.X.X.X

[GoDaddy DNS]
  spiders.whitneylee.com → A record → X.X.X.X

[GitHub Actions CI/CD]
  Build → Push → Update GitOps repo → ArgoCD syncs
```

---

## Goals & Success Criteria

### Primary Goals
- [ ] Stable URL at spiders.whitneylee.com accessible 24/7
- [ ] Setup script creates complete cloud environment in <15 minutes
- [ ] Automatic GoDaddy DNS configuration
- [ ] Full GitOps workflow with ArgoCD (same as Kind)
- [ ] Destroy script cleanly removes all resources
- [ ] Cost-efficient resource sizing for demo workloads

### Success Metrics
- [ ] spiders.whitneylee.com resolves and loads app within 5 minutes of setup
- [ ] CI/CD pipeline successfully deploys to cloud cluster
- [ ] ArgoCD syncs and manages deployments automatically
- [ ] Setup/destroy scripts are idempotent and reliable
- [ ] DNS updates propagate within 2 minutes

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

### Cloud Provider Support

**Flexible Implementation**: Support both GKE and AKS via:
- Separate scripts: `setup-gke.sh` and `setup-aks.sh`
- OR unified script with provider flag: `--provider=gke|aks`
- Implementation details determined during development

**Provider-Specific Considerations**:

**GKE (Google Cloud)**:
- CLI: `gcloud` container clusters create
- Authentication: `gcloud auth login`
- LoadBalancer: Automatically provisions external IP
- Cost: ~$0.10/hour for e2-medium nodes

**AKS (Azure)**:
- CLI: `az aks create`
- Authentication: `az login`
- LoadBalancer: Automatically provisions public IP
- Cost: ~$0.096/hour for Standard_B2s nodes

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
- GoDaddy API integration
- A record: spiders.whitneylee.com → LoadBalancer IP
- TTL: 600 seconds (10 minutes) for faster propagation
- Optional: Wildcard *.spiders.whitneylee.com

### Implementation Details

**Setup Script Flow**:
```bash
1. Check prerequisites (cloud CLI, kubectl, GoDaddy API key)
2. Create cloud Kubernetes cluster
3. Configure kubectl context
4. Install ingress-nginx (LoadBalancer type)
5. Wait for LoadBalancer IP assignment
6. Install ArgoCD
7. Configure ArgoCD Application for spider-rainbows
8. Update GoDaddy DNS via API
9. Wait for DNS propagation
10. Validate access at spiders.whitneylee.com
11. Display success message with URLs
```

**Destroy Script Flow**:
```bash
1. Confirm deletion (prevent accidents)
2. Delete cloud cluster (removes all resources)
3. Optional: Remove GoDaddy DNS record
4. Display confirmation
```

**GoDaddy API Integration**:
```bash
# Requires environment variables:
GODADDY_API_KEY=...
GODADDY_API_SECRET=...

# Update A record
curl -X PUT "https://api.godaddy.com/v1/domains/whitneylee.com/records/A/spiders" \
  -H "Authorization: sso-key $GODADDY_API_KEY:$GODADDY_API_SECRET" \
  -H "Content-Type: application/json" \
  -d '[{"data":"<LOADBALANCER_IP>","ttl":600}]'
```

### Technical Considerations

**DNS Propagation**:
- Initial setup: 2-10 minutes typical
- Updates: Faster with 600s TTL
- Validation retries with exponential backoff

**Cloud Provider Quotas**:
- Document required quotas (IPs, CPUs, LoadBalancers)
- Handle quota exceeded errors gracefully
- Provide clear error messages

**Authentication**:
- Require cloud CLI authentication before running
- GoDaddy API keys via environment variables
- Document credential setup clearly

**Idempotency**:
- Setup script checks if cluster exists
- Graceful handling of partial failures
- Resume/retry capability for interrupted setups

---

## Implementation Milestones

### Milestone 1: Cloud Provider Script Foundation
**Goal**: Basic cluster creation and destruction working for at least one provider

**Tasks**:
- Choose initial provider (GKE or AKS) for MVP
- Implement prerequisite checking (CLI tools, auth)
- Create cluster provisioning logic
- Implement cluster deletion
- Add basic error handling and logging

**Success Criteria**:
- Script successfully creates minimal cloud cluster
- Cluster accessible via kubectl
- Destroy script cleanly removes all resources
- No manual cloud console interaction needed

---

### Milestone 2: Ingress and LoadBalancer Configuration
**Goal**: Public IP exposed and accessible via HTTP

**Tasks**:
- Install nginx-ingress-controller
- Configure LoadBalancer service
- Wait for and capture external IP
- Validate IP is accessible via HTTP
- Handle IP assignment failures/timeouts

**Success Criteria**:
- LoadBalancer service gets public IP
- Can curl the IP and get nginx response
- Script displays assigned IP clearly
- Timeout handling for slow provisioning

---

### Milestone 3: GoDaddy DNS Automation
**Goal**: Automatic DNS configuration via API

**Tasks**:
- Implement GoDaddy API client
- Create/update A record for spiders subdomain
- Add DNS propagation validation
- Handle API errors (auth, rate limits, etc.)
- Document API key setup process

**Success Criteria**:
- Script successfully updates GoDaddy DNS
- spiders.whitneylee.com resolves to cluster IP
- Propagation validation works reliably
- Clear error messages for API failures

---

### Milestone 4: ArgoCD and GitOps Integration
**Goal**: Full GitOps workflow operational in cloud

**Tasks**:
- Install ArgoCD via manifests
- Configure Application CR for spider-rainbows
- Connect to spider-rainbows-platform-config repo
- Verify auto-sync functionality
- Configure ArgoCD ingress (optional)

**Success Criteria**:
- ArgoCD successfully deployed
- Spider-rainbows app syncs and deploys
- GitOps workflow functional (push to repo → auto-deploy)
- App accessible at spiders.whitneylee.com
- Same functionality as Kind setup

---

### Milestone 5: Validation and Documentation
**Goal**: Complete, tested, documented solution

**Tasks**:
- Add comprehensive validation checks
- Test complete setup/destroy cycle multiple times
- Document prerequisites and setup steps
- Add troubleshooting guide
- Create example walkthrough
- Test DNS updates and propagation
- Verify CI/CD pipeline integration

**Success Criteria**:
- Setup script completes end-to-end successfully
- All validation checks pass
- Documentation enables reproduction by others
- Common issues documented with solutions
- README updated with cloud deployment option

---

## Dependencies & Integration Points

### External Dependencies

**Cloud Provider (GKE or AKS)**:
- Account with billing enabled
- CLI tools installed (gcloud or az)
- Sufficient quotas for resources
- Authentication configured

**GoDaddy Domain & API**:
- Active whitneylee.com domain
- API key and secret
- API access enabled for domain
- DNS management permissions

**Existing Infrastructure**:
- GitHub Actions CI/CD pipeline
- spider-rainbows-platform-config GitOps repository
- Docker Hub for images

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
- GoDaddy API becomes critical dependency
- Existing DNS records unaffected (spiders is new subdomain)

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

**Risk 2: DNS Propagation Delays**
- **Impact**: Medium - Demo not immediately accessible
- **Likelihood**: Medium - DNS can take 5-30 minutes
- **Mitigation**:
  - Low TTL values (600s)
  - Retry logic with backoff
  - Display IP address as fallback during propagation
  - Document expected wait times

**Risk 3: GoDaddy API Issues**
- **Impact**: High - Breaks automated DNS setup
- **Likelihood**: Low - API is stable
- **Mitigation**:
  - API authentication validation early
  - Detailed error messages for API failures
  - Manual DNS update instructions as fallback
  - Document API key setup thoroughly

**Risk 4: Resource Quotas**
- **Impact**: High - Cluster creation fails
- **Likelihood**: Medium - New accounts have low quotas
- **Mitigation**:
  - Document required quotas upfront
  - Clear error messages when quota exceeded
  - Instructions for requesting quota increases
  - Minimal resource sizing to reduce quota needs

**Risk 5: Cost Surprises**
- **Impact**: Medium - Unexpected charges
- **Likelihood**: Medium - Easy to forget running resources
- **Mitigation**:
  - Display estimated cost during setup
  - Reminder at end: "Remember to destroy when done"
  - Log cluster details for tracking
  - Optional: Budget alerts via cloud provider

### Process Risks

**Risk 6: Incomplete Cleanup**
- **Impact**: Medium - Orphaned resources continue costing
- **Likelihood**: Medium - Cloud resources can be tricky
- **Mitigation**:
  - Comprehensive destroy script
  - Tag all resources for easy identification
  - Verification after deletion
  - Document manual cleanup if needed

---

## Timeline & Phases

### Phase 1: Foundation (Days 1-3)
- Choose initial cloud provider (GKE or AKS)
- Implement basic cluster creation/destruction
- Set up authentication and prerequisites
- Prove out concept with minimal cluster

### Phase 2: Core Features (Days 4-6)
- Add ingress-nginx and LoadBalancer
- Implement GoDaddy DNS integration
- Get end-to-end flow working (setup → DNS → access)
- Handle common failure scenarios

### Phase 3: GitOps Integration (Days 7-9)
- Deploy ArgoCD to cloud cluster
- Connect GitOps repository
- Verify CI/CD pipeline integration
- Test complete workflow

### Phase 4: Polish & Documentation (Days 10-12)
- Add comprehensive validation
- Test setup/destroy cycles
- Write documentation
- Create troubleshooting guide
- Consider adding second provider support

**Total Estimated Time**: 12 days

---

## Open Questions

1. **Provider Priority**: Should we implement GKE first, AKS first, or both simultaneously?

2. **DNS Subdomain Structure**:
   - Just spiders.whitneylee.com for the app?
   - Also argocd.spiders.whitneylee.com?
   - Wildcard *.spiders.whitneylee.com?

3. **Cluster Sizing**: What's the minimal viable configuration?
   - Single node sufficient?
   - Node size (2 CPU / 4GB RAM)?
   - Auto-scaling or fixed size?

4. **Persistent Storage**: Does anything need persistent volumes?
   - ArgoCD state?
   - Application data?
   - Or all stateless?

5. **HTTPS/TLS**: Should setup script also configure cert-manager + Let's Encrypt?
   - Or just HTTP for now?
   - Manual cert setup instructions?

6. **Multiple Environments**: Support for dev/staging/prod in different clusters?
   - Or just single demo cluster?

7. **Monitoring**: Should we add basic monitoring/logging?
   - Or keep it simple?

---

## Progress Log

### 2025-10-28: PRD Created
- Initial PRD drafted based on user requirements
- Core milestones defined for cloud deployment
- GoDaddy API integration approach outlined
- Open questions identified for implementation

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
