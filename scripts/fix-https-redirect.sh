#!/bin/bash
#
# Fix HTTPS Redirect Loop
# Fixes ERR_TOO_MANY_REDIRECTS issue when switching to HTTPS
#
# Usage: ./scripts/fix-https-redirect.sh
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Fix HTTPS Redirect Loop${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${YELLOW}This will:${NC}"
echo "1. Reset WordPress URLs to HTTP"
echo "2. Add HTTPS support via Cloudflare headers"
echo "3. Clear all caches"
echo ""

# Reset URLs to HTTP
echo -e "${GREEN}Step 1: Resetting URLs to HTTP...${NC}"
docker compose run --rm wp-cli wp option update home 'http://bpkad.bengkaliskab.go.id' --allow-root
docker compose run --rm wp-cli wp option update siteurl 'http://bpkad.bengkaliskab.go.id' --allow-root
echo "✓ URLs reset to HTTP"
echo ""

# Add HTTPS detection code to wp-config.php
echo -e "${GREEN}Step 2: Adding HTTPS detection to wp-config.php...${NC}"
docker compose exec php-fpm bash -c "
if ! grep -q 'HTTP_X_FORWARDED_PROTO' /var/www/html/wp-config.php; then
    # Find the line before 'That's all, stop editing'
    sed -i \"/That's all, stop editing/i\\
\\
// Force HTTPS detection from Cloudflare\\
if (isset(\\\$_SERVER['HTTP_X_FORWARDED_PROTO']) && \\\$_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {\\
    \\\$_SERVER['HTTPS'] = 'on';\\
}\\
\" /var/www/html/wp-config.php
    echo '✓ HTTPS detection code added'
else
    echo '✓ HTTPS detection code already exists'
fi
"
echo ""

# Clear cache
echo -e "${GREEN}Step 3: Clearing caches...${NC}"
docker compose run --rm wp-cli wp cache flush --allow-root
echo "✓ Cache cleared"
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Fix Applied Successfully!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Clear your browser cookies/cache"
echo "2. Try accessing: http://bpkad.bengkaliskab.go.id/wp-admin/"
echo "3. Cloudflare will handle HTTPS automatically"
echo ""
echo -e "${YELLOW}Note:${NC}"
echo "- Keep WordPress URLs as HTTP (internal)"
echo "- Cloudflare handles HTTPS (external)"
echo "- Users will see HTTPS in browser"
echo "- Server communicates via HTTP internally"
echo ""

