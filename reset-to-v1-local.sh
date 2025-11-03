#!/bin/bash
################################################################################
# reset-to-v1-local.sh
#
# PURPOSE:
#   Resets local component files back to v1 baseline state by removing all
#   v2/v3 changes (comments, duplicated code, dead variables, bugs, click handlers).
#
# WHEN TO USE:
#   - During development when testing v1→v2→v1 or v1→v2→v3→v1 transitions
#   - When practicing demo flow and need to reset quickly
#   - Anytime you want to reset files WITHOUT deploying
#
# WHAT IT DOES:
#   - Removes v2/v3 spider anatomy comments from components
#   - Removes v3 click handlers and imports
#   - Removes duplicated calculateSpiderPosition function
#   - Removes dead variables (unusedSpiderCount, spiderAnimationFrame)
#   - Fixes width bug (0.50 → 0.25)
#   - Resets image sources to v1
#   - Removes v3 utility files (clickHandlers.js)
#   - Removes generated PRD files (keeps original PRD-26)
#   - Restores gitops manifests to clean state
#   - Removes K8s node taints (if cluster available)
#   - Verifies reset was successful
#
# WHAT IT DOES NOT DO:
#   - Does NOT build Docker images
#   - Does NOT push to DockerHub
#   - Does NOT commit or push to git
#   - Does NOT trigger ArgoCD deployment
#   - Does NOT delete git branches
#
# USAGE:
#   ./reset-to-v1-local.sh
#
################################################################################

set -euo pipefail

