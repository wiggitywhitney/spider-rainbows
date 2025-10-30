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

# Update GitOps repository
echo "📝 Updating GitOps repository..."
GITOPS_REPO="spider-rainbows-platform-config"
GITOPS_TOKEN="${GITOPS_REPO_TOKEN:-}"

if [ -z "$GITOPS_TOKEN" ]; then
  echo "⚠️  GITOPS_REPO_TOKEN not set. Skipping GitOps repo update."
  echo "To update the GitOps repo manually, set GITOPS_REPO_TOKEN environment variable."
else
  # Create temp directory and ensure cleanup
  TEMP_DIR=$(mktemp -d)
  trap "rm -rf $TEMP_DIR" EXIT

  # Clone GitOps repository to temp directory
  git clone https://x-access-token:${GITOPS_TOKEN}@github.com/wiggitywhitney/${GITOPS_REPO}.git "$TEMP_DIR/gitops-repo"
  cd "$TEMP_DIR/gitops-repo"

  # Configure git
  git config user.name "spider-rainbows-reset"
  git config user.email "reset@spider-rainbows.local"

  # Update deployment.yaml with v1-baseline image and imagePullPolicy: Always
  sed -i.bak 's|image: wiggitywhitney/spider-rainbows:.*|image: wiggitywhitney/spider-rainbows:v1-baseline|' spider-rainbows/deployment.yaml
  sed -i.bak '/image: wiggitywhitney\/spider-rainbows:v1-baseline/a\          imagePullPolicy: Always' spider-rainbows/deployment.yaml
  rm spider-rainbows/deployment.yaml.bak

  # Commit and push
  git add spider-rainbows/deployment.yaml
  git commit -m "chore: reset to v1-baseline image for demo initialization"
  git push origin main

  # Return to original directory (trap handles cleanup)
  cd -

  echo "✅ GitOps repository updated"
fi

echo ""
echo "✅ Reset to v1 complete!"
echo "   Docker image: wiggitywhitney/spider-rainbows:v1-baseline"
echo "   Ready for setup-platform.sh to deploy"
