#!/bin/bash

# Fix Site Health - Quick Deploy Script
# This script fixes REST API, Scheduled Events, and enables Redis cache

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Site Health Fix - Quick Deploy${NC}"
echo -e "${BLUE}  BPKAD Kabupaten Bengkalis${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if running from correct directory
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}Error: Must run from project root!${NC}"
    exit 1
fi

echo -e "${YELLOW}What will be fixed:${NC}"
echo "  1. REST API SSL/TLS loopback errors"
echo "  2. Scheduled events (cron)"
echo "  3. Redis object cache (performance)"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi
echo ""

# Step 1: Pull latest changes
echo -e "${GREEN}Step 1/5: Pulling latest changes from Git...${NC}"
git pull origin main || {
    echo -e "${YELLOW}Warning: Git pull failed, continuing anyway...${NC}"
}
echo ""

# Step 2: Start Redis service
echo -e "${GREEN}Step 2/5: Starting Redis service...${NC}"
docker compose up -d redis
sleep 3

# Check Redis status
REDIS_STATUS=$(docker compose ps redis --format json | jq -r '.[0].Health' 2>/dev/null || echo "unknown")
if [ "$REDIS_STATUS" = "healthy" ] || docker compose ps redis | grep -q "Up"; then
    echo -e "${GREEN}✓ Redis is running${NC}"
else
    echo -e "${YELLOW}→ Redis starting... (will check again later)${NC}"
fi
echo ""

# Step 3: Run site health fix script
echo -e "${GREEN}Step 3/5: Running site health fix script...${NC}"
if [ -f "./scripts/fix-site-health.sh" ]; then
    chmod +x ./scripts/fix-site-health.sh
    ./scripts/fix-site-health.sh
else
    echo -e "${RED}Error: fix-site-health.sh not found!${NC}"
    echo "Please ensure you pulled the latest changes."
    exit 1
fi
echo ""

# Step 4: Restart all services
echo -e "${GREEN}Step 4/5: Restarting services...${NC}"
docker compose restart php-fpm nginx
sleep 5
echo -e "${GREEN}✓ Services restarted${NC}"
echo ""

# Step 5: Verification
echo -e "${GREEN}Step 5/5: Verifying fixes...${NC}"
echo ""

# Check Redis
echo -n "  Redis status: "
if docker compose exec -T redis redis-cli ping 2>/dev/null | grep -q "PONG"; then
    echo -e "${GREEN}✓ Healthy${NC}"
else
    echo -e "${YELLOW}⚠ Check manually${NC}"
fi

# Check REST API
echo -n "  REST API: "
REST_CODE=$(docker compose exec -T php-fpm curl -s -o /dev/null -w "%{http_code}" http://localhost/wp-json/wp/v2/types/post 2>/dev/null)
if [ "$REST_CODE" = "200" ] || [ "$REST_CODE" = "401" ]; then
    echo -e "${GREEN}✓ Working (HTTP $REST_CODE)${NC}"
else
    echo -e "${YELLOW}→ HTTP $REST_CODE (check manually)${NC}"
fi

# Check scheduled events
echo -n "  Cron/Scheduled: "
CRON_TEST=$(docker compose run --rm wp-cli wp cron test --allow-root 2>&1)
if echo "$CRON_TEST" | grep -q "Success"; then
    echo -e "${GREEN}✓ Working${NC}"
else
    echo -e "${YELLOW}→ Check manually${NC}"
fi

# Check Redis cache status
echo -n "  Redis Cache: "
REDIS_STATUS=$(docker compose run --rm wp-cli wp redis status --allow-root 2>&1)
if echo "$REDIS_STATUS" | grep -q "Connected"; then
    echo -e "${GREEN}✓ Enabled${NC}"
else
    echo -e "${YELLOW}→ Check manually${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}  Site Health Fix Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Open WordPress admin: http://bpkad.bengkaliskab.go.id/wp-admin/"
echo "  2. Go to: Tools → Site Health"
echo "  3. Click: 'Info' tab"
echo "  4. Verify all sections show green/no errors"
echo ""

echo -e "${YELLOW}Expected Results:${NC}"
echo "  ✓ REST API: Response 200"
echo "  ✓ Scheduled Events: Working"
echo "  ✓ Object Cache: Redis enabled"
echo ""

echo -e "${YELLOW}Services Status:${NC}"
docker compose ps
echo ""

echo -e "${GREEN}✅ All done! Check WordPress Site Health now.${NC}"

