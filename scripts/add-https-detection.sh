#!/bin/bash

# Add HTTPS Detection to wp-config.php
# Fixes Mixed Content warnings when using Cloudflare

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Add HTTPS Detection to wp-config.php${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check directory
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}Error: Run from project root!${NC}"
    exit 1
fi

# Check if container is running
if ! docker compose ps | grep -q "bpkad-php-fpm"; then
    echo -e "${RED}Error: PHP-FPM container not running!${NC}"
    echo "Start services: docker compose up -d"
    exit 1
fi

echo -e "${YELLOW}This will add HTTPS detection code to wp-config.php${NC}"
echo "This fixes Mixed Content warnings when using Cloudflare/reverse proxy."
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi
echo ""

# Step 1: Check if already exists
echo -e "${GREEN}[1/6] Checking if HTTPS detection already exists...${NC}"
if docker compose exec php-fpm grep -q "HTTP_X_FORWARDED_PROTO" /var/www/html/wp-config.php 2>/dev/null; then
    echo -e "${YELLOW}→ HTTPS detection code already exists${NC}"
    echo "No changes needed."
    exit 0
fi
echo -e "${GREEN}✓ Not found, will add${NC}"
echo ""

# Step 2: Backup
echo -e "${GREEN}[2/6] Creating backup...${NC}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
docker compose exec php-fpm cp /var/www/html/wp-config.php /var/www/html/wp-config.php.backup.$TIMESTAMP
echo -e "${GREEN}✓ Backup created: wp-config.php.backup.$TIMESTAMP${NC}"
echo ""

# Step 3: Create HTTPS detection code
echo -e "${GREEN}[3/6] Creating HTTPS detection code...${NC}"
docker compose exec php-fpm sh -c 'cat > /tmp/https-detection.php << '\''PHPCODE'\''

/* Force HTTPS Detection from Cloudflare/Reverse Proxy */
if (isset($_SERVER["HTTP_X_FORWARDED_PROTO"]) && $_SERVER["HTTP_X_FORWARDED_PROTO"] === "https") {
    $_SERVER["HTTPS"] = "on";
}
PHPCODE
'
echo -e "${GREEN}✓ Code created${NC}"
echo ""

# Step 4: Insert code
echo -e "${GREEN}[4/6] Inserting code into wp-config.php...${NC}"
docker compose exec php-fpm sh -c '
# Create new file with HTTPS detection after <?php
head -n 1 /var/www/html/wp-config.php > /tmp/wp-config-new.php
echo "" >> /tmp/wp-config-new.php
cat /tmp/https-detection.php >> /tmp/wp-config-new.php
echo "" >> /tmp/wp-config-new.php
tail -n +2 /var/www/html/wp-config.php >> /tmp/wp-config-new.php

# Replace original
mv /tmp/wp-config-new.php /var/www/html/wp-config.php
'
echo -e "${GREEN}✓ Code inserted${NC}"
echo ""

# Step 5: Fix permissions
echo -e "${GREEN}[5/6] Fixing permissions...${NC}"
docker compose exec -u root php-fpm chown www-data:www-data /var/www/html/wp-config.php
docker compose exec -u root php-fpm chmod 644 /var/www/html/wp-config.php
echo -e "${GREEN}✓ Permissions fixed${NC}"
echo ""

# Step 6: Validate
echo -e "${GREEN}[6/6] Validating PHP syntax...${NC}"
if docker compose exec php-fpm php -l /var/www/html/wp-config.php > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Syntax valid${NC}"
else
    echo -e "${RED}✗ Syntax error detected!${NC}"
    echo "Restoring backup..."
    docker compose exec php-fpm cp /var/www/html/wp-config.php.backup.$TIMESTAMP /var/www/html/wp-config.php
    echo -e "${GREEN}✓ Backup restored${NC}"
    exit 1
fi
echo ""

# Restart services
echo -e "${GREEN}Restarting services...${NC}"
docker compose restart php-fpm nginx
echo "Waiting for services..."
sleep 10
echo -e "${GREEN}✓ Services restarted${NC}"
echo ""

# Verification
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}  HTTPS Detection Added Successfully!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Show the code
echo -e "${YELLOW}Code added to wp-config.php:${NC}"
docker compose exec php-fpm head -10 /var/www/html/wp-config.php | grep -A5 "HTTPS Detection" || true
echo ""

echo -e "${YELLOW}Next steps:${NC}"
echo "1. Clear browser cache (Ctrl+Shift+Del)"
echo "2. Hard reload page (Ctrl+F5)"
echo "3. Mixed Content warnings should be GONE!"
echo ""

echo -e "${YELLOW}Verify:${NC}"
echo "• Open browser dev tools (F12)"
echo "• Go to Console tab"
echo "• Mixed Content warnings should not appear"
echo "• All resources should load via HTTPS"
echo ""

echo -e "${YELLOW}Backup location:${NC}"
echo "Container: /var/www/html/wp-config.php.backup.$TIMESTAMP"
echo ""

echo -e "${GREEN}✅ Complete!${NC}"

