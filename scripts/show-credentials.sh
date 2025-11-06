#!/bin/bash
#
# Show WordPress Credentials
# Display all important credentials for WordPress admin
#

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  WordPress Credentials${NC}"
echo -e "${BLUE}  BPKAD Kabupaten Bengkalis${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if secrets exist
if [ ! -d "secrets" ]; then
    echo -e "${YELLOW}Warning: secrets directory not found${NC}"
    echo "Run: ./scripts/generate-secrets.sh"
    exit 1
fi

# WordPress Admin
echo -e "${GREEN}WordPress Admin:${NC}"
echo "-----------------------------------"
if [ -f "secrets/wp_admin_password.txt" ]; then
    WP_PASS=$(cat secrets/wp_admin_password.txt)
    echo "Admin URL: http://bpkad.bengkaliskab.go.id/wp-admin/"
    echo "Local URL: http://10.10.10.31/wp-admin/"
    echo "Username:  admin"
    echo "Password:  $WP_PASS"
else
    echo "Password file not found!"
fi
echo ""

# Database Credentials
echo -e "${GREEN}Database Credentials:${NC}"
echo "-----------------------------------"
if [ -f "secrets/db_password.txt" ]; then
    DB_PASS=$(cat secrets/db_password.txt)
    echo "Database:  wordpress"
    echo "Username:  wpuser"
    echo "Password:  $DB_PASS"
    echo "Host:      mariadb (internal) / 10.10.10.31:3306 (external)"
else
    echo "Password file not found!"
fi
echo ""

if [ -f "secrets/db_root_password.txt" ]; then
    DB_ROOT_PASS=$(cat secrets/db_root_password.txt)
    echo "Root User: root"
    echo "Root Pass: $DB_ROOT_PASS"
    echo ""
fi

# WordPress Users from Database
echo -e "${GREEN}WordPress Users:${NC}"
echo "-----------------------------------"
docker compose run --rm wp-cli wp user list --allow-root 2>/dev/null || echo "Could not retrieve users"
echo ""

# URLs
echo -e "${GREEN}Access URLs:${NC}"
echo "-----------------------------------"
echo "Website:       http://bpkad.bengkaliskab.go.id"
echo "Local IP:      http://10.10.10.31"
echo "Admin Panel:   http://bpkad.bengkaliskab.go.id/wp-admin/"
echo "Adminer:       http://10.10.10.31:8080 (if enabled)"
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}⚠️  Keep these credentials secure!${NC}"
echo -e "${BLUE}========================================${NC}"

