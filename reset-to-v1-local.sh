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

echo "🔄 Resetting to v1 baseline..."

# ==============================================================================
# Verify baseline directory exists
# ==============================================================================

if [ ! -d ".baseline/v1/src/components" ]; then
  echo "❌ Error: .baseline/v1/src/components/ directory not found"
  exit 1
fi

# ==============================================================================
# Copy clean v1 files from baseline
# ==============================================================================

cp .baseline/v1/src/components/SpiderImage.jsx src/components/SpiderImage.jsx
cp .baseline/v1/src/components/SurpriseSpider.jsx src/components/SurpriseSpider.jsx

# ==============================================================================
# Remove v3 artifacts
# ==============================================================================

# Remove v3 utility file
rm -f src/utils/clickHandlers.js

# Find and clean up v3 GitHub issue (extract number from PRD filename)
# The develop-next-version.sh script creates a PRD file like "prds/35-v3-horrifying-spider-images.md"
# We extract the issue number from any such file and clean up the corresponding GitHub issue
V3_PRD_FILE=$(find prds -name "*-v3-horrifying-spider-images.md" ! -name "26-v3-horrifying-spider-images.md" 2>/dev/null | head -1)
if [ -n "$V3_PRD_FILE" ]; then
  # Extract issue number from filename (e.g., "prds/35-v3-horrifying-spider-images.md" -> "35")
  V3_ISSUE_NUMBER=$(basename "$V3_PRD_FILE" | grep -oE '^[0-9]+')
  if [ -n "$V3_ISSUE_NUMBER" ] && gh issue view "$V3_ISSUE_NUMBER" &>/dev/null; then
    echo "  Cleaning up GitHub issue #$V3_ISSUE_NUMBER..."
    gh issue close "$V3_ISSUE_NUMBER" --reason "not planned" 2>/dev/null || true
    gh issue delete "$V3_ISSUE_NUMBER" --yes 2>/dev/null || true
  fi
fi

# Remove generated v3 PRD files (keep original PRD-26)
find prds -name "*-v3-horrifying-spider-images.md" ! -name "26-v3-horrifying-spider-images.md" -delete 2>/dev/null || true

# Delete v3 feature branch if it exists
# Branch name is hardcoded to match what develop-next-version.sh creates (line 193)
# This is safe because the branch name is consistent and predictable
V3_BRANCH="feature/v3-scariest-spiders"
if git show-ref --verify --quiet "refs/heads/$V3_BRANCH"; then
  echo "  Deleting branch $V3_BRANCH..."
  CURRENT_BRANCH=$(git branch --show-current)
  if [ "$CURRENT_BRANCH" = "$V3_BRANCH" ]; then
    git checkout main 2>/dev/null || git checkout master 2>/dev/null
  fi
  git branch -D "$V3_BRANCH" 2>/dev/null || true
fi

# Restore deployment manifest (undo K8s failures)
if [ -f "gitops/manifests/spider-rainbows/deployment.yaml" ]; then
  sed -i.bak 's|memory: "10Gi"|memory: "128Mi"|' gitops/manifests/spider-rainbows/deployment.yaml
  sed -i.bak 's|cpu: "4000m"|cpu: "100m"|' gitops/manifests/spider-rainbows/deployment.yaml
  sed -i.bak 's|path: /healthz|path: /health|' gitops/manifests/spider-rainbows/deployment.yaml
  sed -i.bak 's|port: 9090|port: 8080|' gitops/manifests/spider-rainbows/deployment.yaml
  rm -f gitops/manifests/spider-rainbows/deployment.yaml.bak
fi

# Remove K8s node taints (graceful failure if cluster unavailable)
kubectl taint nodes --all demo=scary:NoSchedule- 2>/dev/null || true

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
