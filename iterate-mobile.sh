#!/bin/bash
set -euo pipefail

# Quick iteration script for mobile CSS testing
# Usage: ./iterate-mobile.sh [optional-tag-suffix]

BRANCH="feature/prd-23-mobile-support-conference-demo"
IMAGE_BASE="wiggitywhitney/spider-rainbows"
# Always use unique timestamp-based tag to avoid caching issues
TAG_SUFFIX="$(date +%Y%m%d-%H%M%S)"
IMAGE_TAG="prd-23-${TAG_SUFFIX}"
FULL_IMAGE="${IMAGE_BASE}:${IMAGE_TAG}"

echo "🔨 Building and deploying mobile CSS iteration..."
echo "   Image: ${FULL_IMAGE}"
echo ""

# Check if on correct branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "$BRANCH" ]; then
    echo "⚠️  Warning: Not on feature branch (current: $CURRENT_BRANCH)"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Build and push multi-platform image
echo "🐳 Building multi-platform Docker image (amd64 + arm64)..."
docker buildx build --platform linux/amd64,linux/arm64 -t "${FULL_IMAGE}" --push .

# Update deployment manifest
echo "📝 Updating deployment.yaml..."
sed -i.bak "s|image: ${IMAGE_BASE}:.*|image: ${FULL_IMAGE}|g" gitops/manifests/spider-rainbows/deployment.yaml
rm gitops/manifests/spider-rainbows/deployment.yaml.bak

# Show the change
echo "✓ Updated image tag:"
grep "image:" gitops/manifests/spider-rainbows/deployment.yaml

# Commit and push
echo "📤 Committing and pushing to ${BRANCH}..."
git add gitops/manifests/spider-rainbows/deployment.yaml
git commit -m "test: update image to ${IMAGE_TAG} for mobile CSS iteration

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

git push origin "${BRANCH}"

echo ""
echo "✅ Done! ArgoCD should sync in ~30 seconds"
echo "   Watch with: kubectl get pods -w"
echo ""
echo "🌐 Once deployed, get the URL with:"
echo "   kubectl get ingress"
echo ""
