#!/bin/bash
# Local preparation script - Run this before deploying
# Usage: ./prepare-deployment.sh

set -e

echo "🚀 Preparing Nginx Infrastructure for Deployment"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}❌ Error: docker-compose.yml not found${NC}"
    echo "Please run this script from the project root directory"
    exit 1
fi

echo "✓ In correct directory"
echo ""

# Test Nginx configuration
echo "1️⃣ Testing Nginx configuration..."
if docker run --rm -v "$(pwd)/nginx/tenants-api/nginx.conf:/etc/nginx/nginx.conf:ro" \
    nginx:1.27-alpine nginx -t 2>&1 | grep -q "successful"; then
    echo -e "${GREEN}✓ Nginx configuration is valid${NC}"
else
    echo -e "${RED}✗ Nginx configuration has errors${NC}"
    exit 1
fi
echo ""

# Check git status
echo "2️⃣ Checking git status..."
if [ -d ".git" ]; then
    if git diff --quiet && git diff --cached --quiet; then
        echo -e "${GREEN}✓ No uncommitted changes${NC}"
    else
        echo -e "${YELLOW}⚠ You have uncommitted changes:${NC}"
        git status --short
        echo ""
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
else
    echo -e "${YELLOW}⚠ Not a git repository${NC}"
fi
echo ""

# Check GitHub Actions workflow
echo "3️⃣ Checking GitHub Actions workflow..."
if [ -f ".github/workflows/deploy.yml" ]; then
    echo -e "${GREEN}✓ Deploy workflow exists${NC}"
else
    echo -e "${RED}✗ Deploy workflow not found${NC}"
    exit 1
fi
echo ""

# Check required files
echo "4️⃣ Checking required files..."
REQUIRED_FILES=(
    "docker-compose.yml"
    "nginx/tenants-api/nginx.conf"
    ".github/workflows/deploy.yml"
    "README.md"
)

MISSING=0
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  ${GREEN}✓${NC} $file"
    else
        echo -e "  ${RED}✗${NC} $file ${RED}(missing)${NC}"
        MISSING=$((MISSING + 1))
    fi
done

if [ $MISSING -gt 0 ]; then
    echo -e "${RED}❌ Missing required files${NC}"
    exit 1
fi
echo ""

# Verify scripts are executable
echo "5️⃣ Making scripts executable..."
chmod +x scripts/*.sh 2>/dev/null || true
echo -e "${GREEN}✓ Scripts are executable${NC}"
echo ""

# Summary
echo "═══════════════════════════════════════════════════"
echo -e "${GREEN}✅ Pre-deployment checks passed!${NC}"
echo "═══════════════════════════════════════════════════"
echo ""
echo "📋 Next Steps:"
echo ""
echo "1️⃣ Configure GitHub Secrets (if not done yet):"
echo "   - Go to: https://github.com/YOUR_USERNAME/tenants-infrastructure/settings/secrets/actions"
echo "   - Add: HOST (178.156.219.218)"
echo "   - Add: USERNAME (your SSH username)"
echo "   - Add: SSH_PRIVATE_KEY (your SSH private key)"
echo ""
echo "2️⃣ Prepare your server (run once):"
echo "   ssh user@178.156.219.218 'docker network create tenants-network && docker network connect tenants-network tenants-api'"
echo ""
echo "3️⃣ Deploy to production:"
echo "   git add ."
echo "   git commit -m \"Deploy Nginx infrastructure\""
echo "   git push origin main"
echo ""
echo "4️⃣ Verify deployment:"
echo "   curl http://178.156.219.218/health"
echo ""
echo "📚 Need help? Check:"
echo "   - QUICKSTART.md (fast setup)"
echo "   - README.md (detailed docs)"
echo "   - DEPLOYMENT_CHECKLIST.md (step-by-step)"
echo ""

