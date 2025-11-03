#!/bin/bash
################################################################################
# reset-to-v1-and-deploy.sh
#
# PURPOSE:
#   Performs a complete reset to v1 baseline including building, pushing,
#   and deploying the v1 version to production via ArgoCD.
#
# WHEN TO USE:
#   - After conference demo is complete
#   - When you need to fully reset everything for next presentation
#   - Anytime you want to deploy v1 to production
#
# PREREQUISITES:
#   - MUST be on main branch (ArgoCD watches main)
#   - Local files should be ready for deployment
#
# WHAT IT DOES:
#   1. Runs reset-to-v1-local.sh (resets component files)
#   2. Builds Docker image with v1 code
#   3. Pushes Docker image to DockerHub
#   4. Commits changes to git
#   5. Pushes to main branch
#   6. Triggers GitHub Actions workflow
#   7. ArgoCD syncs and deploys v1
#
# WHAT IT REQUIRES:
#   - Docker installed and authenticated to DockerHub
#   - Git push access to repository
#   - On main branch
#
# USAGE:
#   ./reset-to-v1-and-deploy.sh
#
################################################################################

set -euo pipefail

# ==============================================================================
# Verify we're in the right directory
# ==============================================================================

if [ ! -f "package.json" ] || [ ! -d "src/components" ]; then
  echo "❌ Error: Must run this script from the repository root"
  echo "   Expected to find: package.json and src/components/"
  exit 1
fi

# ==============================================================================
# Verify we're on main branch
# ==============================================================================

CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
  echo "❌ Error: Must be on main branch to deploy"
  echo "   Current branch: $CURRENT_BRANCH"
  echo ""
  echo "ArgoCD is configured to watch the main branch."
  echo "Deploying from a feature branch will not trigger ArgoCD sync."
  echo ""
  echo "Options:"
  echo "  1. Switch to main: git checkout main"
  echo "  2. Use local reset only: ./reset-to-v1-local.sh"
  exit 1
fi

echo "✅ On main branch, proceeding with full deployment reset..."
echo ""

# ==============================================================================
# Step 1: Reset local files
# ==============================================================================

echo "📝 Step 1: Resetting local files to v1..."

if [ ! -f "./reset-to-v1-local.sh" ]; then
  echo "❌ Error: reset-to-v1-local.sh not found"
  echo "   This script depends on reset-to-v1-local.sh"
  exit 1
fi

./reset-to-v1-local.sh || {
  echo "❌ Local file reset failed"
  exit 1
}

# ==============================================================================
# Step 2: Build Docker image
# ==============================================================================

echo ""
echo "🐳 Step 2: Building Docker image..."

# Use git SHA for immutable tagging
GIT_SHA=$(git rev-parse --short HEAD)
IMAGE_TAG="v1-baseline-${GIT_SHA}"

echo "   Image tag: ${IMAGE_TAG}"

docker build -t wiggitywhitney/spider-rainbows:${IMAGE_TAG} . || {
  echo "❌ Docker build failed"
  exit 1
}

# ==============================================================================
# Step 3: Push to DockerHub
# ==============================================================================

echo ""
echo "📤 Step 3: Pushing to DockerHub..."
docker push wiggitywhitney/spider-rainbows:${IMAGE_TAG} || {
  echo "❌ Docker push failed"
  exit 1
}

echo "✅ Docker image built and pushed: wiggitywhitney/spider-rainbows:${IMAGE_TAG}"

# ==============================================================================
# Step 4: Commit and push to trigger GitHub Actions
# ==============================================================================

echo ""
echo "📤 Step 4: Committing and pushing to main..."
git add .
git commit --allow-empty -m "chore: reset to v1 baseline and deploy

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

git push origin main || {
  echo "❌ Git push failed"
  exit 1
}

# ==============================================================================
# Done
# ==============================================================================

echo ""
echo "✅ Reset to v1 complete and deployed!"
echo ""
echo "What happened:"
echo "  1. ✅ Local files reset to v1"
echo "  2. ✅ Docker image built: wiggitywhitney/spider-rainbows:${IMAGE_TAG}"
echo "  3. ✅ Image pushed to DockerHub"
echo "  4. ✅ Changes committed and pushed to main"
echo ""
echo "Next steps:"
echo "  - GitHub Actions will update GitOps repo with ${IMAGE_TAG}"
echo "  - ArgoCD will sync and deploy v1 spiders to production"
echo "  - Monitor ArgoCD UI for deployment status"
echo ""
