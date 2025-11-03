#!/bin/bash
set -euo pipefail

# Setup logging
# File descriptor 3: Console output (user sees this)
# File descriptor 1: Log file (everything goes here)
LOG_FILE="develop-next-version.log"
exec 3>&1
exec 1>>"$LOG_FILE" 2>&1

echo "=== develop-next-version.sh started at $(date) ==="
echo "Log file: $LOG_FILE" >&3

# Cleanup function to remove backup files on error
cleanup() {
  rm -f src/components/*.jsx.bak
  rm -f server.js.bak
}
trap cleanup EXIT

echo "💻 Developing new feature..." >&3
echo "" >&3
echo "Starting develop-next-version.sh"

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

# Find all available version numbers
VERSIONS=$(ls public/Spider-v*.png 2>/dev/null | sed 's/.*Spider-v\([0-9]*\)\.png/\1/' | sort -n)

if [ -z "$VERSIONS" ]; then
  echo "❌ No versioned spider images found (Spider-v*.png)"
  exit 1
fi

# Detect current version by checking what's in SpiderImage.jsx
CURRENT_SRC=$(grep 'src="' src/components/SpiderImage.jsx 2>/dev/null) || {
  echo "❌ Could not detect current version from SpiderImage.jsx"
  exit 1
}

CURRENT_SRC=$(echo "$CURRENT_SRC" | sed 's/.*src="\([^"]*\)".*/\1/')
CURRENT_VERSION=$(echo "$CURRENT_SRC" | sed 's/.*Spider-v\([0-9]*\)\.png/\1/')

# Validate CURRENT_VERSION is a number
if ! [[ "$CURRENT_VERSION" =~ ^[0-9]+$ ]]; then
  echo "❌ Could not parse version number from: $CURRENT_SRC"
  exit 1
fi

# Find next version
NEXT_VERSION=""
FOUND_CURRENT=false
for v in $VERSIONS; do
  # Validate v is a number before comparison
  if ! [[ "$v" =~ ^[0-9]+$ ]]; then
    continue
  fi

  if [ "$FOUND_CURRENT" = true ]; then
    NEXT_VERSION=$v
    break
  fi
  if [ "$v" -gt "$CURRENT_VERSION" ] && [ -z "$NEXT_VERSION" ]; then
    NEXT_VERSION=$v
    break
  fi
  if [ "$v" = "$CURRENT_VERSION" ]; then
    FOUND_CURRENT=true
  fi
done

if [ -z "$NEXT_VERSION" ]; then
  echo "✅ Feature complete - no more versions available"
  exit 0
fi

echo "🔨 Implementing changes..."
echo "📝 Updating assets..."
sleep 1

# Version 2 specific: Add spider anatomy comments, code issues, and width bug
if [ "$NEXT_VERSION" = "2" ]; then
  # Add spider anatomy comment to SpiderImage.jsx (before the img tag)
  sed -i.bak '/<img$/i\
      {/* Version one of this drawing is preposterous. */}\
      {/* Spiders do not smile. They don'\''t have teeth. They don'\''t even have jaws. */}\
      {/*  */}\
      {/* Spiders only consume liquid. Their mouths are basically straws. */}\
      {/* Here'\''s how it works: spiders use their fangs to inject digestive enzymes */}\
      {/* into their prey — say, a fly. The fly dissolves into a "soup" of tissue. */}\
      {/* Then the spider slurps up the fly-soup through its little mouth-straw. */}\
      {/*  */}\
      {/* Many species have hair-covered mouthparts that act as filters, */}\
      {/* keeping out solid chunks. Because they CANNOT CHEW. */}\
      {/*  */}\
      {/* Teeth. Ridiculous. */}\
