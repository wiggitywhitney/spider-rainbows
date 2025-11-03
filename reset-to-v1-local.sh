#!/bin/bash
################################################################################
# reset-to-v1-local.sh
#
# PURPOSE:
#   Resets local component files back to v1 baseline state by removing all
#   v2/v3 changes (comments, duplicated code, dead variables, bugs).
#
# WHEN TO USE:
#   - During development when testing v1→v2→v1 transitions
#   - When practicing demo flow and need to reset quickly
#   - Anytime you want to reset files WITHOUT deploying
#
# WHAT IT DOES:
#   - Removes v2/v3 spider anatomy comments from components
#   - Removes duplicated calculateSpiderPosition function
#   - Removes dead variables (unusedSpiderCount, spiderAnimationFrame)
#   - Fixes width bug (0.50 → 0.25)
#   - Resets image sources to v1
#   - Removes any v2/v3 artifact files (config.js)
#   - Verifies reset was successful
#
# WHAT IT DOES NOT DO:
#   - Does NOT build Docker images
#   - Does NOT push to DockerHub
#   - Does NOT commit or push to git
#   - Does NOT trigger ArgoCD deployment
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

# 1. Remove calculateSpiderPosition function (lines 3-7)
sed -i.bak '/^\/\/ Helper function to calculate spider position$/,/^};$/d' src/components/SpiderImage.jsx

# 2. Remove blank line after import that was left by function removal
sed -i.bak '2{/^$/d;}' src/components/SpiderImage.jsx

# 3. Remove dead variables (unusedSpiderCount and spiderAnimationFrame)
sed -i.bak '/const unusedSpiderCount = 0;/d' src/components/SpiderImage.jsx
sed -i.bak '/let spiderAnimationFrame;/d' src/components/SpiderImage.jsx

# 4. Fix width bug (0.50 → 0.25)
sed -i.bak 's|const spiderWidth = rainbowWidth \* 0\.50|const spiderWidth = rainbowWidth * 0.25|' src/components/SpiderImage.jsx

# 5. Remove spider anatomy comments (all comment lines before <img)
sed -i.bak '/Version one of this drawing is preposterous/,/Teeth\. Ridiculous\./d' src/components/SpiderImage.jsx

# 6. Update image source to v1
sed -i.bak 's|src="/Spider-v[0-9]*\.png"|src="/Spider-v1.png"|' src/components/SpiderImage.jsx

# Clean up backup files
rm -f src/components/SpiderImage.jsx.bak

# ==============================================================================
# SurpriseSpider.jsx - Remove v2/v3 changes
# ==============================================================================

# 1. Remove spider anatomy comments (lines 10-11)
sed -i.bak '/Again, spiders DO NOT HAVE TEETH\./,/They slurp up fly-soup through little mouth-straws!/d' src/components/SurpriseSpider.jsx

# 2. Update image source to v1
sed -i.bak 's|src="/spidersspidersspiders-v[0-9]*\.png"|src="/spidersspidersspiders-v1.png"|' src/components/SurpriseSpider.jsx

# Clean up backup files
rm -f src/components/SurpriseSpider.jsx.bak

# ==============================================================================
# Remove v2/v3 artifacts
# ==============================================================================

# Remove any config files that may have been created
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
