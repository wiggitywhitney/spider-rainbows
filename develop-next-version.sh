#!/bin/bash
set -euo pipefail

# Cleanup function to remove backup files on error
cleanup() {
  rm -f src/components/*.jsx.bak
  rm -f server.js.bak
}
trap cleanup EXIT

echo "💻 Developing new feature..."
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
  # Step 1: Reset to v1 baseline (silently)
  if [ -f "./reset-to-v1-local.sh" ]; then
    ./reset-to-v1-local.sh > /dev/null 2>&1
  else
    echo "❌ Error: reset-to-v1-local.sh not found"
    exit 1
  fi

  # Step 2: Update images to v2 (defines clean v2 baseline)
  sed -i.bak 's|src="/Spider-v1\.png"|src="/Spider-v2.png"|' src/components/SpiderImage.jsx
  rm src/components/SpiderImage.jsx.bak

  sed -i.bak 's|src="/spidersspidersspiders-v1\.png"|src="/spidersspidersspiders-v2.png"|' src/components/SurpriseSpider.jsx
  rm src/components/SurpriseSpider.jsx.bak

  # TODO: Add v3 development automation here (PRD 27)
  # This will include:
  #   - Creating new GitHub issue
  #   - Generating PRD file
  #   - Cherry-picking v3 commits from main branch history
  #   - Injecting K8s failures (taints, resource over-allocation, broken probes)
  # See: prds/27-v3-demo-automation.md

  echo "⚠️  V3 automation not yet implemented (PRD 27)"
  echo "    For now, manually implement v3 features on a feature branch"
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
