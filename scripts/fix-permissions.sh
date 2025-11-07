#!/bin/bash
#
# Fix WordPress Permissions
# Sets correct ownership and permissions for WordPress files and directories
#
# Usage: ./scripts/fix-permissions.sh
#

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Fix WordPress Permissions${NC}"
echo -e "${BLUE}  BPKAD Kabupaten Bengkalis${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${YELLOW}This will fix permissions for:${NC}"
echo "  • wp-content/uploads/"
echo "  • wp-content/plugins/"
echo "  • wp-content/themes/"
echo "  • wp-content/cache/"
echo "  • wp-content/upgrade/"
echo ""

# Fix ownership and permissions
echo -e "${GREEN}Fixing permissions (running as root)...${NC}"

docker compose exec -u root php-fpm bash -c '
# Set correct ownership (www-data)
chown -R www-data:www-data /var/www/html/wp-content

# Set directory permissions (755)
find /var/www/html/wp-content -type d -exec chmod 755 {} \;

# Set file permissions (644)
find /var/www/html/wp-content -type f -exec chmod 644 {} \;

# Ensure uploads directory exists and is writable
mkdir -p /var/www/html/wp-content/uploads
chmod 755 /var/www/html/wp-content/uploads
chown -R www-data:www-data /var/www/html/wp-content/uploads

# Ensure plugins directory is writable
mkdir -p /var/www/html/wp-content/plugins
chmod 755 /var/www/html/wp-content/plugins
chown -R www-data:www-data /var/www/html/wp-content/plugins

# Ensure themes directory is writable
mkdir -p /var/www/html/wp-content/themes
chmod 755 /var/www/html/wp-content/themes
chown -R www-data:www-data /var/www/html/wp-content/themes

# Ensure cache directory is writable
mkdir -p /var/www/html/wp-content/cache
chmod 755 /var/www/html/wp-content/cache
chown -R www-data:www-data /var/www/html/wp-content/cache

# Ensure upgrade directory is writable
mkdir -p /var/www/html/wp-content/upgrade
chmod 755 /var/www/html/wp-content/upgrade
chown -R www-data:www-data /var/www/html/wp-content/upgrade

echo "✓ Permissions fixed"
'

echo ""
echo -e "${GREEN}Verifying permissions...${NC}"

docker compose exec php-fpm bash -c '
echo "wp-content ownership:"
ls -ld /var/www/html/wp-content | awk "{print \$3\":\"\$4\" \"\$1}"

echo ""
echo "wp-content/uploads ownership:"
ls -ld /var/www/html/wp-content/uploads 2>/dev/null | awk "{print \$3\":\"\$4\" \"\$1}" || echo "Directory created"

echo ""
echo "wp-content/plugins ownership:"
ls -ld /var/www/html/wp-content/plugins | awk "{print \$3\":\"\$4\" \"\$1}"

echo ""
echo "wp-content/themes ownership:"
ls -ld /var/www/html/wp-content/themes | awk "{print \$3\":\"\$4\" \"\$1}"
'

echo ""
echo -e "${GREEN}Restarting PHP-FPM container...${NC}"
docker compose restart php-fpm
echo "Waiting for container to be ready..."
sleep 5
echo "✓ Container restarted"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}  Permissions Fixed Successfully!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}You can now:${NC}"
echo "  ✓ Upload media files"
echo "  ✓ Install plugins"
echo "  ✓ Install themes"
echo "  ✓ Update WordPress core"
echo ""
echo -e "${YELLOW}Try uploading your plugin again!${NC}"
echo ""

