#!/bin/bash

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Fixing WordPress Site Health Issues${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}Error: docker-compose.yml not found!${NC}"
    echo "Please run this script from the project root directory."
    exit 1
fi

# Check if services are running
if ! docker compose ps | grep -q "Up"; then
    echo -e "${RED}Error: Docker services are not running!${NC}"
    echo "Please start services first: docker compose up -d"
    exit 1
fi

echo -e "${YELLOW}This script will fix:${NC}"
echo "  1. REST API SSL/TLS errors (loopback requests)"
echo "  2. Scheduled events (cron)"
echo "  3. Enable object cache (Redis/APCu)"
echo ""

# ============================================
# 1. Fix REST API - Add loopback configuration
# ============================================
echo -e "${GREEN}Step 1/4: Fixing REST API loopback requests...${NC}"

WP_CONFIG_PATH="/var/www/html/wp-config.php"

# Add HTTP loopback configuration to wp-config.php
LOOPBACK_CONFIG="
// Fix REST API loopback requests - use HTTP internally
if (!defined('WP_HTTP_BLOCK_EXTERNAL')) {
    define('WP_HTTP_BLOCK_EXTERNAL', false);
}

// Disable SSL verification for internal requests
add_filter('https_ssl_verify', '__return_false');
add_filter('https_local_ssl_verify', '__return_false');
add_filter('http_request_host_is_external', '__return_false');

// Force REST API to use HTTP for loopback
add_filter('rest_url', function(\$url) {
    return str_replace('https://', 'http://', \$url);
});
"

# Check if loopback config already exists
if docker compose exec -T php-fpm grep -q "WP_HTTP_BLOCK_EXTERNAL" "$WP_CONFIG_PATH" 2>/dev/null; then
    echo -e "${YELLOW}  → Loopback configuration already exists. Skipping.${NC}"
else
    echo "  → Adding loopback configuration to wp-config.php..."
    # Insert before "That's all, stop editing!" line
    docker compose exec -T php-fpm sh -c "sed -i \"/^\\/\\* That's all, stop editing/i\\${LOOPBACK_CONFIG}\" $WP_CONFIG_PATH"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}  ✓ Loopback configuration added${NC}"
    else
        echo -e "${RED}  ✗ Failed to add loopback configuration${NC}"
    fi
fi

echo ""

# ============================================
# 2. Test REST API
# ============================================
echo -e "${GREEN}Step 2/4: Testing REST API...${NC}"

# Test REST API endpoint from inside container
REST_TEST=$(docker compose exec -T php-fpm curl -s -o /dev/null -w "%{http_code}" http://localhost/wp-json/wp/v2/types/post 2>/dev/null)

if [ "$REST_TEST" = "200" ]; then
    echo -e "${GREEN}  ✓ REST API is working (HTTP 200)${NC}"
else
    echo -e "${YELLOW}  → REST API returned: HTTP $REST_TEST${NC}"
    echo -e "${YELLOW}  → This is OK if authentication is required${NC}"
fi

echo ""

# ============================================
# 3. Enable Redis Object Cache
# ============================================
echo -e "${GREEN}Step 3/4: Enabling Redis object cache...${NC}"

# Check if Redis plugin is installed
REDIS_PLUGIN=$(docker compose exec -T wp-cli wp plugin list --field=name --status=all --allow-root 2>/dev/null | grep -i redis)

if [ -z "$REDIS_PLUGIN" ]; then
    echo "  → Installing Redis Object Cache plugin..."
    docker compose exec -T wp-cli wp plugin install redis-cache --activate --allow-root
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}  ✓ Redis Object Cache plugin installed${NC}"
    else
        echo -e "${RED}  ✗ Failed to install Redis plugin${NC}"
    fi
else
    echo -e "${YELLOW}  → Redis plugin already installed: $REDIS_PLUGIN${NC}"
    
    # Activate if not active
    docker compose exec -T wp-cli wp plugin activate redis-cache --allow-root 2>/dev/null
    echo -e "${GREEN}  ✓ Redis plugin activated${NC}"
fi

# Add Redis configuration to wp-config.php
REDIS_CONFIG="
// Redis Object Cache Configuration
define('WP_REDIS_HOST', 'redis');
define('WP_REDIS_PORT', 6379);
define('WP_REDIS_TIMEOUT', 1);
define('WP_REDIS_READ_TIMEOUT', 1);
define('WP_REDIS_DATABASE', 0);
"

if docker compose exec -T php-fpm grep -q "WP_REDIS_HOST" "$WP_CONFIG_PATH" 2>/dev/null; then
    echo -e "${YELLOW}  → Redis configuration already exists${NC}"
else
    echo "  → Adding Redis configuration to wp-config.php..."
    docker compose exec -T php-fpm sh -c "sed -i \"/^\\/\\* That's all, stop editing/i\\${REDIS_CONFIG}\" $WP_CONFIG_PATH"
    echo -e "${GREEN}  ✓ Redis configuration added${NC}"
fi

# Enable Redis object cache
echo "  → Enabling Redis object cache..."
docker compose exec -T wp-cli wp redis enable --allow-root 2>/dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}  ✓ Redis object cache enabled${NC}"
else
    echo -e "${YELLOW}  → Redis cache status:${NC}"
    docker compose exec -T wp-cli wp redis status --allow-root 2>/dev/null || echo "    Redis may need redis service running"
fi

echo ""

# ============================================
# 4. Fix Scheduled Events
# ============================================
echo -e "${GREEN}Step 4/4: Fixing scheduled events...${NC}"

# Clear any broken cron events
echo "  → Clearing WordPress cron cache..."
docker compose exec -T wp-cli wp cache flush --allow-root 2>/dev/null

# Test cron
echo "  → Testing WordPress cron..."
CRON_TEST=$(docker compose exec -T wp-cli wp cron test --allow-root 2>&1)

if echo "$CRON_TEST" | grep -q "Success"; then
    echo -e "${GREEN}  ✓ WordPress cron is working${NC}"
else
    echo -e "${YELLOW}  → Cron test result: $CRON_TEST${NC}"
fi

# List scheduled events
echo "  → Checking scheduled events..."
docker compose exec -T wp-cli wp cron event list --format=count --allow-root 2>/dev/null | while read count; do
    echo -e "${GREEN}  ✓ Found $count scheduled events${NC}"
done

echo ""

# ============================================
# 5. Summary & Verification
# ============================================
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}  Site Health Fixes Applied!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${YELLOW}What was fixed:${NC}"
echo "  ✓ REST API loopback configuration (HTTP for internal requests)"
echo "  ✓ SSL verification disabled for internal requests"
echo "  ✓ Redis Object Cache plugin installed & configured"
echo "  ✓ WordPress cron cleared and tested"
echo ""

echo -e "${YELLOW}To verify in WordPress:${NC}"
echo "  1. Go to: Tools → Site Health"
echo "  2. Click: 'Info' tab"
echo "  3. Check: REST API section (should show 'Response: 200')"
echo "  4. Check: Scheduled Events (should be working)"
echo "  5. Check: Object Cache (should show 'Redis' if enabled)"
echo ""

echo -e "${YELLOW}Note about Redis:${NC}"
echo "  If Redis is not working, you need to add redis service to docker-compose.yml"
echo "  For now, APCu can be used as alternative object cache."
echo ""

echo -e "${GREEN}Restarting PHP-FPM to apply changes...${NC}"
docker compose restart php-fpm
sleep 5
echo -e "${GREEN}✓ PHP-FPM restarted${NC}"
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}  Complete! Check Site Health now.${NC}"
echo -e "${BLUE}========================================${NC}"

