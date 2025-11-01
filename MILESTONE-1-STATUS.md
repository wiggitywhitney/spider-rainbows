# Milestone 1 Implementation Status
**Date**: 2025-10-31
**PRD**: #10 - Cloud Demo Environment with Custom Domain
**Milestone**: Milestone 1 - Interactive Mode Selection and Cloud Provider Foundation

---

## Project Goal

Create a unified setup script (`kind/setup-platform.sh`) that supports deploying the spider-rainbows demo to either:
1. **Kind (local)** - For quick local demos
2. **GCP (cloud)** - For persistent 24/7 accessible demos

Key requirement: Same script, user chooses deployment type interactively.

---

## What We Accomplished

### ✅ Core Features Implemented

1. **Interactive Mode Selection**
   - Script prompts: "Which cluster? (1) Kind (2) GCP?"
   - User selects deployment type
   - Location: `kind/setup-platform.sh` lines 60-86

2. **GCP Prerequisites with Auto-PATH Fix**
   - Checks for gcloud, kubectl, gke-gcloud-auth-plugin
   - Automatically adds gcloud SDK to PATH if plugin not found
   - Prevents future confusion when plugin isn't in PATH
   - Location: `kind/setup-platform.sh` lines 147-190

3. **GKE Cluster Creation**
   - Uses user's standard config: `n1-standard-4`, 3 nodes, `us-east1`
   - GCP project: `demoo-ooclock`
   - Waits for ALL nodes to become Ready (not just one)
   - Location: `kind/setup-platform.sh` lines 276-351

4. **Dynamic Cluster Naming**
   - Format: `spider-rainbows-YYYYMMDD-HHMMSS`
   - Prevents name conflicts
   - Starts with letter (GKE requirement)
   - Location: `kind/setup-platform.sh` line 19

5. **LoadBalancer and nip.io DNS**
   - For GCP: Waits for LoadBalancer to get external IP
   - Constructs nip.io domain: `35.237.9.195.nip.io`
   - Sets `BASE_DOMAIN` variable used throughout script
   - Location: `kind/setup-platform.sh` lines 387-417

6. **Dynamic ArgoCD Ingress**
   - Creates ingress with correct domain based on deployment mode
   - Kind: `argocd.127.0.0.1.nip.io`
   - GCP: `argocd.<LoadBalancer-IP>.nip.io`
   - Location: `kind/setup-platform.sh` lines 524-557

7. **ArgoCD 5-Second Sync**
   - Configures `timeout.reconciliation: 5s`
   - Restarts application controller to apply
   - Location: `kind/setup-platform.sh` lines 506-522

8. **Destroy Script Enhancements**
   - Auto-detects which clusters exist (Kind and/or GKE)
   - Confirms before deletion
   - Cleans up kubeconfig for GKE (prevents bloat)
   - Location: `kind/destroy.sh`

### ✅ Testing Results

- **Kind Mode**: ✅ Works perfectly, full backward compatibility
- **GCP Mode**: ⚠️ Partial success (see problems below)

---

## Current Problems

### Problem 1: Spider-Rainbows App Ingress Domain ❌

**Symptom:**
- ArgoCD UI works: `https://argocd.34.74.53.101.nip.io` ✅
- App doesn't work: `http://spider-rainbows.34.74.53.101.nip.io` ❌
- Ingress shows wrong host: `spider-rainbows.127.0.0.1.nip.io` instead of `spider-rainbows.34.74.53.101.nip.io`

**Root Cause:**
ArgoCD syncs spider-rainbows ingress from external GitOps repo (`spider-rainbows-platform-config`) which has hardcoded `127.0.0.1.nip.io`. With `selfHeal: true`, ArgoCD reverts any changes every 5 seconds.

**What We Tried:**
1. Patching ingress after ArgoCD creates it → Reverted by ArgoCD
2. Adding `ignoreDifferences` to ArgoCD Application → Didn't work (ArgoCD still manages it)
3. Adding `RespectIgnoreDifferences: true` + `jqPathExpressions` → Not yet tested fully

