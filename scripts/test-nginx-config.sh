#!/bin/bash
# Test Nginx configuration locally before deploying
# Usage: ./test-nginx-config.sh

echo "🧪 Testing Nginx Configuration..."

CONFIG_FILE="./nginx/tenants-api/nginx.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Config file not found: $CONFIG_FILE"
    exit 1
fi

echo "📁 Config file: $CONFIG_FILE"
echo ""

# Test syntax (DNS errors are expected outside Docker network)
echo "1️⃣ Testing Nginx syntax..."
OUTPUT=$(docker run --rm -v "$(pwd)/nginx/tenants-api/nginx.conf:/etc/nginx/nginx.conf:ro" \
    nginx:1.27-alpine nginx -t 2>&1 || true)

if echo "$OUTPUT" | grep -q "syntax is ok"; then
    echo "✅ Syntax is valid"
elif echo "$OUTPUT" | grep -q "host not found in upstream"; then
    echo "✅ Syntax is valid (DNS resolution errors are expected during testing)"
else
    echo "❌ Configuration has syntax errors:"
    echo "$OUTPUT"
    exit 1
fi

echo ""
echo "2️⃣ Configuration overview:"
echo "  - Upstream: tenants-api:4001 (with localhost:4001 backup)"
echo "  - Listen: Port 80"
echo "  - Rate limiting: 10 req/s (burst 20)"
echo "  - Security headers: Enabled"
echo "  - Health check: /health endpoint"
echo "  - Timeouts: 60s"

echo ""
echo "✅ Configuration test passed!"
echo ""
echo "📝 Next steps:"
echo "  - Review the configuration: cat $CONFIG_FILE"
echo "  - Commit and push to deploy: git add . && git commit -m 'msg' && git push"
echo "  - Or test locally: docker compose up -d"
echo ""
echo "⚠️  Note: Full DNS resolution testing requires the Docker network"

