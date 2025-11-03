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

# Remove generated v3 PRD files (keep original PRD-26)
find prds -name "*-v3-horrifying-spider-images.md" ! -name "26-v3-horrifying-spider-images.md" -delete 2>/dev/null || true

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
