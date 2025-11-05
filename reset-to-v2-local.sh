#!/bin/bash
################################################################################
# reset-to-v2-local.sh
#
# PURPOSE:
#   Resets local component files back to clean v2 baseline.
#
# WHAT IT DOES:
#   - Calls reset-to-v1-local.sh to get clean v1 baseline
#   - Updates image sources from v1 to v2
#   - Verifies the result
#
# USAGE:
#   ./reset-to-v2-local.sh
#
################################################################################

set -euo pipefail

echo "🔄 Resetting to v2 baseline..."

# ==============================================================================
# Step 1: Reset to v1 baseline
# ==============================================================================

echo "Step 1: Resetting to v1 baseline..."
if [ -f "./reset-to-v1-local.sh" ]; then
  ./reset-to-v1-local.sh
else
  echo "❌ Error: reset-to-v1-local.sh not found"
  exit 1
fi

# ==============================================================================
# Step 2: Update images to v2
# ==============================================================================

echo "Step 2: Updating to v2 images..."

# Verify v2 image files exist before updating references
if [ ! -f "public/Spider-v2.png" ]; then
  echo "❌ Error: Spider-v2.png not found in public directory"
  exit 1
fi

if [ ! -f "public/spidersspidersspiders-v2.png" ]; then
  echo "❌ Error: spidersspidersspiders-v2.png not found in public directory"
  exit 1
fi

# Update SpiderImage.jsx
sed -i.bak 's|src="/Spider-v1\.png"|src="/Spider-v2.png"|' src/components/SpiderImage.jsx
rm src/components/SpiderImage.jsx.bak

# Update SurpriseSpider.jsx
sed -i.bak 's|src="/spidersspidersspiders-v1\.png"|src="/spidersspidersspiders-v2.png"|' src/components/SurpriseSpider.jsx
rm src/components/SurpriseSpider.jsx.bak

# ==============================================================================
# Verify reset
# ==============================================================================

if grep -q "Spider-v2.png" src/components/SpiderImage.jsx && \
   grep -q "spidersspidersspiders-v2.png" src/components/SurpriseSpider.jsx; then
  echo "✅ Reset to v2 complete!"
else
  echo "❌ Reset verification failed"
  exit 1
fi
