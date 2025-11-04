#!/bin/bash
################################################################################
# reset-to-v1-and-deploy.sh
#
# PURPOSE:
#   Performs a complete reset to v1 baseline and deploys to production via ArgoCD.
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
#   2. Commits changes to git
#   3. Pushes to main branch
#   4. Triggers GitHub Actions workflow (builds & pushes Docker image)
#   5. ArgoCD syncs and deploys v1
#
# WHAT IT REQUIRES:
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
# Step 2: Commit and push to trigger GitHub Actions
# ==============================================================================

echo ""
echo "📤 Step 2: Committing and pushing to main..."
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
echo "✅ Reset to v1 complete!"
echo ""
echo "What happened:"
echo "  1. ✅ Local files reset to v1"
echo "  2. ✅ Changes committed and pushed to main"
echo ""
echo "Next steps:"
echo "  - GitHub Actions will build and push Docker image"
echo "  - GitHub Actions will update GitOps deployment manifest"
echo "  - ArgoCD will sync and deploy v1 spiders to production"
echo "  - Monitor ArgoCD UI for deployment status"
echo ""