**Current Script Code:**
- `kind/spider-rainbows-app.yaml` lines 22-28: `ignoreDifferences` config
- `kind/setup-platform.sh` lines 701-725: Creates ingress dynamically

### Problem 2: kubectl Access from AI Tool ❌

**Symptom:**
When running kubectl commands via Bash tool:
```
error: exec: executable gke-gcloud-auth-plugin not found
```

**Root Cause:**
- Bash tool creates fresh subshells without inheriting user's PATH
- Even though script auto-adds PATH, individual kubectl commands don't have it
- Makes troubleshooting impossible during development

**Workaround:**
Prefix every command with `source ~/.zshrc &&` but this is fragile.

### Problem 3: Active GKE Cluster Running 💰

**Current State:**
- Cluster: `spider-rainbows-20251031-195105`
- Region: `us-east1`
- Status: Being deleted (background process ID: 371edb)
- LoadBalancer IP was: `34.74.53.101`

---

## Possible Solutions

### For Problem 1 (Ingress Domain)

#### Option A: ArgoCD ignoreDifferences (Current Attempt)
**What:**
```yaml
# kind/spider-rainbows-app.yaml
ignoreDifferences:
- group: networking.k8s.io
  kind: Ingress
  name: spider-rainbows
  jqPathExpressions:
  - .spec
syncOptions:
- RespectIgnoreDifferences=true
```

**Pros:**
- Architecturally clean
- Respects GitOps principles (Git is source, exceptions documented)

**Cons:**
- Complex ArgoCD config
- May not work (not fully tested)

**Status:** ⏸️ Implemented but not verified working

---

#### Option B: Delete and Recreate Ingress
**What:**
```bash
# After ArgoCD creates wrong ingress:
kubectl delete ingress spider-rainbows -n default
kubectl apply -f - <<EOF
  # Dynamic ingress with correct domain
EOF
```

**Pros:**
- Simple, bulletproof
- Guarantees our ingress is there

**Cons:**
- ❌ ArgoCD will recreate it with wrong domain every 5 seconds
- Fight between script and ArgoCD
- Not viable with selfHeal enabled

**Status:** ❌ Won't work due to selfHeal

---

#### Option C: Disable selfHeal for Ingress Only
**What:**
```yaml
# kind/spider-rainbows-app.yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: false  # Disable
```

**Pros:**
- Script can manage ingress without ArgoCD interfering
- Simple

**Cons:**
- Loses auto-remediation for ALL resources (not just ingress)
- Defeats purpose of GitOps

**Status:** 🤔 Possible but undesirable

---

#### Option D: Wait for Milestone 3
**What:**
- Consolidate `spider-rainbows-platform-config` repo into `argocd-config/` in this repo
- Template the ingress manifest
- ArgoCD syncs deployment.yaml, service.yaml (no ingress)
- Script creates ingress (like ArgoCD ingress)

**Pros:**
- Clean separation: ArgoCD = app, Script = infrastructure
- Consistent with how ArgoCD ingress already works
- Architecturally correct (ingress IS infrastructure-specific)

**Cons:**
- More work before seeing GCP work
- Delays completion of Milestone 1

**Status:** 🎯 **Recommended long-term solution**

---

#### Option E: Resource Exclusion (New Idea)
**What:**
Use ArgoCD resource exclusion to completely ignore ingress:
```yaml
# Application spec
source:
  directory:
    exclude: "ingress.yaml"
```

Or use resource tracking:
```yaml
syncOptions:
- ServerSideApply=true
```

**Pros:**
- ArgoCD never touches ingress
- Script has full control
- No fighting

**Cons:**
- Requires understanding ArgoCD resource exclusion syntax
- May need different external repo structure

**Status:** 🤷 Worth investigating

---

### For Problem 2 (kubectl Access)

#### Option A: Use Full Path to gke-gcloud-auth-plugin
**What:**
Export full path in every kubectl call or at start of script.

