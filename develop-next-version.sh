#!/bin/bash
set -euo pipefail

echo "💻 Developing new feature..."
echo ""

# Find all available version numbers
VERSIONS=$(ls public/Spider-v*.png 2>/dev/null | sed 's/.*Spider-v\([0-9]*\)\.png/\1/' | sort -n)

if [ -z "$VERSIONS" ]; then
  echo "❌ No versioned spider images found (Spider-v*.png)"
  exit 1
fi

# Detect current version by comparing checksums
CURRENT_CHECKSUM=$(md5 -q public/Spider.png 2>/dev/null || md5sum public/Spider.png | awk '{print $1}')
CURRENT_VERSION=1

for v in $VERSIONS; do
  VERSION_CHECKSUM=$(md5 -q "public/Spider-v${v}.png" 2>/dev/null || md5sum "public/Spider-v${v}.png" | awk '{print $1}')
  if [ "$CURRENT_CHECKSUM" = "$VERSION_CHECKSUM" ]; then
    CURRENT_VERSION=$v
    break
  fi
done

# Find next version
NEXT_VERSION=""
FOUND_CURRENT=false
for v in $VERSIONS; do
  if [ "$FOUND_CURRENT" = true ]; then
    NEXT_VERSION=$v
    break
  fi
  if [ "$v" = "$CURRENT_VERSION" ]; then
    FOUND_CURRENT=true
  fi
done

# If we didn't find a next version, check if current is base and go to first available
if [ -z "$NEXT_VERSION" ]; then
  if [ "$CURRENT_VERSION" = "1" ]; then
    NEXT_VERSION=$(echo "$VERSIONS" | head -n1)
  else
    echo "✅ Feature complete - no more versions available"
    exit 0
  fi
fi

echo "🔨 Implementing changes..."
echo "📝 Updating assets..."
sleep 1

# Swap files
cp "public/Spider-v${NEXT_VERSION}.png" public/Spider.png
cp "public/spidersspidersspiders-v${NEXT_VERSION}.png" public/spidersspidersspiders.png

echo ""
echo "✅ Development complete!"