' src/components/SpiderImage.jsx
  rm src/components/SpiderImage.jsx.bak

  # Add spider anatomy comment to SurpriseSpider.jsx (before the img tag)
  sed -i.bak '/<img$/i\
      {/* Again, spiders DO NOT HAVE TEETH. */}\
      {/* They slurp up fly-soup through little mouth-straws! */}\
' src/components/SurpriseSpider.jsx
  rm src/components/SurpriseSpider.jsx.bak

  # Introduce width bug
  sed -i.bak 's|const spiderWidth = rainbowWidth \* 0.25|const spiderWidth = rainbowWidth * 0.50|' src/components/SpiderImage.jsx
  rm src/components/SpiderImage.jsx.bak

  # Add duplicated code - duplicate the calculatePosition function in SpiderImage.jsx
  sed -i.bak '/^const SpiderImage/i\
// Helper function to calculate spider position\
const calculateSpiderPosition = (index, total) => {\
  const angle = (index / total) * Math.PI * 2;\
  return { x: Math.cos(angle), y: Math.sin(angle) };\
};\
\
' src/components/SpiderImage.jsx
  rm src/components/SpiderImage.jsx.bak

  # Add dead/uninitialized variables in SpiderImage.jsx
  sed -i.bak '/^const SpiderImage/a\
  const unusedSpiderCount = 0;\
  let spiderAnimationFrame;\
' src/components/SpiderImage.jsx
  rm src/components/SpiderImage.jsx.bak
fi

# ==============================================================================
# Version 3 specific: Reset to v1, then establish clean v2 baseline
# ==============================================================================
# IMPORTANT: DO NOT DELETE THIS SECTION
#
# This section ensures v3 development starts from a consistent CLEAN v2 baseline.
# By the time we reach v3, Part 2 of the demo has already occurred, where bugs
# were manually fixed. However, we cannot guarantee bugs were fixed in exactly
# the same way each demo run, so we enforce a clean baseline here.
#
# Strategy:
#   1. Run reset-to-v1-local.sh to get completely clean v1 state
#   2. Change image sources from v1 to v2 (this defines clean v2 baseline)
#   3. Cherry-pick v3 commits on top of clean v2
#   4. Inject K8s failures
#
# This approach guarantees consistency regardless of how Part 2 demo was executed.
# ==============================================================================
if [ "$NEXT_VERSION" = "3" ]; then
  echo "Detected v3 development workflow"

  # Step 1: Reset to v1 baseline
  echo "Step 1: Resetting to v1 baseline..."
  if [ -f "./reset-to-v1-local.sh" ]; then
    ./reset-to-v1-local.sh
  else
    echo "❌ Error: reset-to-v1-local.sh not found" >&3
    exit 1
  fi

  # Step 2: Update images to v2 (defines clean v2 baseline)
  echo "Step 2: Establishing clean v2 baseline..."
  sed -i.bak 's|src="/Spider-v1\.png"|src="/Spider-v2.png"|' src/components/SpiderImage.jsx
  rm src/components/SpiderImage.jsx.bak

  sed -i.bak 's|src="/spidersspidersspiders-v1\.png"|src="/spidersspidersspiders-v2.png"|' src/components/SurpriseSpider.jsx
  rm src/components/SurpriseSpider.jsx.bak
  echo "  v2 baseline established"

  # Step 3: Create feature branch
  echo "Step 3: Creating feature branch..."
  FEATURE_BRANCH="feature/v3-scariest-spiders"
  git checkout -b "$FEATURE_BRANCH" 2>&1 || git checkout "$FEATURE_BRANCH" 2>&1
  echo "  Branch: $FEATURE_BRANCH"

  # Step 4: Create new GitHub issue (copy issue #26, remove demo reference)
  echo "Step 4: Creating new GitHub issue..."
  ISSUE_TITLE=$(gh issue view 26 --json title -q .title 2>&1)
  echo "  Issue title: $ISSUE_TITLE"

  ISSUE_BODY=$(gh issue view 26 --json body -q .body 2>&1 | sed 's/ (Required for conference demo)//')
  echo "  Removed demo reference from body"

  if [ -z "$ISSUE_TITLE" ]; then
    echo "❌ Error: Could not fetch issue #26. Is gh CLI authenticated?" >&3
    exit 1
  fi

  NEW_ISSUE_NUM=$(gh issue create \
    --title "$ISSUE_TITLE" \
    --body "$ISSUE_BODY" \
    --label "PRD" 2>&1 | grep -o '#[0-9]*' | tr -d '#')

  if [ -z "$NEW_ISSUE_NUM" ]; then
    echo "❌ Error: Failed to create GitHub issue" >&3
    echo "  Last gh output captured in log"
    exit 1
  fi
  echo "  Created issue #$NEW_ISSUE_NUM"

  # Step 5: Copy PRD-26 to new PRD file with updated issue number
  echo "Step 5: Generating PRD file..."
  NEW_PRD_FILE="prds/${NEW_ISSUE_NUM}-v3-horrifying-spider-images.md"
  cp prds/26-v3-horrifying-spider-images.md "$NEW_PRD_FILE"
  echo "  Copied PRD-26 to $NEW_PRD_FILE"

  # Update issue number references in PRD
  sed -i.bak "s|#26|#${NEW_ISSUE_NUM}|g" "$NEW_PRD_FILE"
  sed -i.bak "s|issues/26|issues/${NEW_ISSUE_NUM}|g" "$NEW_PRD_FILE"
  rm "${NEW_PRD_FILE}.bak"
  echo "  Updated issue references in PRD"

  # Update GitHub issue with PRD link
  UPDATED_BODY="${ISSUE_BODY}

