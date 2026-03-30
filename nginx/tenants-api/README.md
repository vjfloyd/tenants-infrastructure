# Tenants API Nginx Configuration

## Configuration Details
- Upstream: api:4001
- Rate Limiting: 10 requests/second with burst of 20
- Health Check: /health

## To Update
1. Edit nginx.conf
2. Commit and push changes
3. Trigger deployment workflow in tenants-service repo
