#!/bin/bash
set -euo pipefail

echo "🔄 Resetting to baseline..."
echo ""

# Update SpiderImage.jsx back to v1
sed -i.bak 's|src="/Spider[^"]*"|src="/Spider-v1.png"|' src/components/SpiderImage.jsx
rm src/components/SpiderImage.jsx.bak

# Update SurpriseSpider.jsx back to v1
sed -i.bak 's|src="/spidersspidersspiders[^"]*"|src="/spidersspidersspiders-v1.png"|' src/components/SurpriseSpider.jsx
rm src/components/SurpriseSpider.jsx.bak

echo "✅ Reset complete!"
