# PRD: Enable External Access via LoadBalancer

**Status**: Draft
**Created**: 2025-10-28
**GitHub Issue**: [#9](https://github.com/wiggitywhitney/spider-rainbows/issues/9)
**Priority**: High

---

## Related Resources

- [Cloud Provider KIND Documentation](https://github.com/kubernetes-sigs/cloud-provider-kind)
- [Kind LoadBalancer Guide](https://kind.sigs.k8s.io/docs/user/loadbalancer)
- [Current setup-platform.sh](../kind/setup-platform.sh)
- [Current README](../README.md)

---

## Problem Statement

The spider-rainbows demo application is currently only accessible via localhost (127.0.0.1.nip.io), preventing demo audience members from accessing the app on their personal devices (phones, laptops) during presentations. This limits the interactive nature of demos and prevents real-world testing scenarios where up to 500 people need simultaneous access.

**Current State**:
- App accessible only at `http://spider-rainbows.127.0.0.1.nip.io`
- Ingress-nginx service uses NodePort with host port mapping
- No external network access available
- Demo presenters cannot share app with audience on same WiFi

**User Impact**:
- Demo presenters cannot provide hands-on experience to audience
- Testing scenarios limited to single presenter's machine
- Reduced engagement during presentations
- No ability to demonstrate real-world mobile access patterns

---

## Solution Overview

Integrate **Cloud Provider KIND** into the setup-platform.sh script to enable Kubernetes LoadBalancer services in the Kind cluster. Convert the ingress-nginx service from NodePort to LoadBalancer type, providing an externally accessible IP address on the local network.

**Key Changes**:
1. Install Cloud Provider KIND binary during platform setup
2. Start Cloud Provider KIND alongside the cluster
3. Convert ingress-nginx service to LoadBalancer type
4. Update ingress hostnames to use actual machine IP with nip.io
5. Validate external access and display accessible URLs
6. Document the new workflow in README

---

## Goals & Success Criteria

### Primary Goals
- [ ] External users on same WiFi network can access spider-rainbows app
- [ ] Setup script handles all Cloud Provider KIND installation and configuration
- [ ] LoadBalancer IP automatically assigned to ingress-nginx service
- [ ] Support up to 500 concurrent users during demos

### Success Metrics
- [ ] LoadBalancer service successfully provisions external IP
- [ ] App accessible from external device on same network
- [ ] Setup script completes with full validation passing
- [ ] README reflects updated workflow

### Non-Goals
- Internet-wide access (outside local network)
- HTTPS/TLS certificate management for external access
- Support for multiple simultaneous Kind clusters with LoadBalancers
- Production-grade load balancing or high availability

---

## User Stories & Use Cases

### Primary User Story
**As a** demo presenter
**I want** the spider-rainbows app to be accessible on attendees' personal devices
**So that** I can provide interactive hands-on demonstrations with up to 500 participants

**Acceptance Criteria**:
- Start with clean machine (no existing cluster)
- Run `./kind/setup-platform.sh`
- Receive externally accessible URL at end of setup
- Share URL with demo audience
- Audience members can immediately access app on their devices

### Use Case 1: Conference Demo
**Context**: Presenting at a tech conference with 200 attendees
**Flow**:
1. Presenter runs setup script on laptop connected to venue WiFi
2. Script completes, displays: `External URL: http://spider-rainbows.192.168.1.50.nip.io`
3. Presenter shares URL via slides/QR code
4. Attendees type URL into phones and see live app
5. Presenter demonstrates feature changes and live CI/CD deployments

### Use Case 2: Team Training Session
**Context**: Internal workshop with 20 team members
**Flow**:
1. Trainer sets up demo environment on laptop
2. Team members join same WiFi network
3. Each team member accesses app and performs exercises
4. Everyone sees real-time updates as trainer makes changes

---

## Technical Approach

### Architecture Changes

**Current Architecture**:
```
[Host Machine]
  └─ [Kind Cluster]
      └─ [ingress-nginx Service: NodePort]
          └─ Maps to host ports 80/443 via extraPortMappings
      └─ [spider-rainbows pods]
      └─ [spider-rainbows ingress: 127.0.0.1.nip.io]
```

**New Architecture**:
```
[Host Machine]
  ├─ [Cloud Provider KIND binary running]
  └─ [Kind Cluster]
      └─ [ingress-nginx Service: LoadBalancer]
          └─ External IP: 192.168.1.X (local network)
      └─ [spider-rainbows pods]
      └─ [spider-rainbows ingress: 192.168.1.X.nip.io]
```

### Implementation Details

**1. Cloud Provider KIND Installation**
- Install binary from GitHub releases or via Go
- Requires privileges for port management and container runtime access
- Runs as standalone process on host system

**2. Service Conversion**
- Change ingress-nginx service type from NodePort to LoadBalancer
- Remove NodePort patches (lines 186-188 in setup-platform.sh)
- Cloud Provider KIND will assign external IP automatically

**3. Hostname Updates**
- Detect host machine's local network IP (e.g., 192.168.1.50)
- Update spider-rainbows ingress to use: `spider-rainbows.192.168.1.50.nip.io`
- Update argocd ingress similarly: `argocd.192.168.1.50.nip.io`
- Maintain nip.io for automatic DNS resolution

**4. Validation Enhancements**
- Verify LoadBalancer IP assignment
- Test external access from LoadBalancer IP
- Display both localhost and external URLs in final output

### Technical Considerations

**Network Requirements**:
- Host and client devices must be on same WiFi network
- Network must allow traffic between devices (no AP isolation)
- LoadBalancer IP will be from host's network subnet

**Cloud Provider KIND Lifecycle**:
- Must start after cluster creation
- Should run for cluster lifetime
- Should be stopped when cluster is deleted

**Compatibility**:
- Works with existing ArgoCD and GitOps setup
- Compatible with current ingress-nginx configuration
- No changes needed to application deployments

---

## Implementation Milestones

### Milestone 1: Cloud Provider KIND Integration
**Goal**: Cloud Provider KIND installed and running with the cluster

**Tasks**:
- Add Cloud Provider KIND installation to setup-platform.sh
- Detect OS/architecture and download appropriate binary
- Start Cloud Provider KIND process after cluster creation
- Verify Cloud Provider KIND is running and healthy

**Success Criteria**:
- `cloud-provider-kind` binary installed in PATH or local bin directory
- Process running and connected to Kind cluster
- No errors in Cloud Provider KIND logs

---

### Milestone 2: LoadBalancer Service Configuration
**Goal**: Ingress-nginx service converted to LoadBalancer with external IP

**Tasks**:
- Modify setup script to use LoadBalancer service type
- Remove NodePort-specific patches
- Wait for LoadBalancer external IP assignment
- Verify external IP is accessible from host machine

**Success Criteria**:
- `kubectl get svc -n ingress-nginx` shows EXTERNAL-IP assigned
- External IP is pingable from host machine
- HTTP traffic reaches ingress-nginx via external IP

---

### Milestone 3: Dynamic Hostname Configuration
**Goal**: Ingresses updated with actual network-accessible hostnames

**Tasks**:
- Detect host machine's local network IP address
- Update spider-rainbows ingress with `<IP>.nip.io` hostname
- Update argocd ingress with `<IP>.nip.io` hostname
- Apply updated ingress configurations

**Success Criteria**:
- Ingresses use real network IP in hostnames
- nip.io DNS resolution works for new hostnames
- Both apps accessible via new URLs

---

### Milestone 4: Enhanced Validation & Testing
**Goal**: Comprehensive validation confirms external access works

**Tasks**:
- Add LoadBalancer IP validation to health checks
- Test external access via LoadBalancer IP
- Verify app functionality through external URL
- Display external URLs prominently in setup output

**Success Criteria**:
- All existing validation checks still pass
- New validation confirms external access
- Setup script displays both localhost and external URLs
- External URLs are copy-paste ready for sharing

---

### Milestone 5: Documentation Complete
**Goal**: README updated with external access workflow

**Tasks**:
- Document Cloud Provider KIND as prerequisite
- Update setup instructions with external access details
- Add troubleshooting section for network access issues
- Include example URLs and usage scenarios
- Document how to find external URLs after setup

**Success Criteria**:
- README clearly describes external access feature
- Instructions tested by following docs exactly
- Common issues documented with solutions
- Users can successfully reproduce setup

---

## Dependencies & Integration Points

### External Dependencies
- **Cloud Provider KIND**: Core dependency for LoadBalancer support
  - Source: https://github.com/kubernetes-sigs/cloud-provider-kind
  - Requires: Host privileges, Docker access
  - Version: Latest stable release

### Internal Dependencies
- **setup-platform.sh**: Primary integration point
- **ingress-nginx**: Service type change required
- **ArgoCD ingress**: Hostname update needed
- **spider-rainbows ingress**: Hostname update needed

### Integration with Existing Systems
- **ArgoCD GitOps**: No changes to sync process
- **CI/CD Pipeline**: No changes to build/deploy workflow
- **Application Code**: No changes required
- **Existing Ingress Controller**: Configuration changes only

---

## Risks & Mitigation

### Technical Risks

**Risk 1: Cloud Provider KIND Installation Complexity**
- **Impact**: High - Feature won't work without it
- **Likelihood**: Medium - Requires binary installation and privileges
- **Mitigation**:
  - Provide clear error messages if installation fails
  - Document manual installation as fallback
  - Test on multiple OS/architecture combinations

**Risk 2: Network Compatibility Issues**
- **Impact**: High - Users can't access app if network blocks traffic
- **Likelihood**: Medium - Some WiFi networks have AP isolation
- **Mitigation**:
  - Document network requirements upfront
  - Provide troubleshooting steps for network issues
  - Add validation that tests actual external connectivity

**Risk 3: Port Conflicts**
- **Impact**: Medium - LoadBalancer may conflict with existing services
- **Likelihood**: Low - Most local networks don't have port 80/443 conflicts
- **Mitigation**:
  - Check port availability before starting Cloud Provider KIND
  - Document port requirements clearly
  - Provide alternative port configuration if needed

### Process Risks

**Risk 4: Breaking Existing Localhost Access**
- **Impact**: Medium - Could break current workflow
- **Likelihood**: Low - Changes are additive
- **Mitigation**:
  - Maintain localhost access alongside external access
  - Test both access methods in validation
  - Keep NodePort configuration as optional fallback

---

## Timeline & Phases

### Phase 1: Foundation (Days 1-2)
- Research Cloud Provider KIND installation methods
- Design integration approach for setup script
- Create proof-of-concept with manual installation

### Phase 2: Implementation (Days 3-4)
- Implement Cloud Provider KIND installation in script
- Convert service types and update configurations
- Add hostname detection and dynamic configuration

### Phase 3: Validation & Testing (Day 5)
- Add comprehensive validation checks
- Test on multiple machines and network setups
- Verify external access with actual devices

### Phase 4: Documentation (Day 6)
- Update README with complete workflow
- Document troubleshooting steps
- Create examples and usage scenarios

**Total Estimated Time**: 6 days

---

## Open Questions

1. **Installation Method**: Should Cloud Provider KIND be installed via:
   - Go install (requires Go on host)?
   - Download pre-built binary from releases?
   - Both with fallback logic?

2. **Binary Location**: Where should cloud-provider-kind binary be stored?
   - System PATH (/usr/local/bin)?
   - Local project directory (./bin)?
   - User's home directory (~/.local/bin)?

3. **Process Management**: How should Cloud Provider KIND process be managed?
   - Background process started by setup script?
   - Terminal window that must stay open?
   - systemd/launchd service for automatic management?

4. **Cluster Cleanup**: How should Cloud Provider KIND be stopped when cluster is deleted?
   - Add to cluster deletion script?
   - Document manual process?
   - Automatic detection and cleanup?

5. **Multiple Network Interfaces**: If host has multiple IPs (VPN, multiple NICs), which should be used?
   - Auto-detect primary interface?
   - Allow user to specify?
   - Use all IPs with multiple ingress rules?

---

## Progress Log

### 2025-10-28: PRD Created
- Initial PRD drafted based on user requirements
- Core milestones and approach defined
- Open questions identified for implementation decisions