# Cleanup function to remove backup files on error
cleanup() {
  rm -f src/components/*.jsx.bak
  rm -f config.js.bak
}
trap cleanup EXIT

echo "🔄 Resetting local files to v1 baseline..."
echo ""

# ==============================================================================
# Verify we're in the right directory
# ==============================================================================

if [ ! -f "package.json" ] || [ ! -d "src/components" ]; then
  echo "❌ Error: Must run this script from the repository root"
  echo "   Expected to find: package.json and src/components/"
  exit 1
fi

# ==============================================================================
# Verify required files exist
# ==============================================================================

if [ ! -f "src/components/SpiderImage.jsx" ]; then
  echo "❌ Error: src/components/SpiderImage.jsx not found"
  exit 1
fi

if [ ! -f "src/components/SurpriseSpider.jsx" ]; then
  echo "❌ Error: src/components/SurpriseSpider.jsx not found"
  exit 1
fi

# ==============================================================================
# SpiderImage.jsx - Remove v2/v3 changes
# ==============================================================================

# V3 cleanup: Remove click handler import
sed -i.bak '/^import.*clickHandlers.*$/d' src/components/SpiderImage.jsx

# V3 cleanup: Remove click handler function
sed -i.bak '/^  const handleSpiderClick = createClickZoneHandler/,/^  });$/d' src/components/SpiderImage.jsx

# V3 cleanup: Remove horror-themed comments
sed -i.bak '/Wow, our users really like/,/We updated this image to portray the scariest spiders/d' src/components/SpiderImage.jsx

# V3 cleanup: Remove click handler attributes from div
sed -i.bak 's|onClick={handleSpiderClick}||' src/components/SpiderImage.jsx
sed -i.bak "s|style={{ cursor: 'pointer' }}||" src/components/SpiderImage.jsx

# V2 cleanup: Remove calculateSpiderPosition function
sed -i.bak '/^\/\/ Helper function to calculate spider position$/,/^};$/d' src/components/SpiderImage.jsx

# V2 cleanup: Remove blank line after import that was left by function removal
sed -i.bak '2{/^$/d;}' src/components/SpiderImage.jsx

# V2 cleanup: Remove dead variables (unusedSpiderCount and spiderAnimationFrame)
sed -i.bak '/const unusedSpiderCount = 0;/d' src/components/SpiderImage.jsx
sed -i.bak '/let spiderAnimationFrame;/d' src/components/SpiderImage.jsx

# V2 cleanup: Fix width bug (0.50 → 0.25)
sed -i.bak 's|const spiderWidth = rainbowWidth \* 0\.50|const spiderWidth = rainbowWidth * 0.25|' src/components/SpiderImage.jsx

# V2 cleanup: Remove spider anatomy comments
sed -i.bak '/Version one of this drawing is preposterous/,/Teeth\. Ridiculous\./d' src/components/SpiderImage.jsx

# Reset image source to v1
sed -i.bak 's|src="/Spider-v[0-9]*\.png"|src="/Spider-v1.png"|' src/components/SpiderImage.jsx

# Clean up backup files
rm -f src/components/SpiderImage.jsx.bak

# ==============================================================================
# SurpriseSpider.jsx - Remove v2/v3 changes
# ==============================================================================

# V3 cleanup: Remove click handler import
sed -i.bak '/^import.*clickHandlers.*$/d' src/components/SurpriseSpider.jsx

# V3 cleanup: Remove click handler function
sed -i.bak '/^  const handleSpiderClick = createClickZoneHandler/,/^  });$/d' src/components/SurpriseSpider.jsx

# V3 cleanup: Remove horror-themed comments
sed -i.bak '/Following the success/,/even more disturbing than before/d' src/components/SurpriseSpider.jsx

# V3 cleanup: Remove click handler attributes from div
sed -i.bak 's|onClick={handleSpiderClick}||' src/components/SurpriseSpider.jsx
sed -i.bak "s|style={{ cursor: 'pointer' }}||" src/components/SurpriseSpider.jsx

# V2 cleanup: Remove spider anatomy comments
sed -i.bak '/Again, spiders DO NOT HAVE TEETH\./,/They slurp up fly-soup through little mouth-straws!/d' src/components/SurpriseSpider.jsx

# Reset image source to v1
sed -i.bak 's|src="/spidersspidersspiders-v[0-9]*\.png"|src="/spidersspidersspiders-v1.png"|' src/components/SurpriseSpider.jsx

# Clean up backup files
rm -f src/components/SurpriseSpider.jsx.bak

# ==============================================================================
# Remove v2/v3 artifacts
# ==============================================================================

# V3: Remove click handlers utility file
rm -f src/utils/clickHandlers.js

# V3: Remove generated PRD files (keep original PRD-26)
find prds -name "*-v3-horrifying-spider-images.md" ! -name "26-v3-horrifying-spider-images.md" -delete 2>/dev/null || true

# V3: Restore gitops deployment manifest to clean state (undo injected failures)
if [ -f "gitops/manifests/spider-rainbows/deployment.yaml" ]; then
  # Fix resource over-allocation
  sed -i.bak 's|memory: "10Gi"|memory: "128Mi"|' gitops/manifests/spider-rainbows/deployment.yaml
  sed -i.bak 's|cpu: "4000m"|cpu: "100m"|' gitops/manifests/spider-rainbows/deployment.yaml

  # Fix broken liveness probe
  sed -i.bak 's|path: /healthz|path: /health|' gitops/manifests/spider-rainbows/deployment.yaml
  sed -i.bak 's|port: 9090|port: 8080|' gitops/manifests/spider-rainbows/deployment.yaml

  rm -f gitops/manifests/spider-rainbows/deployment.yaml.bak
fi

# V3: Remove K8s node taints (requires cluster authentication)
# Note: This will only work if kubectl is authenticated to the cluster
kubectl taint nodes --all demo=scary:NoSchedule- 2>/dev/null || true

# V2: Remove any config files that may have been created
rm -f config.js

# ==============================================================================
# Verify reset was successful
# ==============================================================================

echo "🔍 Verifying reset..."

# Check SpiderImage.jsx
if grep -q "Spider-v1.png" src/components/SpiderImage.jsx && \
   grep -q "rainbowWidth \* 0.25" src/components/SpiderImage.jsx && \
   ! grep -q "calculateSpiderPosition" src/components/SpiderImage.jsx && \
   ! grep -q "unusedSpiderCount" src/components/SpiderImage.jsx && \
   ! grep -q "Version one of this drawing" src/components/SpiderImage.jsx; then
  echo "  ✅ SpiderImage.jsx reset to v1"
else
  echo "  ❌ SpiderImage.jsx may not be at v1"
  exit 1
fi

# Check SurpriseSpider.jsx
if grep -q "spidersspidersspiders-v1.png" src/components/SurpriseSpider.jsx && \
   ! grep -q "spiders DO NOT HAVE TEETH" src/components/SurpriseSpider.jsx; then
  echo "  ✅ SurpriseSpider.jsx reset to v1"
else
  echo "  ❌ SurpriseSpider.jsx may not be at v1"
  exit 1
fi

echo ""
echo "✅ Local files reset to v1 baseline!"
echo ""
echo "NOTE: This was a LOCAL reset only."
echo "      No Docker build, git commit, or deployment occurred."
echo ""
