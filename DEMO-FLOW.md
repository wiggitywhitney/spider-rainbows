# Spider-Rainbows Conference Demo Flow

## Overview

This document outlines the complete flow for the spider-rainbows conference demo, covering setup, Part 2 (code quality issues), and Part 3 (Kubernetes failures).

---

## Pre-Demo Setup

**Timing**: Before presentation starts

### 1. Run Platform Setup
```bash
./setup-platform.sh
# Choose: GCP (cloud)
# Wait for completion (~10-15 minutes)
```

**What this does**:
- Creates GKE cluster in GCP project `demoo-ooclock`
- Installs ArgoCD with 5-second sync interval
- Deploys spider-rainbows app (v1)
- Configures ingress for both ArgoCD and app
- Sets up MCP dot-ai authentication

**Verify**:
- ArgoCD UI accessible: `https://argocd.<EXTERNAL-IP>.nip.io`
  - Username: `admin`
  - Password: `admin123`
- App accessible: `http://spider-rainbows.<EXTERNAL-IP>.nip.io`
- App shows v1 spiders (cute/friendly version)

### 2. Verify MCP Server
```bash
# Restart Claude Code to connect to new cluster
# Verify dot-ai MCP server is connected
```

---

## Part 1: Show Working Application

**Timing**: 2-3 minutes

### Demo Steps
1. Open browser to app URL
2. Show v1 spiders (cute version)
3. Show ArgoCD UI with synced application
4. But this version has a huge problem: spiders don't have teeth. 

**Key Points**:
- Everything is working perfectly
- v1 represents "baseline" state
- About to start development of v2 features

---

## Part 2: V1 → V2 (Code Quality Issues)

**Timing**: 15-20 minutes

### Step 1: Run Development Script
```bash
./develop-next-version.sh
```

**What this does**:
- Detects current version (v1)
- Creates feature branch: `feature/v2-accurate-spider-mouth`
- Updates images from v1 to v2
- Adds spider mouth comments
- Introduces code duplication
- Introduces dead/uninitialized variables
- Introduces width bug (spider too large)

**Explain to audience**:
- Script simulates developer making changes


### Step 2: Create Pull Request with AI
```bash
# Use Claude Code to analyze changes and create PR
# AI will generate description based on code changes
```

**What AI does**:
- Analyzes git diff
- Generates PR title and description
- Creates PR to merge feature branch to main

**Show PR**:
- Open PR in GitHub
- Show AI-generated description
- Explain: "Now we wait for CI/CD pipeline"

### Step 3: CI Fails - Fix with AI
**What happens**:
- GitHub Actions runs tests
- Tests fail due to width bug (spider scale 0.50 instead of 0.25)

**Fix with Claude Code**:
```
"The tests are failing. Can you help me fix it?"
```

**What AI does**:
- Reviews test output
- Identifies width bug in SpiderImage.jsx
- Fixes: `const spiderWidth = rainbowWidth * 0.25`
- Commits fix

**Push fix**:
```bash
git push
```

**Explain to audience**:
- AI diagnosed test failure
- Fixed the bug
- CI will re-run automatically

### Step 4: CodeRabbit Review Appears
**What happens**:
- CodeRabbit analyzes the PR
- Flags 3-5 issues:
  - Code duplication across components
  - Unused/dead variables
  - Potentially uninitialized variables

**Show CodeRabbit comments**:
- Use CodeRabbit mcp to understand and fix problems.

**Explain to audience**:
- Automated code review caught issues we introduced
- Now we'll fix them with AI assistance

### Step 5: Fix CodeRabbit Issues with AI
- Again, use CodeRabbit mcp to understand and fix problems.

**What AI does**:
- Reads CodeRabbit review comments
- Fixes duplication
- Removes dead code
- Commits fixes

**Push fixes**:
```bash
git push
```

**Verify**:
- CI passes (green checkmark)
- CodeRabbit shows issues resolved

### Step 6: Merge and Deploy V2
```bash
# Merge PR via GitHub UI or CLI
gh pr merge --squash  # or via GitHub UI
```

**What happens**:
- PR merges to main
- GitHub Actions builds new Docker image
- Updates GitOps repo with new image tag
- ArgoCD syncs (5-second interval)
- v2 spiders deploy

**Show the deployed app**:
- Refresh browser
- Show v2 of the app
- "This is how a developer interfaces with your platform now, with an AI assistant"

---

## Part 3: V2 → V3 (Platform-Provided Tools + Kubernetes Failures)

**Timing**: 5-10 minutes

**Context for Audience**: Viktor just explained how platforms should provide slash commands and MCP tools for AI-augmented workflows. Now Whitney will demonstrate these platform-provided interfaces in action.

