#!/bin/bash
set -euo pipefail

echo "🔄 Resetting to baseline..."
echo ""

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
fi

# Check SurpriseSpider.jsx
if grep -q "spidersspidersspiders-v1.png" src/components/SurpriseSpider.jsx && \
   ! grep -q "spiders DO NOT HAVE TEETH" src/components/SurpriseSpider.jsx; then
  echo "  ✅ SurpriseSpider.jsx reset to v1"
else
  echo "  ❌ SurpriseSpider.jsx may not be at v1"
fi

echo ""

# Build Docker image
echo "🐳 Building Docker image..."
docker build -t wiggitywhitney/spider-rainbows:v1-baseline .

# Push to DockerHub
echo "📤 Pushing to DockerHub..."
docker push wiggitywhitney/spider-rainbows:v1-baseline

echo "✅ Docker image built and pushed: wiggitywhitney/spider-rainbows:v1-baseline"
echo ""

echo ""
echo "📤 Committing and pushing to trigger GitHub Actions..."
git add .
git commit --allow-empty -m "chore: trigger workflow - deploy v1-baseline image"
git push origin main

echo ""
echo "✅ Reset to v1 complete!"
echo "   Docker image: wiggitywhitney/spider-rainbows:v1-baseline"
echo ""
echo "GitHub Actions workflow will now:"
echo "  1. Update GitOps repo with v1-baseline image"
echo "  2. ArgoCD will sync and deploy v1 spiders"
