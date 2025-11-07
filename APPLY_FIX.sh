#!/bin/bash

# Robust fix script for wp-config.php
# Uses Python for safe configuration editing

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Robust WordPress Configuration Fix${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if in correct directory
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}Error: Run from project root!${NC}"
    exit 1
fi

# Check if services are running
if ! docker compose ps | grep -q "bpkad-php-fpm"; then
    echo -e "${RED}Error: PHP-FPM container not running!${NC}"
    echo "Start services: docker compose up -d"
    exit 1
fi

echo -e "${YELLOW}This script will:${NC}"
echo "  1. Copy wp-config.php from container"
echo "  2. Safely edit with Python script"
echo "  3. Validate syntax"
echo "  4. Copy back to container"
echo "  5. Restart services"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi
echo ""

# Step 1: Copy wp-config.php from container
echo -e "${GREEN}[1/7] Copying wp-config.php from container...${NC}"
docker cp bpkad-php-fpm:/var/www/html/wp-config.php ./wp-config.php.tmp
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ File copied${NC}"
else
    echo -e "${RED}✗ Failed to copy file${NC}"
    exit 1
fi
echo ""

# Step 2: Create backup
echo -e "${GREEN}[2/7] Creating local backup...${NC}"
cp ./wp-config.php.tmp ./wp-config.php.backup.local
echo -e "${GREEN}✓ Backup created: wp-config.php.backup.local${NC}"
echo ""

# Step 3: Run Python script to edit
echo -e "${GREEN}[3/7] Editing configuration with Python...${NC}"
python3 ./fix-wpconfig-safe.py ./wp-config.php.tmp
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Configuration edited successfully${NC}"
else
    echo -e "${RED}✗ Python script failed${NC}"
    rm -f ./wp-config.php.tmp
    exit 1
fi
echo ""

# Step 4: Validate PHP syntax (if php available locally)
echo -e "${GREEN}[4/7] Validating PHP syntax...${NC}"
if command -v php &> /dev/null; then
    php -l ./wp-config.php.tmp > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ PHP syntax valid (local check)${NC}"
    else
        echo -e "${RED}✗ PHP syntax error detected!${NC}"
        php -l ./wp-config.php.tmp
        echo "Restoring original..."
        rm -f ./wp-config.php.tmp
        exit 1
    fi
else
    echo -e "${YELLOW}→ PHP not available locally, will check in container${NC}"
fi
echo ""

# Step 5: Copy back to container
echo -e "${GREEN}[5/7] Copying updated file to container...${NC}"
docker cp ./wp-config.php.tmp bpkad-php-fpm:/var/www/html/wp-config.php
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ File copied to container${NC}"
else
    echo -e "${RED}✗ Failed to copy to container${NC}"
    exit 1
fi

# Set correct ownership
docker compose exec php-fpm chown www-data:www-data /var/www/html/wp-config.php
echo -e "${GREEN}✓ Ownership set to www-data${NC}"
echo ""

# Step 6: Validate in container
echo -e "${GREEN}[6/7] Validating syntax in container...${NC}"
docker compose exec php-fpm php -l /var/www/html/wp-config.php > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ PHP syntax valid in container${NC}"
else
    echo -e "${RED}✗ Syntax error in container!${NC}"
    docker compose exec php-fpm php -l /var/www/html/wp-config.php
    
    echo ""
    echo -e "${YELLOW}Restoring from backup...${NC}"
    docker cp ./wp-config.php.backup.local bpkad-php-fpm:/var/www/html/wp-config.php
    docker compose exec php-fpm chown www-data:www-data /var/www/html/wp-config.php
    echo -e "${GREEN}✓ Restored original file${NC}"
    
    rm -f ./wp-config.php.tmp
    exit 1
fi
echo ""

# Step 7: Restart services
echo -e "${GREEN}[7/7] Restarting services...${NC}"
docker compose restart php-fpm nginx
echo "Waiting for services to be ready..."
sleep 10
echo -e "${GREEN}✓ Services restarted${NC}"
echo ""

# Verification
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}  Verification${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check Redis config
echo -n "Redis config: "
if docker compose exec php-fpm grep -q "WP_REDIS_HOST" /var/www/html/wp-config.php; then
    echo -e "${GREEN}✓ Found${NC}"
else
    echo -e "${RED}✗ Not found${NC}"
fi

# Check REST API config
echo -n "REST API fix: "
if docker compose exec php-fpm grep -q "https_ssl_verify" /var/www/html/wp-config.php; then
    echo -e "${GREEN}✓ Found${NC}"
else
    echo -e "${RED}✗ Not found${NC}"
fi

# Test Redis connection
echo -n "Redis connection: "
REDIS_TEST=$(docker compose exec php-fpm php -r "\$redis = new Redis(); echo \$redis->connect('redis', 6379) ? 'OK' : 'FAIL';" 2>/dev/null)
if [ "$REDIS_TEST" = "OK" ]; then
    echo -e "${GREEN}✓ Connected${NC}"
else
    echo -e "${RED}✗ Failed${NC}"
fi

# Test website
echo -n "Website status: "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost 2>/dev/null)
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ HTTP $HTTP_CODE${NC}"
else
    echo -e "${YELLOW}→ HTTP $HTTP_CODE${NC}"
fi

echo ""

# Clean up
rm -f ./wp-config.php.tmp

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}  Configuration Applied Successfully!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Open: http://bpkad.bengkaliskab.go.id/wp-admin/"
echo ""
echo "2. Enable Redis Cache:"
echo "   Go to: Settings → Redis"
echo "   Click: 'Enable Object Cache'"
echo ""
echo "3. Check Site Health:"
echo "   Go to: Tools → Site Health"
echo "   REST API should show: Response 200 ✓"
echo "   Object Cache should show: Redis ✓"
echo ""
echo "Backup files:"
echo "  - Local: ./wp-config.php.backup.local"
echo "  - Container: /var/www/html/wp-config.php.backup.*"
echo ""

echo -e "${GREEN}✅ All done!${NC}"

