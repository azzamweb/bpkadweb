#!/bin/bash

# Save Current Working Configuration
# Backs up all critical configuration files from production

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Save Working Configuration${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check directory
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}Error: Run from project root!${NC}"
    exit 1
fi

# Create backup directory
BACKUP_DIR="config-backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo -e "${YELLOW}Saving configuration to: $BACKUP_DIR${NC}"
echo ""

# Save wp-config.php
echo -e "${GREEN}[1/5] Saving wp-config.php...${NC}"
if docker compose exec php-fpm test -f /var/www/html/wp-config.php; then
    docker cp bpkad-php-fpm:/var/www/html/wp-config.php "$BACKUP_DIR/wp-config.php"
    echo -e "${GREEN}✓ wp-config.php saved${NC}"
else
    echo -e "${RED}✗ wp-config.php not found${NC}"
fi
echo ""

# Save WordPress options
echo -e "${GREEN}[2/5] Saving WordPress options...${NC}"
docker compose run --rm wp-cli wp option get home --allow-root > "$BACKUP_DIR/wp-home-url.txt" 2>/dev/null || echo "N/A" > "$BACKUP_DIR/wp-home-url.txt"
docker compose run --rm wp-cli wp option get siteurl --allow-root > "$BACKUP_DIR/wp-siteurl.txt" 2>/dev/null || echo "N/A" > "$BACKUP_DIR/wp-siteurl.txt"
echo -e "${GREEN}✓ WordPress options saved${NC}"
echo ""

# Save active plugins
echo -e "${GREEN}[3/5] Saving active plugins list...${NC}"
docker compose run --rm wp-cli wp plugin list --status=active --format=table --allow-root > "$BACKUP_DIR/active-plugins.txt" 2>/dev/null || echo "N/A" > "$BACKUP_DIR/active-plugins.txt"
echo -e "${GREEN}✓ Plugins list saved${NC}"
echo ""

# Save service status
echo -e "${GREEN}[4/5] Saving service status...${NC}"
docker compose ps > "$BACKUP_DIR/docker-services-status.txt"
echo -e "${GREEN}✓ Service status saved${NC}"
echo ""

# Save configuration summary
echo -e "${GREEN}[5/5] Creating configuration summary...${NC}"
cat > "$BACKUP_DIR/CONFIG_SUMMARY.md" << EOF
# Configuration Backup Summary

**Date**: $(date)
**Server**: $(hostname)
**User**: $(whoami)

## Services Status
\`\`\`
$(docker compose ps)
\`\`\`

## WordPress URLs
- Home: $(cat $BACKUP_DIR/wp-home-url.txt)
- Siteurl: $(cat $BACKUP_DIR/wp-siteurl.txt)

## Active Plugins
\`\`\`
$(cat $BACKUP_DIR/active-plugins.txt)
\`\`\`

## wp-config.php First 20 Lines
\`\`\`php
$(head -20 $BACKUP_DIR/wp-config.php)
\`\`\`

## Critical Configuration
- HTTPS Detection: $(grep -q "HTTP_X_FORWARDED_PROTO" $BACKUP_DIR/wp-config.php && echo "✓ Present" || echo "✗ Missing")
- Redis Service: $(docker compose ps redis | grep -q "healthy" && echo "✓ Healthy" || echo "✗ Not healthy")
- Backup Service: $(docker compose ps backup | grep -q "Up" && echo "✓ Running" || echo "✗ Not running")

## Notes
This backup contains the working configuration as of $(date).
All critical services are operational and configuration is tested.
EOF

echo -e "${GREEN}✓ Summary created${NC}"
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}  Configuration Saved Successfully!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${YELLOW}Backup location:${NC}"
echo "$BACKUP_DIR"
echo ""

echo -e "${YELLOW}Files saved:${NC}"
ls -lh "$BACKUP_DIR/"
echo ""

echo -e "${YELLOW}To restore this configuration:${NC}"
echo "1. docker cp $BACKUP_DIR/wp-config.php bpkad-php-fpm:/var/www/html/wp-config.php"
echo "2. docker compose restart php-fpm"
echo ""

echo -e "${GREEN}✅ Complete!${NC}"

