# PRD: V3 Branch Feature - Final Spider Reveal + Interactive Links + MCP Demo Setup

**Status**: Draft
**Created**: 2025-10-31
**GitHub Issue**: [#15](https://github.com/wiggitywhitney/spider-rainbows/issues/15)
**Priority**: High

---

## Related Resources

- [SpiderImage.jsx](../src/components/SpiderImage.jsx)
- [SurpriseSpider.jsx](../src/components/SurpriseSpider.jsx)
- [App.jsx](../src/App.jsx)
- [MCP Server PRD](#PRD-16)
- [V2 PRD](#PRD-14)

---

## Problem Statement

Part 4 of the conference demo introduces platform-provided MCP tools and slash commands. This requires:

1. **V3 Spider Images**: Final reveal with anatomically accurate fangs - on a separate branch
2. **Interactive Links**: Clicking on spiders links to presenter's website or Viktor's website
3. **Intentional K8s Failure**: Deployment fails initially (taint/toleration issue), then MCP server remediates
4. **Branch Strategy**: Merge during demo, revert after (for demo repeatability)

**Current State**:
- V2 works on main with cheesy grins
- V3 images need to be drawn
- No interactive link functionality
- No K8s failure scenario for MCP demo

**Demo Impact**:
- Cannot show final spider reveal and website links
- Cannot demonstrate MCP server troubleshooting workflow
- Cannot provide complete platform demo story

---

## Solution Overview

Create a v3 feature branch that includes:

**1. V3 Spider Images** (new drawing):
- Anatomically accurate spider fangs/mouth parts
- Both single spider and swarm variants
- Visual progression: cute (v1) → silly (v2) → creepy/accurate (v3)

**2. Interactive Spider UI**:
- Clickable spiders that open links
- Link to Viktor's website (or bio page)
- Link to presenter's website
- Smooth interactions that don't interfere with normal demo

**3. Intentional K8s Failure Setup**:
- V3 deployment configuration with no toleration
- Cluster node tainted (setup script or documentation)
- Deployment fails initially - MCP server will diagnose

**4. Part 4 Demo Orchestration**:
- Branch ready to merge via `/prd-done` command
- Demonstrates platform-provided slash commands
- Triggers CI/CD build and deployment
- Deployment fails (taint issue)
- MCP server diagnoses and fixes the issue
- App finally deploys with v3 visible to audience

---

## Goals & Success Criteria

### Primary Goals
- [ ] V3 spider images drawn with anatomically accurate fangs
- [ ] Interactive link functionality working smoothly
- [ ] Branch configured for Part 4 demo workflow
- [ ] K8s failure scenario functional and reproducible
- [ ] MCP server integration points clear
- [ ] Branch can be merged and reverted safely

### Success Metrics
- [ ] V3 images visually distinct and "creepy" compared to v2
- [ ] Clicking spiders opens links without breaking app
- [ ] `/prd-done` merges branch cleanly
- [ ] Deployment initially fails with taint error
- [ ] MCP server identifies taint issue
- [ ] Remediation command fixes issue
- [ ] App deploys successfully with v3
- [ ] Branch can be reverted after demo

### Non-Goals
- Changing the spider add/remove functionality
- Complex interactions or animations
- Permanent link functionality (only for demo period)
- Multi-page experience
- Modifying other demo components

---

## User Stories & Use Cases

### Primary User Story
**As a** conference presenter
**I want** a dramatic v3 reveal with MCP server troubleshooting
**So that** I can show the complete platform-engineer-AI-assistant workflow

**Acceptance Criteria**:
- V3 branch contains all code and image changes
- `/prd-done` seamlessly merges and triggers deployment
- Deployment fails initially (taint/toleration)
- MCP server diagnoses and fixes the issue
- V3 spider reveal happens live on audience devices
- Branch reverts cleanly after demo

### Use Case 1: Part 4 Demo - Complete Platform Workflow
**Context**: Part 4 demo showing platform-provided tools
**Flow**:
1. Presenter on v3 branch with PRD completion status
2. Show audience the MCP-enabled PRD commands: `/prd-start`, `/prd-next`, `/prd-done`
3. Run `/prd-done` to trigger merge, build, push, ArgoCD sync
4. Deployment starts but fails (taint issue visible in kubectl)
5. Presenter uses MCP server to diagnose: "Why isn't the deployment working?"
6. MCP shows taint error on nodes
7. MCP generates remediation command
8. Apply fix, deployment succeeds
9. Audience refreshes app, sees v3 spider with fangs
10. Final moment: Show interactive links by clicking spiders

### Use Case 2: Post-Conference Revert
**Context**: After demo, clean up branch for next use
**Flow**:
1. Demo complete, v3 branch merged to main
2. Run `git revert HEAD` or similar to undo merge
3. Main returns to v2 state
4. Next time someone wants to do the demo, v3 branch is still available
5. Can remerge for future presentations

---

## Technical Approach

### Architecture Components

**1. V3 Spider Images**
- File: `public/Spider-v3.png` (532 x 284 px, PNG with transparency)
- File: `public/spidersspidersspiders-v3.png` (2400 x 1600 px, PNG with transparency)
- Visual: Anatomically accurate spider fangs, creepy/realistic
- Created by: Presenter (or commissioned designer)

**2. Interactive Link Component**
- Wrap existing spiders in clickable containers
- Add href attributes for web links
- Open links in new tabs (don't interrupt demo)
- No new component needed - just wrapping existing SpiderImage/SurpriseSpider
- Links:
  - Single spider: → Viktor's website/bio
  - Swarm: → Presenter's website

**3. V3 Code Integration**
- Update SpiderImage.jsx: Use Spider-v3.png instead of Spider.png
- Update SurpriseSpider.jsx: Use spidersspidersspiders-v3.png instead of spidersspidersspiders.png
- Add comments explaining v3 anatomy progression
- Add optional link handling in component

**4. K8s Failure Setup**
- Add taint to cluster nodes: `kubectl taint nodes <node> demo-issue=true:NoSchedule`
- V3 deployment pod spec has NO toleration for the taint
- Pod fails to schedule - visible in `kubectl get pods`
- MCP server diagnosis: "Pod cannot be scheduled due to taint"
- Remediation: Add toleration OR remove taint

**5. Part 4 Orchestration**
- Branch is ready to merge
- PRD status shows "Completed but not merged"
- `/prd-done` command merges and triggers CI/CD
- GitHub Actions builds and pushes new image
- ArgoCD attempts sync
- Deployment fails (by design)
- MCP server troubleshoots and fixes

### Implementation Details

**SpiderImage.jsx with V3**:
```javascript
// Near the top, conditionally import or reference v3
const spiderImagePath = process.env.REACT_APP_SPIDER_VERSION === 'v3'
  ? '/Spider-v3.png'
  : '/Spider.png';

// In JSX, wrap in link if v3
{isV3 && <a href="https://viktor.site.com" target="_blank" rel="noopener noreferrer">
  <img src={spiderImagePath} alt="spider" />
</a>}
```

**Or simpler - just swap the file**:
- Replace `public/Spider.png` with v3 content
- Update component comments
- No component logic changes

**Taint Configuration**:
```bash
# Before demo, apply taint to one node
kubectl taint nodes <node-name> demo-issue=true:NoSchedule

# In v3 pod spec, NO toleration (intentionally fails)
# After MCP remediation, either:
# 1. Remove taint: kubectl taint nodes <node-name> demo-issue:NoSchedule-
# 2. Add toleration to deployment
```

---

## Success Criteria

### Image Requirements
- [ ] V3 spider images drawn with anatomically accurate fangs
- [ ] Images maintain same dimensions as v1/v2 (532x284, 2400x1600)
- [ ] PNG transparency preserved for rainbow overlay
- [ ] Images visually distinct and "creepy" compared to v2

### Functionality Requirements
- [ ] App still works perfectly with v3 images
- [ ] Spider add/remove functionality unchanged
- [ ] Rainbow opacity transitions work
- [ ] Interactive links work without breaking interaction flow

### K8s Failure Setup Requirements
- [ ] Taint applied to cluster before demo
- [ ] V3 pods fail to schedule initially
- [ ] Failure is visible via kubectl and ArgoCD UI
- [ ] Error message is clear: "taint mismatch" or similar

### MCP Demo Requirements
- [ ] MCP server correctly diagnoses taint issue
- [ ] MCP generates remediation command
- [ ] Remediation command successfully fixes deployment
- [ ] Process takes <5 minutes and feels natural

### Demo Workflow Requirements
- [ ] `/prd-done` merges branch cleanly
- [ ] CI/CD builds and pushes new image
- [ ] ArgoCD attempts sync
- [ ] Failure is visible to audience
- [ ] MCP tools integrate smoothly
- [ ] Final deployment shows v3 on audience devices
- [ ] Interactive links function as expected

### Git Requirements
- [ ] Branch can be created and stayed on safely
- [ ] Branch can be merged to main without conflicts
- [ ] Merge can be reverted cleanly after demo
- [ ] Main remains in working state before and after revert

---

## Milestones

### Milestone 1: V3 Spider Images Designed and Created
**Goal**: V3 images ready with anatomical fangs

**Tasks**:
- [ ] Design v3 spider concept (anatomically accurate fangs)
- [ ] Create v3 single spider image (532x284, PNG)
- [ ] Create v3 swarm image (2400x1600, PNG)
- [ ] Verify image dimensions and transparency
- [ ] Get approval on final designs

**Success Criteria**: All v3 images exist, look good, ready for code integration

---

### Milestone 2: Code Integration and Comments
**Goal**: V3 code in place with educational comments

**Tasks**:
- [ ] Update SpiderImage.jsx to use v3 images
- [ ] Update SurpriseSpider.jsx to use v3 images
- [ ] Add v3 comments explaining anatomical progression
- [ ] Add link references to images (for Part 4)
- [ ] Test locally with `npm run dev`

**Success Criteria**: V3 images display correctly, comments explain anatomy, app works perfectly

---

### Milestone 3: Interactive Link Functionality
**Goal**: Clicking spiders opens links without breaking interaction

**Tasks**:
- [ ] Make spiders clickable (wrap in `<a>` tags)
- [ ] Add links to Viktor's website and presenter's site
- [ ] Ensure clicks open in new tabs
- [ ] Verify click handling doesn't interfere with demo
- [ ] Test on multiple devices and browsers

**Success Criteria**: Links work smoothly, don't disrupt spider add/remove functionality

---

### Milestone 4: K8s Failure Scenario Setup
**Goal**: Intentional deployment failure ready for MCP demo

**Tasks**:
- [ ] Document taint configuration for cluster
- [ ] Verify v3 pods fail to schedule with taint
- [ ] Verify error messages are clear
- [ ] Create MCP server remediation command reference
- [ ] Test complete failure → diagnosis → fix workflow

**Success Criteria**: Taint setup reproducible, failure is clear, remediation steps documented

---

### Milestone 5: Branch Creation and Preparation
**Goal**: V3 branch ready for Part 4 demo merge

**Tasks**:
- [ ] Create feature branch: `feature/prd-15-v3-branch`
- [ ] Commit all v3 changes
- [ ] Create draft PR showing all changes
- [ ] Verify CI/CD passes
- [ ] Test in local Kind cluster with all components
- [ ] Mark PRD as "Complete but not merged"

**Success Criteria**: Branch is production-ready, PR shows all changes clearly, PRD status correct

---

### Milestone 6: Demo Workflow Rehearsal
**Goal**: Part 4 demo flow smooth and well-practiced

**Tasks**:
- [ ] Set up cluster with taint in place
- [ ] Merge v3 branch and trigger CI/CD
- [ ] Watch deployment fail
- [ ] Use MCP server to diagnose
- [ ] Apply remediation
- [ ] Verify v3 deploys successfully
- [ ] Test interactive links
- [ ] Practice talking points and timing
- [ ] Revert merge and return main to clean state

**Success Criteria**:
- Complete workflow takes <10 minutes
- Presenter confident in all steps
- MCP server diagnosis feels natural
- Audience will understand the platform value
- Branch revert is smooth

---

### Milestone 7: Post-Demo Cleanup
**Goal**: Repository and cluster ready for next demo cycle

**Tasks**:
- [ ] Document revert procedure
- [ ] Practice full revert workflow
- [ ] Remove taint from cluster (restore to clean state)
- [ ] Verify main branch is stable
- [ ] Document any tweaks needed for next cycle

**Success Criteria**:
- Repository in clean state
- Branch is ready for future reuse
- Cluster is back to normal
- Lessons learned documented

---

## Technical Considerations

### Link Strategy
- **Option 1**: Update app code to include links in components
- **Option 2**: Use CSS to make spiders clickable (overlay technique)
- **Option 3**: Add link layer in React component

Recommendation: Option 1 - Simple JSX wrapping, minimal code change

### K8s Failure Types to Consider
- **Taint/Toleration**: Pod can't be scheduled
- **Resource Limits**: Pod can't fit on node
- **Image Pull Error**: Image can't be pulled
- **ConfigMap Missing**: Configuration missing

Recommendation: Taint/toleration - most educational, clearest error

### Branch Revert Strategy
- Option 1: `git revert HEAD` - creates new commit showing revert
- Option 2: `git reset --hard HEAD~1` - removes merge commit entirely
- Option 3: Store branch for future reuse

Recommendation: Option 1 - keeps full history, educational value

---

## Dependencies & Integration

### Internal Dependencies
- SpiderImage.jsx and SurpriseSpider.jsx (from V2 PRD)
- Kubernetes cluster with taint capability
- MCP server (from PRD #16)
- `/prd-done` command functionality

### External Dependencies
- V3 spider images (presenter-created)
- MCP server installation and configuration
- Viktor's website and presenter's website (for links)

### Integration with Existing Systems
- CI/CD pipeline (no changes needed)
- ArgoCD GitOps (will deploy and fail as designed)
- Kubernetes cluster (needs taint setup)
- Claude Code (uses MCP tools during demo)

---

## Risks & Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| V3 images not ready in time | High | Medium | Start drawing early, have backup images |
| Branch conflicts on merge | High | Low | Rebase frequently from main, test merge early |
| K8s failure scenario doesn't work | High | Low | Test taint setup thoroughly beforehand |
| MCP server unavailable during demo | High | Low | Have manual kubectl commands as backup |
| Interactive links break app | Medium | Low | Test extensively before demo |
| Revert doesn't work smoothly | Medium | Low | Practice revert workflow multiple times |
| Audience can't access reverted main | Medium | Low | All demos work on both states |

---

## Timeline & Phases

### Phase 1: Image Creation (Days 1-5)
- Design v3 spider concept
- Create v3 single and swarm images
- Get approval and finalize

### Phase 2: Code Integration (Days 6-7)
- Update components with v3 images
- Add comments
- Add link functionality
- Local testing

### Phase 3: K8s Setup (Days 8-9)
- Design failure scenario
- Document taint configuration
- Test failure and remediation
- Prepare MCP server integration

### Phase 4: Demo Preparation (Days 10-14)
- Create branch and test merge
- Full rehearsal of Part 4 workflow
- Practice MCP server troubleshooting
- Refine talking points
- Test revert procedure

### Phase 5: Final Polish (Days 15-16)
- Final rehearsals
- Create backup plan and screenshots
- Prepare slides with backup visuals
- Confidence check

**Total Estimated Time**: 16 days

---

## Progress Log

### 2025-10-31: PRD Created
- Initial PRD drafted for V3 branch feature
- Multi-part demo workflow outlined
- K8s failure scenario design documented

---

## Open Questions

1. **Link Destinations**: Should links go to personal websites or demo-specific pages?
   - Current plan: Viktor's bio/site + Presenter's portfolio site

2. **Link Interaction**: Should clicking links interrupt the demo flow?
   - Current plan: Open in new tabs, don't interrupt

3. **Branch Naming**: Should branch be temporary or kept for reuse?
   - Current plan: Keep for future demo cycles, can be reused

4. **K8s Failure Type**: Which failure is most educational - taint, resource limits, or something else?
   - Current plan: Taint/toleration - clearest and most common

5. **MCP Server Integration**: How deeply should MCP be integrated vs. separate demo?
   - Current plan: Part of the failure diagnosis workflow, integral to story

---

