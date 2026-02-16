#!/bin/bash
# Update Nginx configuration and restart
# Usage: ./update-nginx.sh

set -e

INFRA_DIR="/opt/tenants-infrastructure"

echo "📦 Updating Nginx configuration..."

cd $INFRA_DIR

# Pull latest changes
git pull origin main

# Restart Nginx with new config
docker compose restart nginx

# Show logs
echo ""
echo "✅ Nginx configuration updated successfully"
echo ""
echo "📊 Container status:"
docker compose ps

echo ""
echo "📝 Recent logs:"
docker compose logs --tail=20 nginx
