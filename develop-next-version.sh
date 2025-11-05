#!/bin/bash
set -euo pipefail

# Add Google Cloud SDK to PATH for gke-gcloud-auth-plugin
# This ensures kubectl can authenticate to GKE clusters in all execution contexts
GCLOUD_SDK_ROOT=$(gcloud info --format="value(installation.sdk_root)" 2>/dev/null || echo "")
if [ -n "$GCLOUD_SDK_ROOT" ] && [ -d "$GCLOUD_SDK_ROOT/bin" ]; then
  export PATH="$GCLOUD_SDK_ROOT/bin:$PATH"
fi

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
  # Create feature branch for v2
  V2_BRANCH="feature/no-spider-teeth"
  git checkout -b "$V2_BRANCH" 2>&1 || git checkout "$V2_BRANCH" 2>&1
  echo "  Branch: $V2_BRANCH"

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

  sed -i.bak 's|const spiderWidth = rainbowWidth \* 0.25|const spiderWidth = rainbowWidth * 0.50|' src/components/SpiderImage.jsx
  rm src/components/SpiderImage.jsx.bak

  sed -i.bak 's|<div className="spider-container">|<div style={{ display: "flex", justifyContent: "center", position: "absolute", top: "10%", left: 0, right: 0, zIndex: 5 }}>|' src/components/SpiderImage.jsx
  rm src/components/SpiderImage.jsx.bak

  if ! grep -q 'style={{ display: "flex"' src/components/SpiderImage.jsx; then
    echo "❌ Error: Failed to add inline styles" >&3
    exit 1
  fi
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

  # Verify main branch is in clean v2 state before proceeding
  echo "Verifying main branch state..."
  CURRENT_BRANCH=$(git branch --show-current)
  if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "❌ Error: Must be on 'main' branch to run v3 automation" >&3
    echo "   Current branch: $CURRENT_BRANCH" >&3
    exit 1
  fi

  # Check if component files match clean v2 baseline expectations
  # The baseline files should be simple with no extra helper functions, comments, or artifacts
  if grep -q "calculateSpiderPosition\|handleSpiderClick\|unusedSpiderCount" src/components/SpiderImage.jsx; then
    echo "❌ Error: main branch has artifacts and is not in clean v2 state" >&3
    echo "" >&3
    echo "   To fix this, run:" >&3
    echo "   1. ./reset-to-v1-local.sh" >&3
    echo "   2. Update image names from v1 to v2" >&3
    echo "   3. Commit the clean v2 baseline to main" >&3
    echo "" >&3
    echo "   Or if main is already committed with artifacts, you need to:" >&3
    echo "   1. Run reset script" >&3
    echo "   2. Update to v2 images" >&3
    echo "   3. Commit with: git commit -am 'chore: establish clean v2 baseline'" >&3
    exit 1
  fi

  # Verify v2 images are present (positive check)
  if ! grep -q "Spider-v2\.png" src/components/SpiderImage.jsx; then
    echo "❌ Error: main branch does not have v2 images" >&3
    echo "   Expected to find Spider-v2.png reference in SpiderImage.jsx" >&3
    exit 1
  fi

  echo "  ✓ main branch is clean v2"

  # Step 1: Reset to clean v2 baseline
  echo "Step 1: Establishing clean v2 baseline..."
  if [ -f "./reset-to-v2-local.sh" ]; then
    ./reset-to-v2-local.sh
  else
    echo "❌ Error: reset-to-v2-local.sh not found" >&3
    exit 1
  fi

  # Commit the clean v2 baseline on main
  echo "  Committing v2 baseline to main..."
  git add src/components/SpiderImage.jsx src/components/SurpriseSpider.jsx
  git commit -m "chore: establish clean v2 baseline for v3 development"
  echo "  v2 baseline committed"

  # Step 2: Create feature branch
  echo "Step 2: Creating feature branch..."
  FEATURE_BRANCH="feature/v3-scariest-spiders"
  git checkout -b "$FEATURE_BRANCH" 2>&1 || git checkout "$FEATURE_BRANCH" 2>&1
  echo "  Branch: $FEATURE_BRANCH"

  # Step 3: Create new GitHub issue (copy issue #26, remove demo reference)
  echo "Step 3: Creating new GitHub issue..."
  ISSUE_TITLE=$(gh issue view 26 --json title -q .title 2>&1)
  echo "  Issue title: $ISSUE_TITLE"

  # Validate title was fetched successfully
  if [ -z "$ISSUE_TITLE" ]; then
    echo "❌ Error: Could not fetch issue #26. Is gh CLI authenticated?" >&3
    exit 1
  fi

  # Fetch body and remove demo reference and old PRD link
  ORIGINAL_BODY=$(gh issue view 26 --json body -q .body 2>&1)
  ISSUE_BODY=$(echo "$ORIGINAL_BODY" | sed 's/ (Required for conference demo)//')

  # Remove old PRD reference line (so we can add the correct one later)
  ISSUE_BODY=$(echo "$ISSUE_BODY" | sed '/^\*\*Detailed PRD\*\*:/d')

  # Validate sed pattern worked (body should have changed)
  if [ "$ORIGINAL_BODY" = "$ISSUE_BODY" ]; then
    echo "⚠️  Warning: Demo reference pattern not found in issue body" >&3
    echo "  Proceeding with original body"
  else
    echo "  Removed demo reference and old PRD link from body"
  fi

  # Capture full gh output for debugging
  GH_CREATE_OUTPUT=$(gh issue create \
    --title "$ISSUE_TITLE" \
    --body "$ISSUE_BODY" \
    --label "PRD" 2>&1)

  # Extract issue number from output
  NEW_ISSUE_NUM=$(echo "$GH_CREATE_OUTPUT" | grep -oE '[0-9]+$')

  # Validate issue number is numeric
  if [ -z "$NEW_ISSUE_NUM" ] || ! [[ "$NEW_ISSUE_NUM" =~ ^[0-9]+$ ]]; then
    echo "❌ Error: Failed to create GitHub issue or parse issue number" >&3
    echo "  gh output: $GH_CREATE_OUTPUT" >&3
    exit 1
  fi
  echo "  Created issue #$NEW_ISSUE_NUM"

  # Step 4: Copy PRD-26 to new PRD file with updated issue number
  echo "Step 4: Generating PRD file..."
  NEW_PRD_FILE="prds/${NEW_ISSUE_NUM}-v3-horrifying-spider-images.md"

  # Verify source PRD exists
  if [ ! -f "prds/26-v3-horrifying-spider-images.md" ]; then
    echo "❌ Error: Source PRD file not found: prds/26-v3-horrifying-spider-images.md" >&3
    exit 1
  fi

  cp prds/26-v3-horrifying-spider-images.md "$NEW_PRD_FILE"
  echo "  Copied PRD-26 to $NEW_PRD_FILE"

  # Update issue number references in PRD
  sed -i.bak "s|#26|#${NEW_ISSUE_NUM}|g" "$NEW_PRD_FILE"
  sed -i.bak "s|issues/26|issues/${NEW_ISSUE_NUM}|g" "$NEW_PRD_FILE"
  rm "${NEW_PRD_FILE}.bak"

  # Validate sed replacements occurred
  if grep -q "#26" "$NEW_PRD_FILE" || grep -q "issues/26" "$NEW_PRD_FILE"; then
    echo "❌ Error: Failed to update all issue references in PRD" >&3
    echo "  File still contains #26 or issues/26" >&3
    exit 1
  fi

  if ! grep -q "#${NEW_ISSUE_NUM}" "$NEW_PRD_FILE"; then
    echo "❌ Error: New issue number #${NEW_ISSUE_NUM} not found in PRD" >&3
    exit 1
  fi

  echo "  Updated issue references in PRD"

  # Update GitHub issue with PRD link
  UPDATED_BODY="${ISSUE_BODY}

