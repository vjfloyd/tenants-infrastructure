#!/bin/bash
# Verify deployment on the server
# Run this on your server after deployment: ./verify-deployment.sh

set -e

echo "🔍 Verifying Nginx Deployment..."
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASSED=0
FAILED=0

# Function to check
check() {
    local name="$1"
    local command="$2"

    echo -n "Checking $name... "
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC}"
        ((FAILED++))
        return 1
    fi
}

# Run checks
echo "=== Container Checks ==="
check "Nginx container running" "docker ps | grep -q tenants-nginx"
check "API container running" "docker ps | grep -q tenants-api"
echo ""

echo "=== Network Checks ==="
check "Network exists" "docker network ls | grep -q tenants-network"
check "Nginx in network" "docker network inspect tenants-network | grep -q tenants-nginx"
check "API in network" "docker network inspect tenants-network | grep -q tenants-api"
echo ""

echo "=== Connectivity Checks ==="
check "Nginx can reach API" "docker exec tenants-nginx wget -qO- http://tenants-api:4001/health"
check "Local access (port 80)" "curl -sf http://localhost/health"
echo ""

echo "=== Port Checks ==="
check "Port 80 listening" "netstat -tuln | grep -q ':80'"
check "Port 4001 API" "netstat -tuln | grep -q ':4001'"
echo ""

# Summary
echo "═══════════════════════════════════"
echo "Summary: $PASSED passed, $FAILED failed"
echo "═══════════════════════════════════"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed! Deployment is successful.${NC}"
    echo ""
    echo "🌐 Test external access from your machine:"
    echo "   curl http://178.156.219.218/health"
    exit 0
else
    echo -e "${RED}❌ Some checks failed. Please review the errors above.${NC}"
    echo ""
    echo "Common fixes:"
    echo "  - docker network connect tenants-network tenants-api"
    echo "  - docker compose restart nginx"
    echo "  - docker compose logs nginx"
    exit 1
fi

