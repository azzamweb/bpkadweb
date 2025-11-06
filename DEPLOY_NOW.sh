#!/bin/bash
#
# Quick Deploy Script for Production Fix
# Run this on production server: /var/www/bpkadweb
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  BPKAD WordPress - Production Fix${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if in correct directory
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}Error: docker-compose.yml not found!${NC}"
    echo "Please run this script from project root: /var/www/bpkadweb"
    exit 1
fi

echo -e "${YELLOW}This script will:${NC}"
echo "1. Pull latest changes from git"
echo "2. Stop current containers"
echo "3. Rebuild images with fixes"
echo "4. Start services"
echo "5. Verify deployment"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo -e "${GREEN}Step 1: Pulling latest changes...${NC}"
git pull origin main || {
    echo -e "${YELLOW}Warning: Git pull failed. Continuing with local files...${NC}"
}

echo ""
echo -e "${GREEN}Step 2: Stopping containers...${NC}"
docker compose down

echo ""
echo -e "${GREEN}Step 3: Removing old images...${NC}"
docker rmi bpkadweb-php-fpm bpkadweb-backup 2>/dev/null || true
echo "Old images removed (if existed)"

echo ""
echo -e "${GREEN}Step 4: Building new images...${NC}"
docker compose build --no-cache

echo ""
echo -e "${GREEN}Step 5: Starting services...${NC}"
docker compose up -d

echo ""
echo -e "${YELLOW}Waiting for services to be healthy (30 seconds)...${NC}"
sleep 30

echo ""
echo -e "${GREEN}Step 6: Checking status...${NC}"
docker compose ps

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Deployment Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check PHP-FPM
if docker compose ps | grep -q "bpkad-php-fpm.*healthy"; then
    echo -e "${GREEN}✓ PHP-FPM: Healthy${NC}"
else
    echo -e "${RED}✗ PHP-FPM: Not Healthy${NC}"
    echo -e "${YELLOW}Check logs: docker compose logs php-fpm${NC}"
fi

# Check Backup
if docker compose ps | grep -q "bpkad-backup.*Up"; then
    echo -e "${GREEN}✓ Backup: Running${NC}"
    # Check if cron is running
    if docker compose exec backup ps aux 2>/dev/null | grep -q crond; then
        echo -e "${GREEN}  ✓ Cron: Active${NC}"
    else
        echo -e "${YELLOW}  ⚠ Cron: Check manually${NC}"
    fi
else
    echo -e "${RED}✗ Backup: Not Running${NC}"
fi

# Check Nginx
if docker compose ps | grep -q "bpkad-nginx.*Up"; then
    echo -e "${GREEN}✓ Nginx: Running${NC}"
else
    echo -e "${RED}✗ Nginx: Not Running${NC}"
fi

# Check MariaDB
if docker compose ps | grep -q "bpkad-mariadb.*healthy"; then
    echo -e "${GREEN}✓ MariaDB: Healthy${NC}"
else
    echo -e "${RED}✗ MariaDB: Not Healthy${NC}"
fi

echo ""

# Test website
if curl -sf http://localhost > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Website: Accessible${NC}"
else
    echo -e "${YELLOW}⚠ Website: Not accessible yet (may need WordPress init)${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Deployment completed!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Check logs: ${GREEN}docker compose logs${NC}"
echo "2. Test backup: ${GREEN}docker compose exec backup /usr/local/bin/backup-db.sh${NC}"
echo "3. Access website: ${GREEN}http://10.10.10.31${NC}"
echo ""
echo "For detailed guide, see: PRODUCTION_FIX.md"
echo ""