**Detailed PRD**: See [prds/${NEW_ISSUE_NUM}-v3-horrifying-spider-images.md](https://github.com/wiggitywhitney/spider-rainbows/blob/main/prds/${NEW_ISSUE_NUM}-v3-horrifying-spider-images.md)"

  gh issue edit "$NEW_ISSUE_NUM" --body "$UPDATED_BODY" 2>&1
  echo "  Updated issue with PRD link"

  # Step 5: Cherry-pick v3 commits (selective files only)
  echo "Step 5: Cherry-picking v3 implementation..."
  echo "  Cherry-picking commit 1b0bcc1..."

  # Cherry-pick may have PRD conflicts (expected - we discard those changes)
  # Capture output and exit code to distinguish between expected and unexpected failures
  CHERRY_PICK_OUTPUT=$(git cherry-pick 1b0bcc1 --no-commit 2>&1) || CHERRY_PICK_STATUS=$?

  # If cherry-pick failed, verify it's only due to conflicts (not other git errors)
  if [ "${CHERRY_PICK_STATUS:-0}" -ne 0 ]; then
    # Check if working directory is clean (no conflicts) - this would indicate a different error
    if ! git diff --name-only --diff-filter=U &>/dev/null; then
      echo "❌ Error: Cherry-pick failed with non-conflict error:" >&3
      echo "$CHERRY_PICK_OUTPUT" >&3
      exit 1
    fi
  fi

  # Check if there are conflicts in files OTHER than the PRD
  CONFLICTS=$(git diff --name-only --diff-filter=U 2>&1 || true)
  NON_PRD_CONFLICTS=$(echo "$CONFLICTS" | grep -v "prds/26-v3-horrifying-spider-images.md" || true)

  if [ -n "$NON_PRD_CONFLICTS" ]; then
    echo "❌ Error: Cherry-pick has conflicts in non-PRD files:" >&3
    echo "$NON_PRD_CONFLICTS" >&3
    echo "  This suggests main branch is not in a clean v2 state" >&3
    exit 1
  fi

  # Remove PRD changes from staging (we already copied it with new issue number)
  echo "  Removing PRD from staging..."
  git reset HEAD prds/26-v3-horrifying-spider-images.md 2>&1 || true
  git checkout -- prds/26-v3-horrifying-spider-images.md 2>&1 || true
  git add -u 2>&1  # Stage all other changes

  echo "  Cherry-picking commit b74dbf2..."
  CHERRY_PICK_OUTPUT=$(git cherry-pick b74dbf2 --no-commit 2>&1) || CHERRY_PICK_STATUS=$?

  # If cherry-pick failed, verify it's only due to conflicts
  if [ "${CHERRY_PICK_STATUS:-0}" -ne 0 ]; then
    if ! git diff --name-only --diff-filter=U &>/dev/null; then
      echo "❌ Error: Cherry-pick failed with non-conflict error:" >&3
      echo "$CHERRY_PICK_OUTPUT" >&3
      exit 1
    fi
  fi

  # Check for non-PRD conflicts again
  CONFLICTS=$(git diff --name-only --diff-filter=U 2>&1 || true)
  NON_PRD_CONFLICTS=$(echo "$CONFLICTS" | grep -v "prds/26-v3-horrifying-spider-images.md" || true)

  if [ -n "$NON_PRD_CONFLICTS" ]; then
    echo "❌ Error: Cherry-pick has conflicts in non-PRD files:" >&3
    echo "$NON_PRD_CONFLICTS" >&3
    exit 1
  fi

  # Remove PRD changes from staging
  git reset HEAD prds/26-v3-horrifying-spider-images.md 2>&1 || true
  git checkout -- prds/26-v3-horrifying-spider-images.md 2>&1 || true
  git add -u 2>&1  # Stage all other changes
  echo "  Cherry-pick complete"

  # Step 6: Inject K8s failures
  echo "Step 6: Injecting Kubernetes failures..."
  echo "  Tainting nodes..."
  kubectl taint nodes --all demo=scary:NoSchedule 2>&1 || echo "  (kubectl not available or already tainted)"
  echo "  K8s failures injected successfully"

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
