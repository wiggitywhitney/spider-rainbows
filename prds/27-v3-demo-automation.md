# PRD: V3 Demo Automation Infrastructure

**Status**: In Progress
**Priority**: High
**GitHub Issue**: [#27](https://github.com/wiggitywhitney/spider-rainbows/issues/27)
**Created**: 2025-11-03

---

## Overview

### Problem Statement

The conference talk (Part 4) requires a repeatable, reliable way to transition from v2 to v3 during live demonstration. The demo must:
- Appear as legitimate development work (no visible "demo" artifacts)
- Include intentional Kubernetes failures for troubleshooting demonstration
- Be completely resettable to v1 baseline for repeat performances
- Work reliably under conference conditions

Currently, there is no automation infrastructure to support this workflow. Manual setup would be error-prone and time-consuming during a live talk.

### Solution Summary

Build demo automation infrastructure by updating existing scripts:

1. **Git Strategy**: Verify PRD-26 v3 implementation is merged to main, then immediately revert to preserve commit SHAs while maintaining v2 state
2. **`develop-next-version.sh` Updates**: Add v2→v3 section that creates new GitHub issue, copies completed PRD, cherry-picks v3 commits, and injects K8s failures
3. **Reset Script Updates**: Extend existing reset logic to handle v3→v2→v1 cleanup, including K8s state restoration

All automation will be modular, maintainable, and avoid "demo" language in audience-visible artifacts.

### User Impact

**Conference Presenter:**
- One command (`develop-next-version.sh`) sets up entire v3 demo
- Predictable, rehearsable demo flow
- Quick reset between demo runs
- Confident execution under pressure

**Conference Audience:**
- Sees realistic development workflow
- Experiences genuine troubleshooting with MCP tools
- Views live v3 deployment on their devices
- No awareness of demo automation infrastructure

---

## Success Criteria

### Demo Flow Success

**Starting State**: Application on v2

**Execute**: `./develop-next-version.sh`

**Expected Outcome**:
- New GitHub issue created (unique number, complete PRD linked)
- New feature branch created with all v3 implementation
- K8s failures injected (taints, resource over-allocation, broken probe)
- Ready for `/prd-done` workflow execution

**Execute**: `/prd-done` command

**Expected Outcome**:
- Use MCP dot-ai to diagnose K8s failures
- Fix failures one by one (cascading reveal)
- Merge branch successfully
- Super scary v3 image deploys
- Conference audience sees v3 on their devices

### Reset Flow Success

**Starting State**: After demo completion (v3 deployed or partially deployed)

**Execute**: Reset script

**Expected Outcome**:
- Project returns to v1 baseline
- Code is clean and minimal
- No v2 or v3 features present
- No v2 or v3 bugs present
- K8s cluster state clean (no taints, correct manifests)
- Ready to run full demo again (v1→v2→v3)

---

## Prerequisites

### Must Be Complete Before Starting

1. **PRD-26 Implementation**:
   - V3 feature fully implemented on feature branch
   - All PRD-26 milestones marked complete
   - Testing complete, feature working correctly

2. **PRD-26 Merged to Main**:
   - Feature branch merged to main
   - All v3 commit SHAs now in main branch history
   - Commit SHAs documented for cherry-picking

3. **Git Revert Performed**:
   - Immediate revert commit after PRD-26 merge
   - Working tree back to v2 state
   - Main branch contains v3 commits but not v3 functionality

4. **Existing Scripts Functional**:
   - `develop-next-version.sh` working for v1→v2
   - Reset scripts working for v2→v1
   - K8s cluster accessible and healthy

---

## Technical Approach

### Git Strategy

**Verification Phase**:
```bash
# Verify PRD-26 commits are in main
git log --oneline --grep="v3" main

# Verify working tree is v2 state (reverted)
git diff HEAD~1 HEAD  # Should show revert
```

**Commit Identification**:
Document the specific commit SHAs that implement v3:
- Image source updates
- Click zone implementation
- Comment additions
- Component modifications

These SHAs will be cherry-picked by the demo script.

### Script Modularization Strategy

Create helper scripts for clarity and maintainability:

```
scripts/
├── develop-next-version.sh        # Main orchestrator (already exists, extend it)
├── demo/
│   ├── create-v3-issue.sh        # Creates new GitHub issue
│   ├── generate-v3-prd.sh        # Copies and adjusts PRD-26
│   ├── inject-k8s-failures.sh    # Taints nodes, breaks manifests
│   └── README.md                 # Documentation for maintainers
```

Helper scripts keep main script readable and testable.

### Issue Creation Strategy

**Goals**:
- Create new issue each demo run (no reuse)
- Copy content from issue #26
- Get new issue number for PRD filename
- Link PRD correctly

**Implementation**:
```bash
# Extract issue #26 body as template
gh issue view 26 --json body -q .body > .demo/issue-template.md

# Create new issue
ISSUE_NUM=$(gh issue create \
  --title "PRD: V3 Horrifying Spider Images with Interactive Click Zones" \
  --body-file .demo/issue-template.md \
  --label "PRD" \
  | grep -o '#[0-9]*' | tr -d '#')

# Error handling
if [[ -z "$ISSUE_NUM" ]]; then
  echo "ERROR: Failed to create GitHub issue"
  exit 1
fi
```

### PRD File Generation Strategy

**Goals**:
- Copy completed PRD-26 exactly
- Update issue number references
- Update GitHub links
- Maintain all progress logs and completion status

**Implementation**:
```bash
# Copy PRD-26 as template
cp prds/26-v3-horrifying-spider-images.md prds/${ISSUE_NUM}-v3-horrifying-spider-images.md

# Update issue number references
sed -i.bak "s/#26/#${ISSUE_NUM}/g" prds/${ISSUE_NUM}-v3-horrifying-spider-images.md
sed -i.bak "s/issues\/26/issues\/${ISSUE_NUM}/g" prds/${ISSUE_NUM}-v3-horrifying-spider-images.md

# Update issue with PRD link
gh issue edit ${ISSUE_NUM} --body "$(cat .demo/issue-template.md)

**Detailed PRD**: See [prds/${ISSUE_NUM}-v3-horrifying-spider-images.md](https://github.com/wiggitywhitney/spider-rainbows/blob/main/prds/${ISSUE_NUM}-v3-horrifying-spider-images.md)"
```

### Commit Cherry-Pick Strategy

**Goals**:
- Replay v3 implementation commits
- Preserve original commit messages
- Handle conflicts gracefully

**Implementation**:
```bash
# Document these SHAs after PRD-26 merge
V3_COMMITS=(
  "abc123f"  # Specific commit SHAs from PRD-26
  "def456a"
  "789beef"
)

# Cherry-pick in order
for commit in "${V3_COMMITS[@]}"; do
  git cherry-pick "$commit" || {
    echo "ERROR: Cherry-pick failed at $commit"
    echo "Manual resolution required"
    exit 1
  }
done
```

**Alternative Approach** (if commits are contiguous):
```bash
# Cherry-pick range from main
git cherry-pick <first-v3-commit>^..<last-v3-commit>
```

### Kubernetes Failure Injection

**Three-Layer Cascading Failures**:

**Layer 1: Node Taints**
```bash
# Taint all nodes to prevent scheduling
kubectl taint nodes --all demo=scary:NoSchedule

# Deployment lacks matching toleration
# Pods will be Pending: "0/X nodes available: X node(s) had untolerated taint"
```

**Layer 2: Resource Over-Allocation**
```bash
# Modify gitops/manifests/spider-rainbows/deployment.yaml
sed -i.bak 's/memory: "128Mi"/memory: "10Gi"/' gitops/manifests/spider-rainbows/deployment.yaml
sed -i.bak 's/cpu: "100m"/cpu: "4000m"/' gitops/manifests/spider-rainbows/deployment.yaml

# Even after untainting, pods Pending: "Insufficient memory/cpu"
```

**Layer 3: Broken Liveness Probe**
```bash
# Change probe to wrong endpoint and port
sed -i.bak 's|path: /health|path: /healthz|' gitops/manifests/spider-rainbows/deployment.yaml
sed -i.bak 's/port: 8080/port: 9090/' gitops/manifests/spider-rainbows/deployment.yaml

# After fixing resources, pods CrashLoopBackOff: "Liveness probe failed"
```

**Failure Commit**:
All K8s modifications committed to feature branch, ready for merge via `/prd-done`.

### Reset Script Strategy

**Goals**:
- Clean up v3 artifacts
- Restore K8s to healthy state
- Return to v1 baseline
- Idempotent (safe to run multiple times)

**Extensions Needed**:
```bash
# In reset script, add v3 cleanup before v2→v1 logic

echo "Cleaning up v3 artifacts..."

# Delete v3 feature branch (if exists)
git branch -D feature/v3-scariest-spiders 2>/dev/null || true

# Remove v3 PRD files
rm -f prds/*-v3-horrifying-spider-images.md

# Restore K8s cluster state
echo "Restoring Kubernetes state..."
kubectl taint nodes --all demo=scary:NoSchedule- 2>/dev/null || true
git checkout origin/main -- gitops/manifests/spider-rainbows/deployment.yaml
kubectl apply -f gitops/manifests/spider-rainbows/deployment.yaml

echo "V3 cleanup complete, proceeding to v2→v1 reset..."
# ... existing v2→v1 logic continues ...
```

---

## Milestones

### Milestone 1: Git Strategy Complete

**Goal**: PRD-26 merged and reverted, commit SHAs documented

**Acceptance Criteria**:
- [ ] PRD-26 feature branch merged to main
- [ ] Revert commit created (working tree back to v2)
- [ ] V3 commit SHAs documented in this PRD or script
- [ ] Main branch verified: contains v3 commits, shows v2 functionality
- [ ] Commit SHAs tested with `git cherry-pick` (dry run)

**Validation**:
```bash
# Verify v3 commits in history
git log --oneline --grep="v3" main

# Verify working tree is v2
git diff HEAD~1 HEAD  # Should show revert changes

# Test cherry-pick (dry run)
git checkout -b test-cherry-pick
git cherry-pick <v3-commit-sha>
git checkout main
git branch -D test-cherry-pick
```

---

### Milestone 2: Helper Scripts Created

**Goal**: Modular helper scripts for issue, PRD, and K8s operations

**Acceptance Criteria**:
- [ ] `scripts/demo/` directory created
- [ ] `create-v3-issue.sh` creates new issue from template
- [ ] `generate-v3-prd.sh` copies and updates PRD-26
- [ ] `inject-k8s-failures.sh` applies all three K8s failures
- [ ] Each script has error handling and clear output
- [ ] Scripts tested independently
- [ ] README.md documents each script's purpose

**Validation**:
Run each helper script independently and verify outputs/effects.

---

### Milestone 3: `develop-next-version.sh` V2→V3 Section Implemented

**Goal**: Main script orchestrates full v2→v3 transition

**Acceptance Criteria**:
- [ ] Script detects current version (v2)
- [ ] Creates feature branch: `feature/v3-scariest-spiders`
- [ ] Calls helper scripts in correct order:
  1. Create GitHub issue
  2. Generate PRD file
  3. Cherry-pick v3 commits
  4. Inject K8s failures
- [ ] Commits all changes to feature branch
- [ ] Output clearly shows issue number and branch name
- [ ] Error handling prevents partial state
- [ ] No "demo" language in any committed files or messages

**Validation**:
```bash
# Start from v2
./develop-next-version.sh

# Verify:
# - New issue created and linked
# - New PRD file exists with correct issue number
# - Feature branch has v3 code + K8s failures
# - Ready for /prd-done workflow
```

---

### Milestone 4: K8s Failure Injection Verified

**Goal**: All three failure layers work correctly in demo environment

**Acceptance Criteria**:
- [ ] Layer 1 (node taints) prevents pod scheduling
- [ ] Layer 2 (resources) revealed after untainting
- [ ] Layer 3 (probe) revealed after fixing resources
- [ ] Each failure produces expected error messages
- [ ] MCP dot-ai can diagnose each layer
- [ ] Fixes work correctly (untaint, edit yaml, apply)
- [ ] After all fixes, v3 deploys successfully

**Validation**:
Run full demo flow in test environment, fix each failure layer, verify cascading behavior.

---

### Milestone 5: Reset Script Extended

**Goal**: Reset script handles v3→v2→v1 cleanup

**Acceptance Criteria**:
- [ ] V3 cleanup logic added before existing v2→v1 logic
- [ ] Deletes v3 feature branch (idempotent)
- [ ] Removes v3 PRD files (pattern match)
- [ ] Untaints cluster nodes (idempotent)
- [ ] Restores deployment.yaml from origin/main
- [ ] Applies clean manifest to cluster
- [ ] Existing v2→v1 logic still works
- [ ] Script safe to run multiple times
- [ ] Clear output shows each cleanup step

**Validation**:
```bash
# After v3 demo (any state)
./reset-to-v1-local.sh

# Verify:
# - No v3 branches exist
# - No v3 PRD files exist
# - Cluster has no taints
# - Deployment.yaml is clean
# - Application shows v1 state
```

---

### Milestone 6: End-to-End Demo Flow Validated

**Goal**: Complete demo flow works reliably from v2 to v3

**Acceptance Criteria**:
- [ ] Starting from v2, run `develop-next-version.sh`
- [ ] New issue and PRD created correctly
- [ ] Feature branch has all v3 code + K8s failures
- [ ] Execute `/prd-done` workflow
- [ ] K8s failures appear as expected (layer by layer)
- [ ] MCP dot-ai diagnoses failures correctly
- [ ] Fixes applied successfully (untaint, edit yaml, apply)
- [ ] V3 deploys and displays on audience devices
- [ ] Entire flow completable in demo timeframe (~20 min)
- [ ] Rehearsal confirms reliability

**Validation**:
Full dress rehearsal following DEMO-FLOW.md Part 4 exactly.

---

### Milestone 7: Reset Flow Validated

**Goal**: Reset script reliably returns to v1 baseline

**Acceptance Criteria**:
- [ ] Run reset script after v3 demo
- [ ] Project returns to v1 state (clean code)
- [ ] No v2 or v3 features present
- [ ] No v2 or v3 bugs present
- [ ] K8s cluster clean (no taints, correct manifests)
- [ ] Application displays v1 spiders
- [ ] Can immediately run v1→v2→v3 demo again
- [ ] Reset tested from multiple starting states:
  - After successful v3 deployment
  - After partial v3 deployment (failures not fixed)
  - After v2 state (no v3 run yet)

**Validation**:
Multiple reset cycles to verify idempotence and reliability.

---

## User Stories

### Story 1: Conference Presenter Setup

**As a** conference presenter
**I want to** run one command to set up the v3 demo
**So that** I can focus on narration and troubleshooting during the live talk

**Acceptance Criteria**:
- Single command execution: `./develop-next-version.sh`
- Script completes in <2 minutes
- Clear output confirms successful setup
- Issue number displayed for `/prd-done` reference
- No manual intervention required

---

### Story 2: Realistic Demo Appearance

**As a** conference presenter
**I want** all demo artifacts to look like legitimate development work
**So that** the audience experiences an authentic development workflow

**Acceptance Criteria**:
- No "demo" language in issue titles, PRD content, or commit messages
- PRD shows realistic completion (not template-like)
- Feature branch name matches organizational pattern
- K8s failures appear as production mistakes (not intentional demo bugs)

---

### Story 3: MCP Troubleshooting Demonstration

**As a** conference presenter
**I want** K8s failures to appear in layers (cascading)
**So that** I can demonstrate MCP dot-ai diagnosis across multiple problem types

**Acceptance Criteria**:
- Fix taint → reveals resource issue
- Fix resources → reveals probe issue
- Fix probe → deployment succeeds
- Each failure produces distinct, diagnosable error messages
- MCP dot-ai provides actionable remediation for each layer

---

### Story 4: Quick Reset Between Runs

**As a** conference presenter
**I want to** quickly reset the demo to v1 baseline
**So that** I can run the demo multiple times (practice, repeat conferences)

**Acceptance Criteria**:
- Reset script completes in <1 minute
- All v3 artifacts removed
- K8s state restored
- Application shows v1 spiders
- Ready for immediate re-run

---

## Risks and Mitigations

### Risk 1: Cherry-Pick Conflicts

**Risk**: Cherry-picking v3 commits from main may encounter conflicts if main has evolved

**Impact**: High - script would fail mid-execution during demo setup

**Likelihood**: Low - main should be stable during demo period

**Mitigation**:
- Test cherry-pick during rehearsal
- Keep main stable (no unrelated changes during conference period)
- If conflicts expected, document resolution steps
- Consider squashing v3 commits to single commit for simpler cherry-pick

---

### Risk 2: GitHub API Rate Limiting

**Risk**: Creating issues via `gh` CLI may hit rate limits during testing/rehearsal

**Impact**: Medium - script fails to create issue, blocks demo setup

**Likelihood**: Low - rate limits are generous for authenticated users

**Mitigation**:
- Use authenticated `gh` CLI (personal access token)
- Minimize test runs that create real issues
- Mock issue creation in development environment if needed
- Have fallback: manually create issue if script fails

---

### Risk 3: K8s Cluster State Pollution

**Risk**: Failed demo runs may leave cluster in inconsistent state (taints, broken manifests)

**Impact**: High - subsequent demo runs fail or behave unpredictably

**Likelihood**: Medium - especially during rehearsals with incomplete fixes

**Mitigation**:
- Reset script is idempotent (safe to run multiple times)
- Add verification checks in reset script
- Document manual cleanup steps as backup
- Test reset script thoroughly from various failure states

---

### Risk 4: Network Issues During Demo

**Risk**: GitHub API, K8s API, or audience access may be affected by conference network

**Impact**: High - demo cannot proceed or audience cannot participate

**Likelihood**: Medium - conference WiFi can be unreliable

**Mitigation**:
- Test all network operations in venue beforehand
- Have mobile hotspot backup
- Pre-cache what's possible (images, manifests)
- Document failure modes and recovery steps

---

### Risk 5: Script Complexity

**Risk**: Scripts become complex and hard to maintain as features evolve

**Impact**: Medium - harder to debug, update, or understand for future use

**Likelihood**: Medium - scope creep, edge cases, error handling add complexity

**Mitigation**:
- Keep scripts modular (helper scripts in `scripts/demo/`)
- Add comments explaining non-obvious logic
- Write README documenting each script's purpose
- Test scripts independently
- Keep error messages clear and actionable

---

## Dependencies

### Internal Dependencies

- **PRD-26 Implementation**: Must be complete and merged to main
- **Existing Scripts**: `develop-next-version.sh` and reset scripts must be functional
- **Demo Flow Documentation**: DEMO-FLOW.md Part 4 defines expected behavior
- **GitOps Manifests**: `gitops/manifests/spider-rainbows/deployment.yaml` must exist

### External Dependencies

- **GitHub CLI**: `gh` command must be installed and authenticated
- **Kubernetes Cluster**: Cluster must be accessible and healthy
- **kubectl**: Must be configured with correct context
- **Git**: Clean working directory, correct branch

### Demo Environment Dependencies

- **GKE Cluster**: With ArgoCD configured (5-second sync interval)
- **MCP dot-ai**: Installed and connected to cluster
- **Audience Access**: Application accessible via public URL
- **Claude Code**: `/prd-done` workflow configured and tested

---

## Open Questions

### 1. Commit SHA Documentation

**Question**: Where should we document the v3 commit SHAs for cherry-picking?

**Options**:
- A: Directly in `develop-next-version.sh` as array
- B: In this PRD (update after merge)
- C: Separate config file (e.g., `.demo/v3-commits.txt`)

**Recommendation**: Option A (in script) for simplicity, but document them in this PRD as backup.

---

### 2. Issue Template Storage

**Question**: Where should the issue #26 body template be stored?

**Options**:
- A: Extract dynamically each time: `gh issue view 26 --json body -q .body`
- B: Store as file: `.demo/issue-template.md` (commit to repo)
- C: Hardcode in script

**Recommendation**: Option B (committed file) for reliability and speed. Extract once, commit, reuse.

---

### 3. GitHub Issue Cleanup

**Question**: Should reset script close demo issues or leave them open?

**Options**:
- A: Leave open as historical record
- B: Close with comment: "Demo completed [date]"
- C: Delete issues (not possible via API)

**Recommendation**: Option A or B. Discuss preference. Closing with comment provides audit trail.

---

### 4. Error Recovery During Demo

**Question**: If script fails mid-execution during live demo, what's the recovery plan?

**Options**:
- A: Manual completion (presenter knows the steps)
- B: Backup branch pre-prepared (fall back to pre-made v3 branch)
- C: Skip to pre-deployed v3 (emergency backup)

**Recommendation**: Have option B as safety net. Test during rehearsal.

---

## Progress Log

### 2025-11-03: PRD Created

- Initial PRD created based on detailed planning discussion
- GitHub issue #27 created and linked
- Key decisions documented:
  - Git strategy: merge + revert approach
  - Script modularization via helper scripts
  - New issue creation each demo run
  - No "demo" language in visible artifacts
- Success criteria defined for both demo flow and reset flow
- 7 major milestones identified
- Risk assessment completed
- Ready to begin implementation once PRD-26 is merged and reverted

### 2025-11-03: Implementation Progress (~85% Complete)

**Note**: Milestones NOT marked complete due to incomplete K8s integration (Layer 1 kubectl taints require GKE auth configuration).

**Working Components**:

1. **Git Strategy**:
   - PRD-26 merged to main (commits 1b0bcc1, b74dbf2)
   - Verified cherry-pick works correctly
   - Main branch maintains clean v2 state

2. **Baseline Directory System**:
   - Created `.baseline/v1/` with canonical v1 component files
   - Enables idempotent reset operations
   - Verified files restore correctly

3. **develop-next-version.sh V3 Section**:
   - ✅ Creates feature branch: `feature/v3-scariest-spiders`
   - ✅ Verifies main branch is in clean v2 state before proceeding
   - ✅ Creates new GitHub issue (copies issue #26, removes demo reference)
   - ✅ Generates PRD file with updated issue number references
   - ✅ Cherry-picks v3 commits (1b0bcc1, b74dbf2) with intelligent conflict handling
   - ✅ Allows expected PRD conflicts, fails on unexpected conflicts
   - ✅ K8s Layer 2: Over-allocates resources (10Gi memory, 4000m CPU)
   - ✅ K8s Layer 3: Breaks liveness probe (wrong path `/healthz`, wrong port 9090)
   - ⚠️ K8s Layer 1: kubectl taint command fails gracefully (GKE auth not configured)
   - Tested successfully: v2 → v3 transition creates issue, PRD, code, K8s failures (Layers 2 & 3)

4. **develop-next-version.sh V2 Section**:
   - ✅ Creates feature branch: `feature/no-spider-teeth`
   - Ensures consistent branch workflow across versions

5. **reset-to-v1-local.sh Extensions**:
   - ✅ Extracts v3 issue number dynamically from PRD filename
   - ✅ Closes and deletes GitHub issue automatically
   - ✅ Cleans up both v2 and v3 feature branches
   - ✅ Removes v3 artifacts (clickHandlers.js, generated PRDs)
   - ✅ Restores deployment manifest (undoes K8s Layers 2 & 3)
   - ⚠️ kubectl untaint command fails gracefully (GKE auth not configured)
   - **Critical fix**: Reordered operations to clean git state BEFORE filesystem operations
   - **Critical fix**: Extracts issue number BEFORE git clean deletes PRD file
   - Tested successfully: Complete cleanup from v3 → v1

6. **End-to-End Testing**:
   - ✅ v2 → v3 automation: Successfully creates issue, PRD, feature branch, v3 code, K8s failures
   - ✅ v3 → v1 reset: Successfully cleans all artifacts, deletes branches, closes issues
   - ✅ Multiple reset cycles confirmed idempotent behavior
   - ✅ Scripts handle edge cases gracefully (missing files, already-deleted branches, etc.)

**Deferred to Future Milestone**:

- **K8s Layer 1 (Node Taints)**: `kubectl taint` command requires GKE authentication setup
  - Current behavior: Command fails gracefully, doesn't break script execution
  - Layers 2 & 3 still work correctly (manifest edits are filesystem operations)
  - Decision: Two-layer cascading failures sufficient for demo, Layer 1 enhancement deferred
  - Future work: Configure GKE auth plugin to enable kubectl cluster operations

**Technical Patterns Established**:

- **Git State Management**: Clean git state (reset/checkout/clean) BEFORE filesystem operations
- **Dynamic Resource Extraction**: Pattern-match filenames to extract metadata (issue numbers)
- **Cherry-Pick Conflict Handling**: Allow expected conflicts, fail fast on unexpected conflicts
- **Graceful Degradation**: kubectl commands fail gracefully when cluster unavailable
- **Idempotent Operations**: All cleanup scripts safe to run multiple times

**Key Implementation Details**:

- V3 commit SHAs documented in develop-next-version.sh: 1b0bcc1, b74dbf2
- Issue template dynamically extracted from issue #26 each run
- Helper script approach abandoned in favor of integrated implementation in main scripts
- All operations logged to `develop-next-version.log` for troubleshooting

**Next Steps**:

1. Configure GKE authentication (gcloud auth login, kubectl context setup)
2. Test kubectl taint/untaint operations with cluster access
3. Validate K8s Layer 1 behavior in demo flow
4. Full dress rehearsal with `/prd-done` workflow and MCP dot-ai integration
5. Mark milestones complete after K8s integration verified

---

## Notes

### Demo Context

This PRD supports [DEMO-FLOW.md Part 4](../DEMO-FLOW.md#part-3-v2--v3-platform-provided-tools--kubernetes-failures) and [CONFERENCE_TALK_OUTLINE.md Part 4](../CONFERENCE_TALK_OUTLINE.md#part-four-demoing-platform-provided-slash-commands-and-mcp-tools).

**Part 4 Demo Flow**:
1. Show platform-provided slash commands (`/prd-done`)
2. Execute `/prd-done` with completed PRD
3. Deployment starts but fails (K8s issues)
4. Use MCP dot-ai to diagnose and fix (3 layers)
5. V3 deploys successfully, audience sees scary spiders

### Modular Script Philosophy

Helper scripts in `scripts/demo/` serve multiple purposes:
- **Clarity**: Main script reads like orchestration, not implementation
- **Testability**: Each helper can be tested independently
- **Maintainability**: Easier to update individual components
- **Reusability**: Helpers might be useful for other demos/testing

### Avoiding "Demo" Language

Critical for authenticity. Use production-like language:
- ✅ "feature/v3-scariest-spiders" (feature branch)
- ❌ "demo/v3" or "test/v3"
- ✅ "PRD: V3 Horrifying Spider Images..." (descriptive)
- ❌ "Demo PRD: V3..." (exposes artifice)
- ✅ "feat: add interactive click zones" (commit message)
- ❌ "demo: prepare v3 for conference"

### Cascading Failure Design

The three-layer K8s failure approach is intentional:
- **Educational**: Shows multiple troubleshooting techniques
- **Realistic**: Production issues often hide behind other issues
- **Demonstrates MCP Value**: Each diagnosis reveals next problem
- **Time Management**: 5-7 min per layer = ~20 min total (fits Part 4 timing)

---

## Definition of Done

- [ ] All 7 milestones marked complete
- [ ] Demo flow success criteria validated
- [ ] Reset flow success criteria validated
- [ ] Helper scripts documented in README
- [ ] V3 commit SHAs documented (after PRD-26 merge)
- [ ] Full dress rehearsal completed successfully
- [ ] Edge cases tested (failed resets, network issues, etc.)
- [ ] Documentation updated (DEMO-FLOW.md if needed)
- [ ] Ready for conference execution

---

**Last Updated**: 2025-11-03
**PRD Owner**: Development Team
**Stakeholders**: Conference Presentation Team
