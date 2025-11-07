#!/bin/bash

# Deploy MU Plugin to Production
# Script untuk menambahkan Must-Use plugin ke WordPress production

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Deploy MU Plugin${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if running from project root
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}Error: Run this script from project root!${NC}"
    exit 1
fi

# Check if MU plugin exists
MU_PLUGIN="wordpress/mu-plugins/remove-metabox-non-admin.php"
if [ ! -f "$MU_PLUGIN" ]; then
    echo -e "${RED}Error: MU plugin file not found: $MU_PLUGIN${NC}"
    exit 1
fi

echo -e "${YELLOW}MU Plugin to deploy:${NC}"
echo "  $MU_PLUGIN"
echo ""

# Check if PHP-FPM container is running
if ! docker compose ps php-fpm | grep -q "Up"; then
    echo -e "${RED}Error: PHP-FPM container is not running!${NC}"
    echo "Run: docker compose up -d"
    exit 1
fi

echo -e "${GREEN}[1/5] Creating mu-plugins directory...${NC}"
docker compose exec php-fpm mkdir -p /var/www/html/wp-content/mu-plugins
echo -e "${GREEN}✓ Directory created${NC}"
echo ""

echo -e "${GREEN}[2/5] Copying MU plugin to container...${NC}"
docker cp "$MU_PLUGIN" bpkad-php-fpm:/var/www/html/wp-content/mu-plugins/
echo -e "${GREEN}✓ Plugin copied${NC}"
echo ""

echo -e "${GREEN}[3/5] Setting correct permissions...${NC}"
docker compose exec -u root php-fpm chown -R www-data:www-data /var/www/html/wp-content/mu-plugins/
docker compose exec -u root php-fpm chmod 644 /var/www/html/wp-content/mu-plugins/remove-metabox-non-admin.php
echo -e "${GREEN}✓ Permissions set${NC}"
echo ""

echo -e "${GREEN}[4/5] Validating PHP syntax...${NC}"
if docker compose exec php-fpm php -l /var/www/html/wp-content/mu-plugins/remove-metabox-non-admin.php; then
    echo -e "${GREEN}✓ Syntax valid${NC}"
else
    echo -e "${RED}✗ Syntax error! Plugin not activated.${NC}"
    exit 1
fi
echo ""

echo -e "${GREEN}[5/5] Verifying installation...${NC}"
if docker compose exec php-fpm test -f /var/www/html/wp-content/mu-plugins/remove-metabox-non-admin.php; then
    echo -e "${GREEN}✓ Plugin installed successfully${NC}"
    
    # Show file info
    echo ""
    echo -e "${YELLOW}Plugin info:${NC}"
    docker compose exec php-fpm ls -lh /var/www/html/wp-content/mu-plugins/remove-metabox-non-admin.php
else
    echo -e "${RED}✗ Plugin not found after installation${NC}"
    exit 1
fi
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}  MU Plugin Deployed Successfully!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${YELLOW}What was done:${NC}"
echo "  ✓ Created mu-plugins directory"
echo "  ✓ Copied remove-metabox-non-admin.php"
echo "  ✓ Set permissions (644, www-data:www-data)"
echo "  ✓ Validated PHP syntax"
echo "  ✓ Plugin is now ACTIVE (always-on)"
echo ""

echo -e "${YELLOW}Testing:${NC}"
echo "  1. Login sebagai user non-admin"
echo "  2. Buka Create/Edit Post"
echo "  3. Metabox Jannah theme seharusnya hilang"
echo "  4. Login sebagai admin → metabox masih ada"
echo ""

echo -e "${YELLOW}Notes:${NC}"
echo "  • MU Plugins SELALU aktif (tidak bisa di-disable)"
echo "  • Tidak akan hilang saat update/ganti theme"
echo "  • Tidak perlu aktivasi manual"
echo ""

echo -e "${YELLOW}Manage MU Plugins:${NC}"
echo "  • List: docker compose exec php-fpm ls -lh /var/www/html/wp-content/mu-plugins/"
echo "  • View: docker compose exec php-fpm cat /var/www/html/wp-content/mu-plugins/remove-metabox-non-admin.php"
echo "  • Remove: docker compose exec php-fpm rm /var/www/html/wp-content/mu-plugins/remove-metabox-non-admin.php"
echo ""

echo -e "${GREEN}✅ Complete!${NC}"