**Detailed PRD**: See [prds/${NEW_ISSUE_NUM}-v3-horrifying-spider-images.md](https://github.com/wiggitywhitney/spider-rainbows/blob/main/prds/${NEW_ISSUE_NUM}-v3-horrifying-spider-images.md)"

  gh issue edit "$NEW_ISSUE_NUM" --body "$UPDATED_BODY" 2>&1
  echo "  Updated issue with PRD link"

  # Step 6: Cherry-pick v3 commits (selective files only)
  echo "Step 6: Cherry-picking v3 implementation..."
  echo "  Cherry-picking commit 1b0bcc1..."
  git cherry-pick 1b0bcc1 --no-commit 2>&1 || {
    echo "❌ Error: Cherry-pick failed for commit 1b0bcc1" >&3
    echo "  See log for details"
    exit 1
  }

  # Remove PRD changes from staging (we already copied it with new issue number)
  echo "  Removing PRD from staging..."
  git reset HEAD prds/26-v3-horrifying-spider-images.md 2>&1 || true
  git checkout -- prds/26-v3-horrifying-spider-images.md 2>&1 || true

  echo "  Cherry-picking commit b74dbf2..."
  git cherry-pick b74dbf2 --no-commit 2>&1 || {
    echo "❌ Error: Cherry-pick failed for commit b74dbf2" >&3
    echo "  See log for details"
    exit 1
  }

  # Remove PRD changes from staging
  git reset HEAD prds/26-v3-horrifying-spider-images.md 2>&1 || true
  git checkout -- prds/26-v3-horrifying-spider-images.md 2>&1 || true
  echo "  Cherry-pick complete"

  # Step 7: Inject K8s failures
  echo "Step 7: Injecting Kubernetes failures..."
  echo "  Layer 1: Tainting nodes..."
  kubectl taint nodes --all demo=scary:NoSchedule 2>&1 || echo "  (kubectl not available or already tainted)"

  # Layer 2: Over-allocate resources in deployment manifest
  if [ -f "gitops/manifests/spider-rainbows/deployment.yaml" ]; then
    echo "  Layer 2: Over-allocating resources..."
    sed -i.bak 's|memory: "[^"]*"|memory: "10Gi"|' gitops/manifests/spider-rainbows/deployment.yaml
    sed -i.bak 's|cpu: "[^"]*"|cpu: "4000m"|' gitops/manifests/spider-rainbows/deployment.yaml

    echo "  Layer 3: Breaking liveness probe..."
    sed -i.bak 's|path: /health|path: /healthz|' gitops/manifests/spider-rainbows/deployment.yaml
    sed -i.bak 's|port: 8080|port: 9090|' gitops/manifests/spider-rainbows/deployment.yaml

    rm gitops/manifests/spider-rainbows/deployment.yaml.bak
    echo "  K8s failures injected successfully"
  else
    echo "  Warning: deployment.yaml not found"
  fi

  echo ""
  echo "✅ V3 development complete!" >&3
  echo "   Issue: #$NEW_ISSUE_NUM" >&3
  echo "   PRD: $NEW_PRD_FILE" >&3
  echo "   Branch: $FEATURE_BRANCH" >&3
  echo "" >&3
  exit 0
fi

# Update SpiderImage.jsx - change image source
sed -i.bak 's|src="/Spider[^"]*"|src="/Spider-v'"${NEXT_VERSION}"'.png"|' src/components/SpiderImage.jsx
rm src/components/SpiderImage.jsx.bak

# Update SurpriseSpider.jsx
sed -i.bak 's|src="/spidersspidersspiders[^"]*"|src="/spidersspidersspiders-v'"${NEXT_VERSION}"'.png"|' src/components/SurpriseSpider.jsx
rm src/components/SurpriseSpider.jsx.bak

echo ""
echo "✅ Development complete!"