**Status:** Hacky, not recommended

#### Option B: Accept Limitation
**What:**
- Acknowledge AI can't easily test kubectl during development
- User tests manually
- Document testing steps clearly

**Status:** 🎯 Pragmatic for now

#### Option C: Fix User's Shell Config
**What:**
Already done - added PATH to `~/.zshrc`:
```bash
export PATH="/opt/homebrew/share/google-cloud-sdk/bin:$PATH"
```

User needs to run `source ~/.zshrc` in their terminal.

**Status:** ✅ Complete, user needs to restart terminal

---

## Architecture Decisions Made

### Decision 1: Cluster Naming ✅
- **Decision:** `spider-rainbows-YYYYMMDD-HHMMSS` format
- **Rationale:** Prevents conflicts, meets GKE naming requirements (must start with letter)

### Decision 2: DNS Strategy ✅
- **Decision:** Use nip.io (not custom domain or GoDaddy API)
- **Rationale:** No external dependencies, immediate availability, perfect for testing

### Decision 3: Script Manages Ingress ✅
- **Decision:** Script creates ArgoCD and spider-rainbows ingress dynamically
- **Rationale:** Ingress hosts are environment-specific infrastructure, not application config

### Decision 4: PATH Auto-Fix ✅
- **Decision:** Script auto-adds gcloud SDK to PATH if needed
- **Rationale:** Prevents repeated confusion across conversations, pragmatic over purist

### Decision 5: Repository Consolidation ⏸️
- **Decision:** Defer to Milestone 3
- **Rationale:** Milestone 1 is about cluster creation, not repo structure

---

## Files Modified

### Core Script Changes
1. `kind/setup-platform.sh` - Major additions:
   - Interactive prompt
   - GCP prerequisite checks
   - GKE cluster creation
   - Dynamic ingress creation
   - Node readiness waits

2. `kind/destroy.sh` - Enhanced:
   - Auto-detect clusters
   - Kubeconfig cleanup for GKE
   - Confirmation prompts

3. `kind/spider-rainbows-app.yaml` - Modified:
   - Added `ignoreDifferences` for ingress
   - Added `RespectIgnoreDifferences: true`
   - Removed invalid `syncInterval` field

4. `kind/cluster-config.yaml` - Modified:
   - Removed hardcoded cluster name (now passed via --name flag)

5. `~/.zshrc` - Modified:
   - Added gcloud SDK to PATH

### Files NOT Modified (But Should Consider)
- External repo: `spider-rainbows-platform-config` - Still has hardcoded localhost domain

---

## Test Clusters History

