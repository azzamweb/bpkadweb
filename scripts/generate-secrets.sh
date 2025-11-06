#!/bin/bash
#
# Generate Secrets Script for WordPress Docker Project
# Generates secure passwords and WordPress salts
#
# Usage: ./scripts/generate-secrets.sh
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  WordPress Docker Secrets Generator${NC}"
echo -e "${GREEN}  BPKAD Kabupaten Bengkalis${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Create secrets directory if not exists
SECRETS_DIR="./secrets"
if [ ! -d "$SECRETS_DIR" ]; then
    echo -e "${YELLOW}Creating secrets directory...${NC}"
    mkdir -p "$SECRETS_DIR"
    chmod 700 "$SECRETS_DIR"
fi

# Function to generate random password
generate_password() {
    local length=${1:-32}
    openssl rand -base64 48 | tr -dc 'A-Za-z0-9!@#$%^&*()_+-=' | head -c "$length"
}

# Function to check if secret already exists
check_existing() {
    local file=$1
    if [ -f "$file" ]; then
        echo -e "${YELLOW}Warning: $file already exists.${NC}"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${GREEN}Skipping $file${NC}"
            return 1
        fi
    fi
    return 0
}

# Generate database root password
if check_existing "$SECRETS_DIR/db_root_password.txt"; then
    echo -e "${GREEN}Generating database root password...${NC}"
    generate_password 32 > "$SECRETS_DIR/db_root_password.txt"
    chmod 600 "$SECRETS_DIR/db_root_password.txt"
    echo -e "${GREEN}✓ Database root password generated${NC}"
fi

# Generate database user password
if check_existing "$SECRETS_DIR/db_password.txt"; then
    echo -e "${GREEN}Generating database user password...${NC}"
    generate_password 32 > "$SECRETS_DIR/db_password.txt"
    chmod 600 "$SECRETS_DIR/db_password.txt"
    echo -e "${GREEN}✓ Database user password generated${NC}"
fi

# Generate WordPress admin password
if check_existing "$SECRETS_DIR/wp_admin_password.txt"; then
    echo -e "${GREEN}Generating WordPress admin password...${NC}"
    generate_password 24 > "$SECRETS_DIR/wp_admin_password.txt"
    chmod 600 "$SECRETS_DIR/wp_admin_password.txt"
    echo -e "${GREEN}✓ WordPress admin password generated${NC}"
fi

# Generate WordPress salts
if check_existing "$SECRETS_DIR/wp_salts.txt"; then
    echo -e "${GREEN}Generating WordPress authentication salts...${NC}"
    
    # Try to fetch from WordPress API
    if command -v curl &> /dev/null; then
        curl -s https://api.wordpress.org/secret-key/1.1/salt/ > "$SECRETS_DIR/wp_salts.txt" 2>/dev/null || {
            echo -e "${YELLOW}Failed to fetch from WordPress API, generating locally...${NC}"
            # Generate salts locally if API fails
            cat > "$SECRETS_DIR/wp_salts.txt" << EOF
define('AUTH_KEY',         '$(generate_password 64)');
define('SECURE_AUTH_KEY',  '$(generate_password 64)');
define('LOGGED_IN_KEY',    '$(generate_password 64)');
define('NONCE_KEY',        '$(generate_password 64)');
define('AUTH_SALT',        '$(generate_password 64)');
define('SECURE_AUTH_SALT', '$(generate_password 64)');
define('LOGGED_IN_SALT',   '$(generate_password 64)');
define('NONCE_SALT',       '$(generate_password 64)');
EOF
        }
    else
        echo -e "${YELLOW}curl not found, generating salts locally...${NC}"
        cat > "$SECRETS_DIR/wp_salts.txt" << EOF
define('AUTH_KEY',         '$(generate_password 64)');
define('SECURE_AUTH_KEY',  '$(generate_password 64)');
define('LOGGED_IN_KEY',    '$(generate_password 64)');
define('NONCE_KEY',        '$(generate_password 64)');
define('AUTH_SALT',        '$(generate_password 64)');
define('SECURE_AUTH_SALT', '$(generate_password 64)');
define('LOGGED_IN_SALT',   '$(generate_password 64)');
define('NONCE_SALT',       '$(generate_password 64)');
EOF
    fi
    
    chmod 600 "$SECRETS_DIR/wp_salts.txt"
    echo -e "${GREEN}✓ WordPress salts generated${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Secrets Generated Successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Important:${NC}"
echo -e "1. Secrets are stored in: ${SECRETS_DIR}/"
echo -e "2. Keep these files secure and never commit to git"
echo -e "3. Backup these files in a secure location"
echo ""
echo -e "${GREEN}Generated files:${NC}"
ls -lh "$SECRETS_DIR/"
echo ""
echo -e "${YELLOW}WordPress Admin Password:${NC}"
cat "$SECRETS_DIR/wp_admin_password.txt"
echo ""
echo -e "${YELLOW}Database Root Password:${NC}"
cat "$SECRETS_DIR/db_root_password.txt"
echo ""
echo -e "${RED}Make sure to save these passwords securely!${NC}"
echo ""

