#!/bin/bash
set -euo pipefail

echo "🔄 Resetting to baseline..."
echo ""

# Update SpiderImage.jsx back to v1
sed -i.bak 's|src="/Spider[^"]*"|src="/Spider-v1.png"|' src/components/SpiderImage.jsx
rm src/components/SpiderImage.jsx.bak

# Fix spider width back to correct value
sed -i.bak 's|const spiderWidth = rainbowWidth \* 0.50|const spiderWidth = rainbowWidth * 0.25|' src/components/SpiderImage.jsx
rm src/components/SpiderImage.jsx.bak

# Update SurpriseSpider.jsx back to v1
sed -i.bak 's|src="/spidersspidersspiders[^"]*"|src="/spidersspidersspiders-v1.png"|' src/components/SurpriseSpider.jsx
rm src/components/SurpriseSpider.jsx.bak

echo "✅ Local files reset to v1"
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
