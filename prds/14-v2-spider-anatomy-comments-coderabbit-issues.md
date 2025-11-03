# PRD: V2 Spider Anatomy Comments + CodeRabbit Issues

**Status**: Draft
**Created**: 2025-10-31
**GitHub Issue**: [#20](https://github.com/wiggitywhitney/spider-rainbows/issues/20)
**Priority**: High

---

## Conference Demo Context

**IMPORTANT**: This PRD implements requirements for the conference talk demonstration:
- **Talk Outline**: [CONFERENCE_TALK_OUTLINE.md](../CONFERENCE_TALK_OUTLINE.md)
- **Demo Flow**: [DEMO-FLOW.md](../DEMO-FLOW.md)

**Part 2 (15-20 min)**: Developer workflow - v1→v2 code quality issues
**Part 4 (15-25 min)**: Platform-provided tools - v2→v3 slash commands + K8s failures

---

## Related Resources

- [SpiderImage.jsx](../src/components/SpiderImage.jsx)
- [SurpriseSpider.jsx](../src/components/SurpriseSpider.jsx)
- [CodeRabbit Review Guide](../.claude/CLAUDE.md)
- [V2 Spider Images](../public/Spider-v2.png) and [Swarm](../public/spidersspidersspiders-v2.png)
- [Conference Talk Outline](../CONFERENCE_TALK_OUTLINE.md) - **Full conference structure**
- [Demo Flow](../DEMO-FLOW.md) - **Step-by-step demo execution**

---

## Prerequisites

**Manual Steps (Must be completed before starting implementation)**:
1. Rename image files:
   - Current `Spider-v2.png` → `Spider-v1.png`
   - Current `spidersspidersspiders-v2.png` → `spidersspidersspiders-v1.png`
   - Current `Spider-v3.png` → `Spider-v2.png`
   - Current `spidersspidersspiders-v3.png` → `spidersspidersspiders-v2.png`
2. Remove old v1 files:
   - Delete `Spider.png`
   - Delete `spidersspidersspiders.png`
3. Create and add new v3 artwork (scariest spiders version):
   - Add `Spider-v3.png`
   - Add `spidersspidersspiders-v3.png`

---

## Problem Statement

**Conference Demo**: This PRD covers requirements for the conference talk. See [CONFERENCE_TALK_OUTLINE.md](../CONFERENCE_TALK_OUTLINE.md) for full context and [DEMO-FLOW.md](../DEMO-FLOW.md) for step-by-step execution.

This PRD covers conference demo requirements for both Part 2 (v1→v2 developer workflow) and Part 4 (v2→v3 platform-provided tools + K8s troubleshooting).

**Part 2 Requirements**:
Part 2 demonstrates pure developer workflow using Claude Code with an IDP. Need realistic code quality issues for CodeRabbit to flag, plus educational narrative about spider anatomy.

**Current State (Part 2)**:
- V2 spider images exist (cheesy grins)
- No code comments explaining spider anatomy
- No CodeRabbit issues to demonstrate remediation workflow

**Demo Impact (Part 2)**:
- Cannot show realistic code review workflow
- Missing educational narrative about spider characteristics
- No opportunity to discuss how AI helps with code quality issues

**Part 4 Requirements**:
Part 4 demonstrates platform-provided slash commands and MCP tools. Need a demo PRD showing "scariest spiders" feature nearly complete, ready for `/prd-done` workflow execution. Also need cascading K8s failures to demonstrate MCP troubleshooting.

**Current State (Part 4)**:
- No demo PRD file showing realistic "mostly complete" state
- No `/prd-done` workflow integration
- Need K8s failures (taints, resources, probes) to trigger after deployment

**Demo Impact (Part 4)**:
- Cannot demonstrate platform-provided slash commands
- No realistic PRD lifecycle to show
- Missing opportunity to show AI-augmented organizational workflows
- Cannot demonstrate MCP tools for infrastructure troubleshooting

---

## Solution Overview

This PRD covers both Part 2 (v1→v2) and Part 3 (v2→v3) of the conference demo, using `develop-next-version.sh` to automate issue introduction.

### Part 2: V1 → V2 (Code Quality Issues)

Add narrative code comments explaining spider anatomy to v2 components, and strategically introduce code quality issues that CodeRabbit will flag:

**Educational Narrative**:
- Comments explain spider mouth parts (chelicerae, external digestion)
- Comments tie to why v2 image looks different from v1
- Provides story for presenter to tell during demo

**Code Quality Issues** (intentional for demo):
- Duplicated functionality across components
- Dead/uninitialized variables
- These create realistic CodeRabbit findings to remediate
- Script also introduces width bug (spider too large) causing test failures

### Part 3: V2 → V3 (Kubernetes Failures)

Add comments about "wildly scariest spider image yet" and introduce cascading Kubernetes deployment failures:

**Educational Narrative**:
- Comments emphasize v3 as the scariest version
- Ties to horror/fear theme progression (cute → scary → scariest)

**Kubernetes Failures** (intentional for demo - DEEP complexity):
1. **Node Taints** - Script taints all nodes with `demo=scary:NoSchedule`
   - Deployment lacks matching toleration
   - Pods stuck in `Pending` state

2. **Resource Over-Allocation** - Deployment requests excessive resources
   - Memory: 10Gi (way more than nodes have)
   - CPU: 4000m (4 cores)
   - Even after fixing taints, pods still `Pending`

3. **Broken Liveness Probe** - Wrong port and path
   - Path: `/healthz` (should be `/health`)
   - Port: `9090` (should be `8080`)
   - Even after fixing resources, pods enter `CrashLoopBackOff`

**Cascading Failure Design**:
- Fix taint → reveals resource issue
- Fix resources → reveals probe issue
- Fix probe → deployment succeeds
- Demonstrates realistic production debugging with MCP dot-ai

---

## Goals & Success Criteria

### Primary Goals - Part 2 (V1→V2)
- [ ] V2 components have educational spider anatomy comments
- [ ] Duplicated functionality strategically placed
- [ ] Dead/uninitialized variables introduced
- [ ] Width bug causes test failures
- [ ] CodeRabbit flags realistic issues
- [ ] Presenter can remediate during Part 2 demo
- [ ] Narrative enhances demo storytelling

### Primary Goals - Part 4 (V2→V3)
- [ ] V3 components have "scariest spider" comments
- [ ] Interactive links: clicking spiders opens websites (Viktor's site, presenter's site)
- [ ] Demo PRD created showing "mostly complete" state
- [ ] `/prd-done` workflow demonstrates platform-provided slash commands
- [ ] Script taints all cluster nodes with `demo=scary:NoSchedule`
- [ ] Deployment manifest has excessive resource requests (10Gi memory, 4 CPUs)
- [ ] Deployment manifest has broken liveness probe (wrong port/path)
- [ ] Cascading failures require multi-step debugging
- [ ] MCP dot-ai assists with Kubernetes issue diagnosis
- [ ] Presenter can remediate all K8s issues during Part 4 demo

### Success Metrics - Part 2
- [ ] Code comments are scientifically accurate about spider anatomy
- [ ] CodeRabbit produces 3-5 actionable issues
- [ ] Issues are remediable in <10 minutes
- [ ] Test failures are clear and fixable
- [ ] Changes merged to main after demo completion
- [ ] Demo shows complete CI/CD + code review workflow

### Success Metrics - Part 4
- [ ] Interactive links work smoothly (open in new tabs, don't interrupt demo)
- [ ] Demo PRD accurately reflects "mostly complete" state
- [ ] `/prd-done` executes complete workflow successfully
- [ ] All 3 K8s failures trigger correctly (taint, resources, probe)
- [ ] Cascading failure behavior works (fixing one reveals next)
- [ ] MCP dot-ai can diagnose each layer of failure
- [ ] Total remediation time: 10-20 minutes (deep complexity)
- [ ] Deployment succeeds after all fixes applied
- [ ] Demo shows realistic production debugging workflow
- [ ] V3 spiders display on audience devices after successful deployment

### Non-Goals
- Changing actual spider images (handled separately)
- Permanent code duplication (only for demo period)
- Breaking application functionality permanently
- Hiding the intentional issues from code review
- Creating failures that can't be remediated during demo timeframe

---

## User Stories & Use Cases

### Primary User Story
**As a** conference presenter
**I want** to demonstrate realistic code review workflow during Part 2
**So that** I can show how AI coding assistants help with code quality while building the platform

**Acceptance Criteria**:
- Code comments tell story about spider anatomy
- CodeRabbit flags meaningful issues
- Issues can be fixed quickly live during demo
- Both v1 (clean) and v2 (issues) states work correctly

### Use Case 1: Part 2 Demo Code Review Flow
**Context**: Presenter commits v2 spider code changes
**Flow**:
1. Presenter updates components with v2 comments and duplicated code
2. Git commit → Push to main
3. GitHub Actions CI completes
4. CodeRabbit reviews code
5. Presenter opens PR, shows CodeRabbit findings
6. Explains issues to audience
7. Remediates issues live using Claude Code
8. Shows clean PR and merge
9. App deploys v2 with clean code

### Use Case 2: Educational Narrative
**Context**: Audience learns about spider anatomy while watching code
**Flow**:
1. Presenter commits new v2 code
2. During deployment wait, presenter explains code comments
3. Discusses real spider characteristics: chelicerae, external digestion
4. Explains why v2 image reflects actual anatomy
5. Ties back to software engineering principles: documentation, clarity
6. Meanwhile CI/CD completes and CodeRabbit findings appear

---

## Technical Approach

### Script-Based Automation

**Core Tool**: `develop-next-version.sh`
- Existing script handles version detection and image source updates
- Script will be modified to add:
  1. User-provided spider anatomy comments
  2. Duplicated code (instead of fake credentials)
  3. Dead/uninitialized variables (instead of fake credentials)
- Script runs to prepare v2 changes for commit

### Code Comments - Spider Anatomy Narrative

**User-Controlled Content**:
- User will provide exact comment text (100% control)
- Comments will be added to SpiderImage.jsx
- Comments will be added to SurpriseSpider.jsx
- Comments should explain spider anatomy and tie to v2 image appearance

### Code Quality Issues - Intentional for Demo

**Approach**: Replace fake credentials block with realistic code issues
- **Old approach** (lines 46-58): Added fake API keys, secrets, tokens
- **New approach**: Add duplicated code and dead/uninitialized variables
- Exact implementation details: TBD during implementation
- Goal: Trigger 3-5 CodeRabbit findings that are realistic and remediable

### Integration Strategy

**Phase 1: Script Development**
- Modify `develop-next-version.sh` v2 section
- Remove fake credentials logic
- Add comment injection logic
- Add code duplication logic
- Add dead code logic
- Test script execution locally

**Phase 2: Demo Day Execution**
- Run script to generate v2 changes
- Commit changes to trigger CodeRabbit review
- Show CodeRabbit findings during demo
- Remediate issues live with Claude Code
- Push clean code

---

## Success Criteria

### Functional Requirements
- [ ] App still works perfectly with duplicated code (no functionality breaking)
- [ ] Spider anatomy comments are scientifically accurate
- [ ] V2 images display correctly with new code
- [ ] Dead code doesn't impact application behavior

### Code Review Requirements
- [ ] CodeRabbit flags at least 3 actionable issues
- [ ] Issues are realistic (not artificial/obvious)
- [ ] Issues are remediable in <10 minutes
- [ ] Presenter understands each issue and how to fix it

### Demo Requirements
- [ ] Comments add narrative value to demo story
- [ ] Code issues demonstrate real code review workflow
- [ ] Remediation can be done live with Claude Code
- [ ] Changes can be pushed and app redeployed within demo timeframe

---

## Milestones

### Milestone 1: Prerequisites Complete & Assets Ready
- [ ] Rename image files (v2→v1, v3→v2)
- [ ] Remove old v1 files (Spider.png, spidersspidersspiders.png)
- [ ] Create and add new v3 artwork (scariest spiders version)
- [ ] Commit asset changes to branch

**Success Criteria**: All spider image assets are properly versioned and committed

---

### Milestone 2: Spider Anatomy Comments Written

**Demo Context**: See [DEMO-FLOW.md Part 2](../DEMO-FLOW.md#part-2-v1--v2-code-quality-issues) for how this integrates into the conference demo.

- [ ] User writes spider anatomy comments (100% user-provided content)
- [ ] Update `develop-next-version.sh` to add user-provided comments to SpiderImage.jsx (v2 version)
- [ ] Update `develop-next-version.sh` to add user-provided comments to SurpriseSpider.jsx (v2 version)
- [ ] Comments tie to v2 image appearance
- [ ] Script replaces fake credentials approach with duplicated code + dead/uninitialized variables

**Success Criteria**: Script automates v1→v2 transition with comments and code issues that trigger CodeRabbit

---

### Milestone 3: V2 Script Implementation (Part 2)

**Demo Context**: This milestone supports [DEMO-FLOW.md Part 2](../DEMO-FLOW.md#part-2-v1--v2-code-quality-issues) - the developer workflow demonstration.

- [ ] Modify `develop-next-version.sh` v2 section to remove fake credentials logic
- [ ] Add user-provided spider anatomy comments injection
- [ ] Add duplicated code injection
- [ ] Add dead/uninitialized variables injection
- [ ] Keep existing width bug logic (spider scale 0.50 instead of 0.25)
- [ ] Script creates feature branch automatically
- [ ] Test script execution locally

**Success Criteria**: Script successfully generates v1→v2 transition with all intended issues

---

### Milestone 4: V3 Script Implementation (Part 4)

**Demo Context**: This milestone supports [DEMO-FLOW.md Part 4](../DEMO-FLOW.md#part-3-v2--v3-platform-provided-tools--kubernetes-failures) - platform-provided tools and K8s troubleshooting. See also [CONFERENCE_TALK_OUTLINE.md Part 4](../CONFERENCE_TALK_OUTLINE.md#part-four-demoing-platform-provided-slash-commands-and-mcp-tools).

- [ ] Add v3 section to `develop-next-version.sh`
- [ ] Script creates demo PRD file (`prds/demo-scariest-spiders.md`) showing "mostly complete" status
- [ ] Demo PRD has realistic milestones (2.5/3 complete)
- [ ] Add user-provided "scariest spider" comments injection
- [ ] Add kubectl command to taint all nodes: `kubectl taint nodes --all demo=scary:NoSchedule`
- [ ] Add sed/yaml modification to increase resource requests (10Gi memory, 4000m CPU)
- [ ] Add sed/yaml modification to break liveness probe (path: `/healthz`, port: `9090`)
- [ ] Script creates feature branch automatically
- [ ] Test script execution with active cluster

**Success Criteria**: Script successfully generates v2→v3 transition with demo PRD and all 3 K8s failures

---

### Milestone 5: Slash Commands Integration

**Demo Context**: Critical for [DEMO-FLOW.md Part 4 Step 3](../DEMO-FLOW.md#step-3-execute-prd-done-command) - executing `/prd-done` workflow live during demo.

- [ ] Verify duplicate MCP PRD commands are hidden/disabled
- [ ] Keep local slash commands: `/prd-create`, `/prd-start`, `/prd-next`, `/prd-update-progress`, `/prd-done`
- [ ] Test `/prd-done` workflow with demo PRD
- [ ] Verify `/prd-done` handles: branch creation, PR creation, CodeRabbit review, merge
- [ ] Test CodeRabbit review integration within `/prd-done` workflow
- [ ] Verify organizational compliance enforcement (code review required)

**Success Criteria**: Slash commands work correctly, no duplicate MCP commands visible, `/prd-done` executes complete workflow

---

### Milestone 6: Integration Testing

**Demo Context**: Full rehearsal following [DEMO-FLOW.md](../DEMO-FLOW.md) exactly as it will be presented. Reference [CONFERENCE_TALK_OUTLINE.md](../CONFERENCE_TALK_OUTLINE.md) for timing and narrative.

- [ ] Test complete Part 2 flow: v1→v2 with code issues + CodeRabbit review (NO PRD mentions)
- [ ] Test complete Part 4 flow: v2→v3 with slash commands + K8s failures + MCP diagnosis
- [ ] Verify demo PRD shows correct "mostly complete" state
- [ ] Verify `/prd-done` workflow completes successfully
- [ ] Verify cascading failure behavior (fix taint → see resources → see probe)
- [ ] Verify all issues are remediable within demo timeframe
- [ ] Practice full demo run-through

**Success Criteria**: Both demo parts work end-to-end with all intended failures, remediations, and platform tool demonstrations

---

## Implementation Details

**Demo Context**: These implementation details support the execution outlined in [DEMO-FLOW.md](../DEMO-FLOW.md). For full conference context, see [CONFERENCE_TALK_OUTLINE.md](../CONFERENCE_TALK_OUTLINE.md).

### Script-Based Implementation Strategy

**Primary Tool**: Modify `develop-next-version.sh` to automate both v1→v2 and v2→v3 transitions
- Script already exists and handles version detection/switching
- Currently adds fake credentials for v2 (lines 46-58) - **REPLACE THIS**
- Script will handle branch creation automatically
- Script will inject issues appropriate for each version

### Part 2: V1→V2 Implementation (Code Quality Issues)

**Branch Creation**:
```bash
# Script detects current version and creates feature branch
git checkout -b feature/v2-spider-anatomy
```

**Comment Injection Strategy**:
- User provides exact comment text (100% control)
- Script uses `sed` or heredoc to inject into SpiderImage.jsx
- Script uses `sed` or heredoc to inject into SurpriseSpider.jsx
- Comments placed near image src references

**Code Duplication Strategy**:
- Replace fake credentials approach with duplicated code
- Strategy details: TBD during implementation
- Options include:
  - Duplicated utility functions
  - Cross-component duplication
  - Duplicated logic within components

**Dead Code Strategy**:
- Add unused but realistic-looking code via script
- Options include:
  - Unused variables
  - Unused functions
  - Uninitialized variables

**Width Bug** (already exists):
- Keep existing logic: `const spiderWidth = rainbowWidth * 0.50` (should be 0.25)
- This causes test failures that need fixing

### Part 4: V2→V3 Implementation (Platform Tools + Kubernetes Failures)

**Branch Creation**:
```bash
# Script detects current version and creates feature branch
git checkout -b feature/v3-scariest-spiders
```

**Demo PRD Creation**:
Script creates `prds/demo-scariest-spiders.md` with:
```markdown
# PRD: Scariest Spiders Feature (V3)

**Status**: Ready for Completion
**Created**: 2025-11-03

## Milestones

### Milestone 1: Scariest Spider Design
- [x] Created v3 artwork (horror-themed spiders)
- [x] Added scary spider comments to components

### Milestone 2: Implementation Complete
- [x] Updated SpiderImage.jsx with v3 references
- [x] Updated SurpriseSpider.jsx with v3 references
- [x] All local tests passing

### Milestone 3: Deployment (In Progress)
- [ ] Feature branch merged to main
- [ ] Successfully deployed to production

Ready to run /prd-done!
```

**Comment Injection Strategy**:
- User provides "scariest spider" comment text
- Script injects into both components

**Interactive Links Implementation**:
Wrap spiders in clickable links:
```javascript
// SpiderImage.jsx - wrap in link to Viktor's site
<a href="https://viktor-site.com" target="_blank" rel="noopener noreferrer">
  <img src="/Spider-v3.png" alt="spider" className="spider-image" />
</a>

// SurpriseSpider.jsx - wrap in link to presenter's site
<a href="https://presenter-site.com" target="_blank" rel="noopener noreferrer">
  <img src="/spidersspidersspiders-v3.png" alt="spider swarm" className="surprise-spider-image" />
</a>
```
- Links open in new tabs (don't interrupt demo)
- No interference with spider add/remove functionality
- Simple JSX wrapping, minimal code change

**Slash Commands Integration**:
- Demo PRD enables `/prd-done` workflow demonstration
- Shows platform-provided tool for organizational compliance
- Demonstrates AI-augmented workflow with human decision-making

**Kubernetes Failure Injection**:

1. **Node Taints** (kubectl command):
```bash
# Taint all nodes in the cluster
kubectl taint nodes --all demo=scary:NoSchedule

# Deployment needs this toleration (but script DOES NOT add it):
# tolerations:
# - key: "demo"
#   operator: "Equal"
#   value: "scary"
#   effect: "NoSchedule"
```

2. **Resource Over-Allocation** (modify deployment.yaml):
```bash
# Script modifies gitops/manifests/spider-rainbows/deployment.yaml
# Using sed or yq to change resource requests:
sed -i 's/memory: "128Mi"/memory: "10Gi"/' gitops/manifests/spider-rainbows/deployment.yaml
sed -i 's/cpu: "100m"/cpu: "4000m"/' gitops/manifests/spider-rainbows/deployment.yaml
```

3. **Broken Liveness Probe** (modify deployment.yaml):
```bash
# Change probe path and port to incorrect values
sed -i 's|path: /health|path: /healthz|' gitops/manifests/spider-rainbows/deployment.yaml
sed -i 's/port: 8080/port: 9090/' gitops/manifests/spider-rainbows/deployment.yaml
```

**Cascading Failure Verification**:
- Script commits changes to feature branch
- Presenter pushes to trigger ArgoCD sync
- Failures appear in order:
  1. Pods `Pending` due to taint
  2. Fix taint → Pods still `Pending` due to resources
  3. Fix resources → Pods `CrashLoopBackOff` due to probe
  4. Fix probe → Deployment succeeds

---

## Dependencies & Integration

### Internal Dependencies
- SpiderImage.jsx (main component)
- SurpriseSpider.jsx (easter egg component)
- spiderUtils.js (utility functions)
- Spider images: v1 (cheesy grins, renamed from v2), v2 (scarier, renamed from v3), v3 (scariest, new artwork)

### Integration with Existing Systems
- CI/CD pipeline (already configured)
- CodeRabbit reviews (already enabled)
- ArgoCD/GitOps (no changes needed)
- App functionality (no changes, only additions)

---

## Risks & Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Code duplication breaks app | High | Low | Test thoroughly in all environments |
| CodeRabbit doesn't flag issues | High | Low | Verify findings in draft PR first |
| Code review workflow feels forced | Medium | Medium | Make all changes feel organic and realistic |
| K8s taints persist after demo | Medium | Low | Document untaint command: `kubectl taint nodes --all demo=scary:NoSchedule-` |
| K8s failures too complex to fix in demo time | High | Medium | Practice full remediation flow multiple times; have fix cheat sheet ready |
| Script modifies deployment.yaml incorrectly | High | Low | Test script with live cluster; verify yaml syntax after modifications |
| Multiple cascading failures confuse audience | Medium | Medium | Clear narrative explaining each layer; MCP diagnosis makes issues visible |
| Cluster doesn't exist when v3 script runs | High | Low | Document prerequisite: run setup-platform.sh before demo |

---

## Timeline & Phases

### Phase 1: Asset Preparation
- Rename spider image files
- Remove old v1 files
- Create and add new v3 artwork
- Commit asset changes

### Phase 2: Planning & Script Design
- User writes spider anatomy comments (v2)
- User writes "scariest spider" comments (v3)
- Design code duplication strategy for v2
- Design K8s failure injection strategy for v3

### Phase 3: V2 Script Implementation
- Modify `develop-next-version.sh` v2 section
- Remove fake credentials logic
- Add comment injection
- Add code duplication injection
- Add dead code injection
- Test v1→v2 transition

### Phase 4: V3 Script Implementation
- Add v3 section to `develop-next-version.sh`
- Add comment injection
- Add kubectl taint command
- Add deployment.yaml modifications (resources + probe)
- Test v2→v3 transition with live cluster

### Phase 5: Integration Testing & Demo Practice
- Test complete Part 2 flow (v1→v2)
- Test complete Part 3 flow (v2→v3)
- Verify cascading K8s failures
- Practice full demo run-through
- Verify all remediations work within timeframe

**Total Estimated Time**: 5-7 days

---

## Progress Log

### 2025-11-03: Merged PRD 15 into PRD 14
- **Decision**: Consolidate all demo requirements into single PRD
- **From PRD 15**: Added interactive links feature (clicking spiders opens websites)
- **Implementation discussion**: Deferred script vs. branch strategy decision to implementation time
- **PRD 15 status**: Will be closed/abandoned, content merged here

### 2025-11-03: Slash Commands Integration + Demo PRD Strategy
- **Decision**: Keep local slash commands, hide/disable duplicate MCP PRD commands
- **Part 4 Integration**: Demo will execute `/prd-done` workflow
- **Demo PRD**: Script creates `prds/demo-scariest-spiders.md` showing "mostly complete" state
- **Workflow**: `/prd-done` handles branch, PR creation, CodeRabbit review, merge, deployment
- **Narrative**: Platform-provided tools (slash commands + MCP) demonstrated together
- Updated DEMO-FLOW.md with complete Part 4 integration
- Added Milestone 5 for slash commands integration testing

### 2025-11-03: PRD Expanded to Include V3 + K8s Failures
- Added Part 4 (v2→v3) with platform tools + cascading Kubernetes failures
- Designed 3-layer failure strategy: taints → resources → probe
- Script will use kubectl to taint nodes with `demo=scary:NoSchedule`
- Script will modify deployment.yaml to over-allocate resources (10Gi memory, 4 CPUs)
- Script will break liveness probe (wrong path `/healthz`, wrong port `9090`)
- Cascading failures demonstrate deep debugging with MCP dot-ai
- User confirmed: go DEEP with complexity, cluster exists during demo
- Updated milestones to cover both v2 and v3/v4 script implementations

### 2025-11-03: Milestone 2 Strategy Refined
- Updated implementation approach to be script-based
- User will have 100% control over comment content
- Replacing fake credentials approach with duplicated code + dead/uninitialized variables
- Modified `develop-next-version.sh` will automate v1→v2 transition
- Exact implementation details to be determined during implementation phase

### 2025-10-31: PRD Created
- Initial PRD drafted for V2 comments and code issues
- Educational narrative strategy outlined
- CodeRabbit issue strategy designed

---

## Open Questions

1. **Comment Detail Level**: How technical should spider anatomy comments be?
   - Current plan: Accessible to general audience, 2-3 key facts

2. **How Many Issues**: Should we aim for 3, 5, or more CodeRabbit findings?
   - Current plan: 3-5 realistic, remediable issues

3. **Dead Code Realism**: Should dead code look like forgotten code or obviously unused?
   - Current plan: Realistic-looking, not obviously fake

4. **Implementation Strategy Discussion** (TO BE RESOLVED AT IMPLEMENTATION TIME):
   - **Option A: Script-based approach** (current plan)
     - `develop-next-version.sh` generates v2 and v3 changes on-demand
     - `reset-to-v1.sh` returns to clean state
     - Pros: Automated, repeatable, no branch management
     - Cons: Script complexity, harder to preview changes

   - **Option B: Branch-based approach** (alternative from PRD 15)
     - Pre-prepared branches for v2 and v3
     - Switch branches for each demo part
     - Merge during demo, revert after
     - Pros: Easy to preview, simple to execute during demo
     - Cons: Branch management overhead, potential conflicts

   - **Decision needed**: Discuss pros/cons at implementation time
   - **Considerations**: Demo reliability, ease of preview, repeatability, branch management complexity

---

