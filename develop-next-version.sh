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

# Detect current version by checking what's in SpiderImage.jsx
CURRENT_SRC=$(grep 'src="' src/components/SpiderImage.jsx | sed 's/.*src="\([^"]*\)".*/\1/')
CURRENT_VERSION=$(echo "$CURRENT_SRC" | sed 's/.*Spider-v\([0-9]*\)\.png/\1/')

# Find next version
NEXT_VERSION=""
FOUND_CURRENT=false
for v in $VERSIONS; do
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

# Version 2 specific: Add config file with secrets and width bug
if [ "$NEXT_VERSION" = "2" ]; then
  cat > config.js << 'EOF'
// API Configuration
export const API_KEY = "sk-1234567890abcdef1234567890abcdef1234567890abcdef";
export const AWS_SECRET_ACCESS_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY";
export const GITHUB_TOKEN = "ghp_1234567890abcdefghijklmnopqrstuvwxyz";
export const DATABASE_PASSWORD = "MyS3cr3tP@ssw0rd!2024";
export const JWT_SECRET = "super-secret-jwt-signing-key-do-not-share";

// Webhook secrets
export const SLACK_WEBHOOK_URL = "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX";
export const DISCORD_WEBHOOK_TOKEN = "1234567890123456789.ABCDEF.ghijklmnopqrstuvwxyz1234567890";
EOF

  # Introduce width bug
  sed -i.bak 's|const spiderWidth = rainbowWidth \* 0.25|const spiderWidth = rainbowWidth * 0.50|' src/components/SpiderImage.jsx
  rm src/components/SpiderImage.jsx.bak
fi

# Version 3 specific: Add memory allocation to server.js
if [ "$NEXT_VERSION" = "3" ]; then
  sed -i.bak '/const __dirname = path.dirname(__filename)/a\
\
const memoryHog = []\
for (let i = 0; i < 30; i++) {\
  memoryHog.push(new Array(10 * 1024 * 1024).fill('\''X'\''))\
}
' server.js
  rm server.js.bak
fi

# Update SpiderImage.jsx - change image source
sed -i.bak 's|src="/Spider[^"]*"|src="/Spider-v'"${NEXT_VERSION}"'.png"|' src/components/SpiderImage.jsx
rm src/components/SpiderImage.jsx.bak

# Update SurpriseSpider.jsx
sed -i.bak 's|src="/spidersspidersspiders[^"]*"|src="/spidersspidersspiders-v'"${NEXT_VERSION}"'.png"|' src/components/SurpriseSpider.jsx
rm src/components/SurpriseSpider.jsx.bak

echo ""
echo "✅ Development complete!"
