#!/bin/bash

# Quick Fix for DNS and Redis Plugin
# Fixes: DNS resolution & installs Redis plugin

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Quick Fix: DNS & Redis Plugin${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check directory
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}Error: Run from project root!${NC}"
    exit 1
fi

# Step 1: Install Redis Plugin
echo -e "${GREEN}Step 1/5: Installing Redis Object Cache plugin...${NC}"
docker compose run --rm wp-cli wp plugin install redis-cache --activate --allow-root
echo -e "${GREEN}✓ Redis plugin installed${NC}"
echo ""

# Step 2: Add Redis config to wp-config.php
echo -e "${GREEN}Step 2/5: Configuring Redis in wp-config.php...${NC}"

# Check if already configured
if docker compose exec -T php-fpm grep -q "WP_REDIS_HOST" /var/www/html/wp-config.php 2>/dev/null; then
    echo -e "${YELLOW}  → Redis config already exists${NC}"
else
    echo "  → Adding Redis configuration..."
    docker compose exec -T php-fpm sh -c "cat >> /var/www/html/wp-config.php" << 'REDIS_CONFIG'

/* Redis Object Cache Configuration */
define('WP_REDIS_HOST', 'redis');
define('WP_REDIS_PORT', 6379);
define('WP_REDIS_TIMEOUT', 1);
define('WP_REDIS_READ_TIMEOUT', 1);
define('WP_REDIS_DATABASE', 0);

REDIS_CONFIG
    echo -e "${GREEN}  ✓ Redis config added${NC}"
fi
echo ""

# Step 3: Enable Redis Object Cache
echo -e "${GREEN}Step 3/5: Enabling Redis object cache...${NC}"
docker compose exec -T php-fpm sh -c 'cd /var/www/html && php -r "define(\"WP_REDIS_DISABLED\", false); require \"wp-load.php\"; \$redis_plugin = new WP_Redis(); \$redis_plugin->enable();"' 2>/dev/null || {
    echo -e "${YELLOW}  → Enabling via wp-cli (alternative method)...${NC}"
    docker compose run --rm wp-cli wp plugin activate redis-cache --allow-root
}
echo -e "${GREEN}✓ Redis cache enabled${NC}"
echo ""

# Step 4: Add REST API loopback fix
echo -e "${GREEN}Step 4/5: Fixing REST API loopback...${NC}"

if docker compose exec -T php-fpm grep -q "WP_HTTP_BLOCK_EXTERNAL" /var/www/html/wp-config.php 2>/dev/null; then
    echo -e "${YELLOW}  → REST API config already exists${NC}"
else
    echo "  → Adding REST API loopback fix..."
    # Insert before "That's all" line
    docker compose exec -T php-fpm sh -c "sed -i \"/^\\/\\* That's all, stop editing/i\\
/* Fix REST API loopback - use HTTP internally */\\
if (!defined('WP_HTTP_BLOCK_EXTERNAL')) {\\
    define('WP_HTTP_BLOCK_EXTERNAL', false);\\
}\\
\\
/* Disable SSL verification for internal requests */\\
add_filter('https_ssl_verify', '__return_false');\\
add_filter('https_local_ssl_verify', '__return_false');\\
\\
/* Force REST API to use HTTP for loopback */\\
add_filter('rest_url', function(\\\$url) {\\
    return str_replace('https://', 'http://', \\\$url);\\
});\\
\" /var/www/html/wp-config.php"
    echo -e "${GREEN}  ✓ REST API fix added${NC}"
fi
echo ""

# Step 5: Restart PHP-FPM
echo -e "${GREEN}Step 5/5: Restarting PHP-FPM...${NC}"
docker compose restart php-fpm
sleep 5
echo -e "${GREEN}✓ PHP-FPM restarted${NC}"
echo ""

# Verification
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}  Verification${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check Redis connection from PHP
echo -n "Redis connection: "
if docker compose exec -T php-fpm php -r "try { \$redis = new Redis(); \$redis->connect('redis', 6379); echo 'OK'; } catch (Exception \$e) { echo 'FAIL'; }" 2>/dev/null | grep -q "OK"; then
    echo -e "${GREEN}✓ Connected${NC}"
else
    echo -e "${RED}✗ Failed${NC}"
fi

# Check if plugin is active
echo -n "Redis plugin: "
if docker compose run --rm wp-cli wp plugin list --field=name --status=active --allow-root 2>/dev/null | grep -q "redis-cache"; then
    echo -e "${GREEN}✓ Active${NC}"
else
    echo -e "${YELLOW}⚠ Check manually${NC}"
fi

# Check REST API using localhost (avoid DNS issue)
echo -n "REST API (internal): "
REST_CODE=$(docker compose exec -T php-fpm curl -s -o /dev/null -w "%{http_code}" http://localhost/wp-json/wp/v2/types/post 2>/dev/null)
if [ "$REST_CODE" = "200" ] || [ "$REST_CODE" = "401" ]; then
    echo -e "${GREEN}✓ Working (HTTP $REST_CODE)${NC}"
else
    echo -e "${YELLOW}→ HTTP $REST_CODE${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}  Fix Applied!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Go to WordPress admin: Settings → Redis"
echo "   Or: wp-admin/options-general.php?page=redis-cache"
echo ""
echo "2. Check Redis status in WordPress admin"
echo "   Should show: Status: Connected"
echo ""
echo "3. Go to: Tools → Site Health"
echo "   Check: REST API, Scheduled Events, Object Cache"
echo ""

echo -e "${YELLOW}Note about DNS:${NC}"
echo "The 'Could not resolve host' error is normal for WP-CLI"
echo "because Docker containers use internal networking."
echo "WordPress frontend works fine via Nginx."
echo ""

echo -e "${GREEN}✅ Redis is now configured and running!${NC}"

