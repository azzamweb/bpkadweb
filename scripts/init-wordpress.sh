#!/bin/bash
#
# WordPress Initialization Script
# Sets up WordPress with WP-CLI
#
# Usage: docker compose run --rm wp-cli /scripts/init-wordpress.sh
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  WordPress Initialization Script${NC}"
echo -e "${GREEN}  BPKAD Kabupaten Bengkalis${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Wait for database to be ready
echo -e "${YELLOW}Waiting for database to be ready...${NC}"
sleep 10

# Check if wp-config.php already exists
if [ -f /var/www/html/wp-config.php ]; then
    echo -e "${YELLOW}WordPress is already configured.${NC}"
    echo -e "${YELLOW}To reinstall, remove wp-config.php and run again.${NC}"
    exit 0
fi

# Read database password from secret
if [ -f /run/secrets/db_password ]; then
    DB_PASSWORD=$(cat /run/secrets/db_password)
else
    echo -e "${RED}Error: Database password secret not found!${NC}"
    exit 1
fi

# Read WordPress admin password from secret
if [ -f /run/secrets/wp_admin_password ]; then
    WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
else
    echo -e "${RED}Error: WordPress admin password secret not found!${NC}"
    exit 1
fi

# Environment variables with defaults
WORDPRESS_DB_HOST=${WORDPRESS_DB_HOST:-mariadb}
WORDPRESS_DB_NAME=${WORDPRESS_DB_NAME:-wordpress}
WORDPRESS_DB_USER=${WORDPRESS_DB_USER:-wpuser}
WORDPRESS_DOMAIN=${WORDPRESS_DOMAIN:-bpkad.bengkaliskab.go.id}
WORDPRESS_LOCAL_IP=${WORDPRESS_LOCAL_IP:-10.10.10.31}

# WordPress site settings
SITE_TITLE=${WORDPRESS_TITLE:-"BPKAD Kabupaten Bengkalis"}
ADMIN_USER=${WORDPRESS_ADMIN_USER:-admin}
ADMIN_EMAIL=${WORDPRESS_ADMIN_EMAIL:-admin@bpkad.bengkaliskab.go.id}

echo -e "${GREEN}Creating wp-config.php...${NC}"

# Create wp-config.php
wp config create \
    --dbname="$WORDPRESS_DB_NAME" \
    --dbuser="$WORDPRESS_DB_USER" \
    --dbpass="$DB_PASSWORD" \
    --dbhost="$WORDPRESS_DB_HOST" \
    --dbcharset="utf8mb4" \
    --dbcollate="utf8mb4_unicode_ci" \
    --locale="id_ID" \
    --force \
    --allow-root

echo -e "${GREEN}Installing WordPress...${NC}"

# Install WordPress
wp core install \
    --url="http://${WORDPRESS_DOMAIN}" \
    --title="$SITE_TITLE" \
    --admin_user="$ADMIN_USER" \
    --admin_password="$WP_ADMIN_PASSWORD" \
    --admin_email="$ADMIN_EMAIL" \
    --skip-email \
    --allow-root

echo -e "${GREEN}Configuring WordPress settings...${NC}"

# Set permalink structure
wp rewrite structure '/%postname%/' --allow-root

# Update site URL to handle both domain and IP
wp option update home "http://${WORDPRESS_DOMAIN}" --allow-root
wp option update siteurl "http://${WORDPRESS_DOMAIN}" --allow-root

# Set timezone
wp option update timezone_string 'Asia/Jakarta' --allow-root

# Set default language
wp language core install id_ID --activate --allow-root

# Disable file editor (security)
wp config set DISALLOW_FILE_EDIT true --raw --allow-root

# Set memory limits
wp config set WP_MEMORY_LIMIT '256M' --allow-root
wp config set WP_MAX_MEMORY_LIMIT '512M' --allow-root

# Enable auto-updates for minor core versions
wp config set WP_AUTO_UPDATE_CORE 'minor' --allow-root

# Limit post revisions
wp config set WP_POST_REVISIONS 5 --raw --allow-root

# Set autosave interval (3 minutes)
wp config set AUTOSAVE_INTERVAL 180 --raw --allow-root

# Empty trash after 7 days
wp config set EMPTY_TRASH_DAYS 7 --raw --allow-root

# Add Cloudflare compatibility
wp config set WP_PROXY_BYPASS_HOSTS "${WORDPRESS_LOCAL_IP}" --allow-root

echo -e "${GREEN}Installing essential plugins...${NC}"

# Install and activate essential security plugins
wp plugin install wordfence --activate --allow-root || echo "Failed to install Wordfence"
wp plugin install limit-login-attempts-reloaded --activate --allow-root || echo "Failed to install Limit Login Attempts"

# Install and activate performance plugins
wp plugin install wp-super-cache --activate --allow-root || echo "Failed to install WP Super Cache"
wp plugin install autoptimize --activate --allow-root || echo "Failed to install Autoptimize"

# Install and activate backup plugin
wp plugin install updraftplus --activate --allow-root || echo "Failed to install UpdraftPlus"

# Install Indonesian language theme (optional)
# wp theme install twentytwentyfour --activate --allow-root

# Update all plugins and themes
wp plugin update --all --allow-root || echo "No plugin updates available"
wp theme update --all --allow-root || echo "No theme updates available"

echo -e "${GREEN}Disabling XML-RPC...${NC}"
# Disable XML-RPC via htaccess (will be handled by Nginx)
# wp plugin install disable-xml-rpc --activate --allow-root

echo -e "${GREEN}Optimizing database...${NC}"
wp db optimize --allow-root

echo -e "${GREEN}Flushing cache...${NC}"
wp cache flush --allow-root

echo -e "${GREEN}Setting proper file permissions...${NC}"
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  WordPress Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${GREEN}Site URL:${NC} http://${WORDPRESS_DOMAIN}"
echo -e "${GREEN}Local IP:${NC} http://${WORDPRESS_LOCAL_IP}"
echo -e "${GREEN}Admin URL:${NC} http://${WORDPRESS_DOMAIN}/wp-admin/"
echo -e "${GREEN}Admin User:${NC} ${ADMIN_USER}"
echo -e "${GREEN}Admin Password:${NC} ${WP_ADMIN_PASSWORD}"
echo ""
echo -e "${YELLOW}Important Next Steps:${NC}"
echo -e "1. Change admin password after first login"
echo -e "2. Configure Wordfence security settings"
echo -e "3. Set up UpdraftPlus backup schedule"
echo -e "4. Configure WP Super Cache settings"
echo -e "5. Review and configure Limit Login Attempts"
echo ""
echo -e "${RED}Save the admin password securely!${NC}"
echo ""