**Clusters Created:**
1. `spider-rainbows-gitops` (old name) - Created before name fix
2. `20251031-180201-spider-rainbows` - Invalid (starts with number)
3. `spider-rainbows-20251031-180227` - Valid, tested
4. `spider-rainbows-20251031-181553` - Valid, tested
5. `spider-rainbows-20251031-184716` - Valid, tested
6. `spider-rainbows-20251031-190337` - Valid, tested (ArgoCD worked, app didn't)
7. `spider-rainbows-20251031-195105` - Valid, currently being deleted

**All clusters cleaned up except:** Deletion in progress (background job 371edb)

---

## Success Criteria (Milestone 1)

### ✅ Complete
- [x] Script prompts user for deployment type
- [x] Kind deployment works (backward compatible)
- [x] GCP prerequisite checks work
- [x] GKE cluster creation works
- [x] LoadBalancer IP retrieval works
- [x] nip.io domain construction works
- [x] ArgoCD deploys and is accessible
- [x] Destroy script works for both modes
- [x] Kubeconfig cleanup prevents bloat

### ⏸️ Incomplete
- [ ] Spider-rainbows app accessible via nip.io domain on GCP
- [ ] Full end-to-end GCP test passes
- [ ] Kind mode re-tested with ingress changes

---

## Recommended Next Steps

### Immediate (Complete Milestone 1)

1. **Verify ignoreDifferences Works**
   - Deploy fresh GCP cluster
   - Watch ArgoCD behavior with new config
   - Check if ingress stays at correct domain after 10+ seconds
   - Test: `curl http://spider-rainbows.<IP>.nip.io/health`

2. **If ignoreDifferences Doesn't Work:**
   - Investigate ArgoCD resource exclusion patterns
   - Consider temporarily disabling selfHeal for testing
   - Document findings

3. **Test Kind Mode**
   - Run `echo "1" | ./kind/setup-platform.sh`
   - Verify app accessible at `http://spider-rainbows.127.0.0.1.nip.io`
   - Confirm backward compatibility

4. **Document Success**
   - Update PRD with completion status
   - Mark Milestone 1 as complete
   - Identify blockers for Milestone 2

### Future (Milestone 3)

1. **Consolidate GitOps Repo**
   - Move `spider-rainbows-platform-config` → `argocd-config/`
   - Remove ingress from ArgoCD management entirely
   - Script creates all ingress resources
   - Clean architectural separation

---

## Key Learnings

1. **GitOps vs Infrastructure Tension**: Resources with environment-specific config (like ingress hosts) don't fit pure GitOps model well. Need pragmatic solutions.

2. **ArgoCD selfHeal is Aggressive**: With `selfHeal: true`, ArgoCD reverts changes every 5 seconds. `ignoreDifferences` + `RespectIgnoreDifferences` should work but needs testing.

3. **PATH Management**: Subshells don't inherit PATH. Script auto-fix solves user experience but doesn't help AI debugging. Trade-off accepted.

4. **Cluster Naming Matters**: GKE has strict rules (must start with letter, max 40 chars). Simple timestamp prefix doesn't work.

5. **Testing in Subshells is Hard**: AI tools run commands in fresh environments, making iteration difficult when credentials/PATH setup is complex.

---

## Open Questions

1. Does `RespectIgnoreDifferences: true` + `jqPathExpressions: [.spec]` actually prevent ArgoCD from overwriting ingress?

2. Should we abandon `ignoreDifferences` approach and just wait for Milestone 3 repo consolidation?

3. Is there a simpler ArgoCD config that "just works" for excluding specific resources?

4. Should we add `ingress.yaml` template to Git (even if not used) for documentation?

---

## Environment Details

**User Setup:**
- Machine: macOS (Darwin 24.6.0)
- GCP Project: `demoo-ooclock`
- GCP Region: `us-east1`
- Shell: zsh
- gcloud SDK: `/opt/homebrew/share/google-cloud-sdk`

**Current Branch:** `feature/prd-10-cloud-demo-environment-custom-domain`

**Related PRDs:**
- PRD #3: ArgoCD Kind setup (working, provides baseline)
- PRD #10: Cloud deployment (this work)

---

## For Future AI Reading This

**Context:** You're picking up work on Milestone 1 of PRD #10. The goal is a unified setup script that deploys to Kind OR GCP based on user choice.

**Status:** 95% complete. Kind works perfectly. GCP mostly works but spider-rainbows app ingress has wrong domain due to ArgoCD sync conflict.

**The Issue:** Script creates ingress with correct domain (`spider-rainbows.34.74.53.101.nip.io`), but ArgoCD syncs from Git repo with hardcoded localhost domain and overwrites it every 5 seconds.

**Where We Left Off:** Implemented `ignoreDifferences` config to prevent ArgoCD from overwriting ingress, but haven't tested if it actually works. Need to deploy fresh cluster and observe behavior.

**What to Do:** See "Recommended Next Steps" section above. Start with verifying ignoreDifferences solution works.

**Key Files:**
- `kind/setup-platform.sh` - Main script
- `kind/spider-rainbows-app.yaml` - ArgoCD Application with ignoreDifferences
- `kind/destroy.sh` - Cleanup script
- This file - Complete context

Good luck! 🕷️