---

### Step 1: Show Platform-Provided Slash Commands

**Demonstrate discoverability**:
```bash
# In Claude Code, type: /prd
# Show autocomplete dropdown with available commands
```

**Explain to audience**:
- "These slash commands are provided by the platform"
- "They're discoverable through autocomplete - no need to memorize"
- "They automate organizational workflows while letting AI help"

**Show the commands available**:
- `/prd-create` - Create new PRD
- `/prd-start` - Begin implementing a feature
- `/prd-next` - Find next task to work on
- `/prd-update-progress` - Track implementation progress
- `/prd-done` - Complete the workflow (merge, deploy, close)

---

### Step 2: Show Active PRD for Scariest Spider Feature

**Open the demo PRD**:
```bash
# Show prds/demo-scariest-spiders.md
cat prds/demo-scariest-spiders.md
```

**Explain to audience**:
- "We've been working on a new feature: v3 scariest spiders"
- Our developers can create and interface with this via our /prd commands
- This is referred to as "Spec-driven development"
- "The PRD tracked our work from planning through implementation"
- "All milestones are complete"
- "Let's use the platform's `/prd-done` command"

**Show PRD status**:
```markdown
## Milestones

### Milestone 1: Scariest Spider Design
- [x] Created v3 artwork (horror-themed spiders)
- [x] Uploaded v3 artwork to repo
- [x] Added comments to components

### Milestone 2: Implementation Complete
- [x] Updated SpiderImage.jsx with v3 references
- [x] Updated SurpriseSpider.jsx with v3 references
- [x] All local tests passing

### Milestone 3: Add Links
- [x] Add external links
- [x] All local tests passing

### Documentation and Integration
- [x] Documentation updated
- [x] Integration passing

```
(Also add fake work logs, etc, and overall more detail to make it seem real)

---

### Step 3: Execute `/prd-done` Command

**Run the command**:
```bash
# In Claude Code:
/prd-done
```

**What the command does** (AI executes workflow):

1. **Validates PRD completion**:
   - Checks all required milestones are done
   - Confirms implementation is ready

2. **Creates/verifies feature branch**:
   - Branch already exists: `feature/v3-scariest-spiders`
   - All changes committed

3. **Pushes to remote**:
   ```bash
   git push -u origin feature/v3-scariest-spiders
   ```

4. **Creates Pull Request**:
   - Auto-generates PR description from PRD
   - Links to original issue
   - Tags for code review

5. **Waits for CodeRabbit Review**:
   - But for the sake of demo speed (and demoing MCP tool), we will skip this

6. **User Decision**:
   ```
   "Let's merge now and handle any issues as they come up"
   ```

7. **Merges Pull Request**:
   ```bash
   gh pr merge --squash
   ```

8. **Triggers ArgoCD Sync**:
   - GitOps detects main branch update
   - ArgoCD begins syncing v3 deployment
   - "Deployment starting... let's watch on our devices"

**Explain to audience**:
- "The platform enforced our code review process automatically"
- "AI helped us make decisions about what to prioritize"
- "The entire workflow is captured in one command"
- "Now let's see v3 deploy..."

---

### Step 4: Deployment Fails - Enter MCP Tools

**What happens**:
- ArgoCD attempts to deploy v3
- **Deployment fails** (pods stuck in `Pending`)
- App doesn't update on audience devices

**Explain to audience**:
- "Something went wrong with the deployment"
- "This is where MCP tools come in - they give AI deep platform knowledge"
- "Let's diagnose what's happening"

---

### Step 5: Investigate Failure Layer 1 - Node Taints
**Show in terminal/ArgoCD**:
```bash
kubectl get pods -n default
# Shows: Pods stuck in Pending

kubectl describe pod <pod-name> -n default
# Shows: "0/X nodes are available: X node(s) had untolerated taint {demo: scary}"
```

**Use MCP dot-ai for diagnosis**:
```
"The spider-rainbows pods are stuck in Pending state. Can you help me figure out why?"
```

**What MCP dot-ai does**:
- Analyzes pod events
- Identifies taint/toleration mismatch
- Explains the issue
- Suggests fix: remove taint or add toleration

**Fix with AI assistance**:
```
"Can you help me fix the taint issue?"
```

**What AI does**:
- Suggests removing the taint (easiest fix for demo)
- Provides command: `kubectl taint nodes --all demo=scary:NoSchedule-`

**Execute fix**:
```bash
kubectl taint nodes --all demo=scary:NoSchedule-
```

**Explain to audience**:
- Taint prevented pods from scheduling on any nodes
- MCP server helped diagnose the issue
- Removed the taint
- "Now let's see if it works..."

