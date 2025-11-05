#!/bin/bash
################################################################################
# reset-to-v1-local.sh
#
# PURPOSE:
#   Resets local component files back to v1 baseline by copying from
#   .baseline/v1/ directory.
#
# WHAT IT DOES:
#   - Copies clean v1 files from .baseline/v1/
#   - Removes v3 artifacts (clickHandlers.js, generated PRDs)
#   - Restores gitops deployment manifest
#   - Removes K8s node taints
#
# USAGE:
#   ./reset-to-v1-local.sh
#
################################################################################

set -euo pipefail

# Add Google Cloud SDK to PATH for gke-gcloud-auth-plugin
# This ensures kubectl can authenticate to GKE clusters in all execution contexts
GCLOUD_SDK_ROOT=$(gcloud info --format="value(installation.sdk_root)" 2>/dev/null || echo "")
if [ -n "$GCLOUD_SDK_ROOT" ] && [ -d "$GCLOUD_SDK_ROOT/bin" ]; then
  export PATH="$GCLOUD_SDK_ROOT/bin:$PATH"
fi

echo "🔄 Resetting to v1 baseline..."

# ==============================================================================
# Verify baseline directory exists
# ==============================================================================

if [ ! -d ".baseline/v1/src/components" ]; then
  echo "❌ Error: .baseline/v1/src/components/ directory not found"
  exit 1
fi

# ==============================================================================
# Switch to main and clean up feature branch FIRST
# ==============================================================================
# IMPORTANT: We must switch to main and clean git state BEFORE doing filesystem
# operations, otherwise git operations will undo our filesystem changes

V2_BRANCH="feature/no-spider-teeth"
V3_BRANCH="feature/v3-scariest-spiders"
CURRENT_BRANCH=$(git branch --show-current)

# Extract issue number from PRD file BEFORE git clean deletes it
V3_ISSUE_NUMBER=""
V3_PRD_FILE=$(find prds -name "*-v3-horrifying-spider-images.md" ! -name "26-v3-horrifying-spider-images.md" 2>/dev/null | head -1)
if [ -n "$V3_PRD_FILE" ]; then
  V3_ISSUE_NUMBER=$(basename "$V3_PRD_FILE" | grep -oE '^[0-9]+')
fi

# Handle v2 or v3 feature branches
if [ "$CURRENT_BRANCH" = "$V2_BRANCH" ] || [ "$CURRENT_BRANCH" = "$V3_BRANCH" ]; then
  echo "  Switching from feature branch to main..."
  # Clean up git state on feature branch (unstage + discard all changes)
  # WARNING: git clean will delete the PRD file, so we extracted issue number above
  git reset HEAD . 2>/dev/null || true
  git checkout . 2>/dev/null || true
  git clean -fd 2>/dev/null || true
  # Switch to main
  git checkout main 2>/dev/null || git checkout master 2>/dev/null
fi

# Delete feature branches if they exist
if git show-ref --verify --quiet "refs/heads/$V2_BRANCH"; then
  echo "  Deleting branch $V2_BRANCH..."
  git branch -D "$V2_BRANCH" 2>/dev/null || true
fi
if git show-ref --verify --quiet "refs/heads/$V3_BRANCH"; then
  echo "  Deleting branch $V3_BRANCH..."
  git branch -D "$V3_BRANCH" 2>/dev/null || true
fi

# ==============================================================================
# Copy clean v1 files from baseline (now that we're on main)
# ==============================================================================

cp .baseline/v1/src/components/SpiderImage.jsx src/components/SpiderImage.jsx
cp .baseline/v1/src/components/SurpriseSpider.jsx src/components/SurpriseSpider.jsx

# ==============================================================================
# Remove v3 artifacts
# ==============================================================================

# Remove v3 utility file
rm -f src/utils/clickHandlers.js

# Clean up v3 GitHub issue (using issue number extracted earlier)
if [ -n "$V3_ISSUE_NUMBER" ] && gh issue view "$V3_ISSUE_NUMBER" &>/dev/null; then
  echo "  Cleaning up GitHub issue #$V3_ISSUE_NUMBER..."
  gh issue close "$V3_ISSUE_NUMBER" --reason "not planned" 2>/dev/null || true
  gh issue delete "$V3_ISSUE_NUMBER" --yes 2>/dev/null || true
fi

# Remove generated v3 PRD files (keep original PRD-26)
# Note: This may have already been done by git clean, but we run it again to be thorough
find prds -name "*-v3-horrifying-spider-images.md" ! -name "26-v3-horrifying-spider-images.md" -delete 2>/dev/null || true

# Remove K8s node taints (graceful failure if cluster unavailable)
kubectl taint nodes --all demo=scary:NoSchedule- 2>/dev/null || true

# Remove tolerations from deployment (graceful failure if cluster unavailable)
kubectl patch deployment spider-rainbows -n default --type=json -p='[{"op": "remove", "path": "/spec/template/spec/tolerations"}]' 2>/dev/null || true

# ==============================================================================
# Verify reset
# ==============================================================================

if grep -q "Spider-v1.png" src/components/SpiderImage.jsx && \
   grep -q "spidersspidersspiders-v1.png" src/components/SurpriseSpider.jsx; then
  echo "✅ Reset to v1 complete!"
else
  echo "❌ Reset verification failed"
  exit 1
fi
