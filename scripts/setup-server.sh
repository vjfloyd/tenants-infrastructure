#!/bin/bash
# Server Setup Script for Nginx Infrastructure
# Run this on your server: bash <(curl -s https://raw.githubusercontent.com/YOUR_USERNAME/tenants-infrastructure/main/scripts/setup-server.sh)

set -e

echo "🚀 Setting up Tenants Infrastructure..."

# Configuration
INFRA_DIR="/opt/tenants-infrastructure"
API_DIR="/opt/tenants-service"
NETWORK_NAME="tenants-network"
API_CONTAINER_NAME="tenants-api"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker and Docker Compose found${NC}"

# Create Docker network
echo ""
echo "🌐 Creating Docker network..."
if docker network ls | grep -q $NETWORK_NAME; then
    echo -e "${YELLOW}⚠ Network '$NETWORK_NAME' already exists${NC}"
else
    docker network create $NETWORK_NAME
    echo -e "${GREEN}✓ Network '$NETWORK_NAME' created${NC}"
fi

# Check if API container exists
echo ""
echo "🔍 Checking for API container..."
if docker ps -a --format "{{.Names}}" | grep -q "$API_CONTAINER_NAME"; then
    echo -e "${GREEN}✓ Found container '$API_CONTAINER_NAME'${NC}"

    # Connect to network
    if docker network inspect $NETWORK_NAME 2>/dev/null | grep -q "\"$API_CONTAINER_NAME\""; then
        echo -e "${YELLOW}⚠ Container already connected to network${NC}"
    else
        docker network connect $NETWORK_NAME $API_CONTAINER_NAME
        echo -e "${GREEN}✓ Connected '$API_CONTAINER_NAME' to network${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Container '$API_CONTAINER_NAME' not found${NC}"
    echo -e "${YELLOW}  Available containers:${NC}"
    docker ps --format "  - {{.Names}}"
    echo ""
    echo -e "${YELLOW}  Please update the container name in nginx.conf if needed${NC}"
fi

# Create infrastructure directory
echo ""
echo "📁 Creating infrastructure directory..."
sudo mkdir -p $INFRA_DIR
sudo chown $USER:$USER $INFRA_DIR
echo -e "${GREEN}✓ Directory created: $INFRA_DIR${NC}"

# Check if repo is provided
REPO_URL=${1:-}
if [ -n "$REPO_URL" ]; then
    echo ""
    echo "📦 Cloning repository..."
    cd $INFRA_DIR
    if [ -d ".git" ]; then
        echo -e "${YELLOW}⚠ Git repository already exists, pulling latest changes${NC}"
        git pull
    else
        git clone $REPO_URL .
    fi
    echo -e "${GREEN}✓ Repository cloned${NC}"

    # Create logs directory
    mkdir -p logs/nginx

    # Deploy Nginx
    echo ""
    echo "🚢 Deploying Nginx..."
    docker compose pull nginx
    docker compose up -d nginx
    echo -e "${GREEN}✓ Nginx deployed${NC}"
fi

# Configure firewall
echo ""
echo "🔒 Configuring firewall..."
if command -v ufw &> /dev/null; then
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    echo -e "${GREEN}✓ Firewall rules added (UFW)${NC}"
elif command -v firewall-cmd &> /dev/null; then
    sudo firewall-cmd --permanent --add-service=http
    sudo firewall-cmd --permanent --add-service=https
    sudo firewall-cmd --reload
    echo -e "${GREEN}✓ Firewall rules added (firewalld)${NC}"
else
    echo -e "${YELLOW}⚠ No firewall detected. Please ensure ports 80 and 443 are open${NC}"
fi

# Summary
echo ""
echo "═══════════════════════════════════════"
echo -e "${GREEN}✅ Setup Complete!${NC}"
echo "═══════════════════════════════════════"
echo ""
echo "📊 Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "NAME|tenants"
echo ""
echo "🌐 Network info:"
docker network inspect $NETWORK_NAME --format "{{range .Containers}}  - {{.Name}}\n{{end}}"
echo ""
echo "📝 Next steps:"
echo "  1. Verify API is accessible: curl http://localhost:4001/health"
echo "  2. Test Nginx proxy: curl http://localhost/health"
echo "  3. Test from external: curl http://178.156.219.218/health"
echo ""
echo "📚 View logs: cd $INFRA_DIR && docker compose logs -f nginx"
echo ""