### Step 6: Failure Layer 2 - Resource Over-Allocation
**What happens**:
- Taint removed, but pods still `Pending`

**Check status**:
```bash
kubectl get pods -n default
# Still Pending!

kubectl describe pod <pod-name> -n default
# Shows: "Insufficient memory" or "Insufficient cpu"
```

**Use MCP dot-ai for diagnosis**:
```
"I fixed the taint, but pods are still Pending. What's wrong now?"
```

**What MCP dot-ai does**:
- Analyzes pod events
- Identifies resource requests exceed node capacity
- Shows: requesting 10Gi memory, 4 CPUs
- Suggests fix: reduce resource requests

**Fix with AI assistance**:
```
"Can you help me fix the resource requests in the deployment?"
```

**What AI does**:
- Edits `gitops/manifests/spider-rainbows/deployment.yaml`
- Changes resources back to reasonable values:
  - Memory: `128Mi` → `256Mi`
  - CPU: `100m` → `200m`
- Commits and pushes fix

**Push fix**:
```bash
git push
```

**Wait for ArgoCD sync** (5 seconds)

**Explain to audience**:
- Deployment was requesting 10Gi of memory per pod
- Cluster nodes don't have that much available
- Fixed resource requests to reasonable values
- ArgoCD is syncing the fix...

### Step 7: Failure Layer 3 - Broken Liveness Probe
**What happens**:
- Resources fixed, pods start
- **But**: Pods enter `CrashLoopBackOff`

**Check status**:
```bash
kubectl get pods -n default
# Shows: CrashLoopBackOff

kubectl describe pod <pod-name> -n default
# Shows: Liveness probe failed

kubectl logs <pod-name> -n default
# App logs show it's running fine on port 8080
```

**Use MCP dot-ai for diagnosis**:
```
"The pods are now in CrashLoopBackOff. Can you help me debug this?"
```

**What MCP dot-ai does**:
- Analyzes pod status and events
- Identifies liveness probe failures
- Checks deployment manifest
- Finds: probe checking wrong path `/healthz` (should be `/health`)
- Finds: probe checking wrong port `9090` (should be `8080`)
- Suggests fix: correct probe configuration

**Fix with AI assistance**:
```
"Can you help me fix the liveness probe?"
```

**What AI does**:
- Edits `gitops/manifests/spider-rainbows/deployment.yaml`
- Fixes liveness probe:
  - Path: `/healthz` → `/health`
  - Port: `9090` → `8080`
- Commits and pushes fix

**Push fix**:
```bash
git push
```

**Wait for ArgoCD sync** (5 seconds)

**Explain to audience**:
- Liveness probe was checking wrong endpoint
- App was running fine, but Kubernetes kept killing it
- Fixed the probe configuration
- Now it should work...

### Step 8: Success - V3 Deploys
**What happens**:
- Pods start successfully
- Liveness probes pass
- Pods become `Ready`
- Service routes traffic

**Verify**:
```bash
kubectl get pods -n default
# Shows: Running, Ready 1/1

kubectl get application spider-rainbows -n argocd
# Shows: Synced, Healthy
```

**Show the deployed app**:
- Refresh browser
- Show v3 spiders (OMG SO SCARY)
- Celebrate: "We fixed all three layers of issues!"

**Explain to audience**:
- Cascading failures are realistic in production
- Fix one issue → reveals next issue
- MCP dot-ai helped diagnose each layer
- From broken deployment to working app in ~20 minutes

### Step 9: Wrap Up - Platform Tools Demonstrated

**Explain to audience**:
- "We just demonstrated two types of platform-provided tools"
- **Slash Commands** (`/prd-done`):
  - Discoverable through autocomplete
  - Automate organizational workflows
  - Enforce compliance (code review required)
  - Let AI handle complexity while human makes decisions
- **MCP Tools** (Kubernetes diagnosis):
  - Provide deep platform knowledge to AI
  - Diagnose complex infrastructure issues
  - Help fix cascading failures
  - Make troubleshooting faster and more reliable
- "Both tools work WITH AI, not instead of humans"
- "Platform engineers provide these interfaces - developers discover and use them"
- "This is what modern IDPs look like: AI-augmented, developer-friendly, organizationally compliant"

**Show final result**:
- V3 scariest spiders deployed successfully
- All K8s issues resolved
- PRD complete from planning → implementation → deployment
- Audience can see v3 on their devices

---

## Post-Demo Cleanup

**Optional**: Clean up demo resources

TODO: CREATE A SCRIPT THAT REVERTS BACK TO V1
update ./reset-to-v1

### Destroy Cluster
```bash
./destroy.sh
```

**What this does**:
- Deletes GKE cluster
- Removes all cloud resources
- Cleans up local kubeconfig

---
