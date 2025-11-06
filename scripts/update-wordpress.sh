#!/bin/bash
#
# WordPress Update Script
# Safely updates WordPress core, plugins, and themes
#
# Usage: ./scripts/update-wordpress.sh [--core] [--plugins] [--themes] [--all]
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  WordPress Update Script${NC}"
echo -e "${BLUE}  BPKAD Kabupaten Bengkalis${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to run wp-cli command
wp_cli() {
    docker compose run --rm wp-cli wp "$@" --allow-root
}

# Function to create backup before update
create_backup() {
    echo -e "${YELLOW}Creating safety backup before update...${NC}"
    docker compose exec backup /backup-db.sh
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Backup created successfully${NC}"
    else
        echo -e "${RED}✗ Backup failed!${NC}"
        read -p "Continue without backup? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    echo ""
}

# Function to check for updates
check_updates() {
    echo -e "${BLUE}Checking for available updates...${NC}"
    echo ""
    
    echo -e "${YELLOW}WordPress Core:${NC}"
    wp_cli core check-update || echo "No core updates available"
    echo ""
    
    echo -e "${YELLOW}Plugins:${NC}"
    wp_cli plugin list --update=available --format=table || echo "All plugins are up to date"
    echo ""
    
    echo -e "${YELLOW}Themes:${NC}"
    wp_cli theme list --update=available --format=table || echo "All themes are up to date"
    echo ""
}

# Function to update WordPress core
update_core() {
    echo -e "${BLUE}Updating WordPress Core...${NC}"
    
    # Check current version
    CURRENT_VERSION=$(wp_cli core version)
    echo -e "Current version: ${GREEN}$CURRENT_VERSION${NC}"
    
    # Update core
    wp_cli core update
    
    # Update database if needed
    wp_cli core update-db
    
    # Check new version
    NEW_VERSION=$(wp_cli core version)
    echo -e "New version: ${GREEN}$NEW_VERSION${NC}"
    
    echo -e "${GREEN}✓ WordPress core updated${NC}"
    echo ""
}

# Function to update plugins
update_plugins() {
    echo -e "${BLUE}Updating Plugins...${NC}"
    
    # List plugins with updates
    PLUGINS_TO_UPDATE=$(wp_cli plugin list --update=available --field=name 2>/dev/null || echo "")
    
    if [ -z "$PLUGINS_TO_UPDATE" ]; then
        echo -e "${GREEN}All plugins are already up to date${NC}"
    else
        echo -e "Plugins to update:"
        echo "$PLUGINS_TO_UPDATE"
        echo ""
        
        # Update all plugins
        wp_cli plugin update --all
        
        echo -e "${GREEN}✓ All plugins updated${NC}"
    fi
    echo ""
}

# Function to update themes
update_themes() {
    echo -e "${BLUE}Updating Themes...${NC}"
    
    # List themes with updates
    THEMES_TO_UPDATE=$(wp_cli theme list --update=available --field=name 2>/dev/null || echo "")
    
    if [ -z "$THEMES_TO_UPDATE" ]; then
        echo -e "${GREEN}All themes are already up to date${NC}"
    else
        echo -e "Themes to update:"
        echo "$THEMES_TO_UPDATE"
        echo ""
        
        # Update all themes
        wp_cli theme update --all
        
        echo -e "${GREEN}✓ All themes updated${NC}"
    fi
    echo ""
}

# Function to verify site health after update
verify_site() {
    echo -e "${BLUE}Verifying site health...${NC}"
    
    # Test site access
    if curl -sf http://localhost >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Site is accessible${NC}"
    else
        echo -e "${RED}✗ Site is NOT accessible!${NC}"
        echo -e "${YELLOW}Please check logs: docker compose logs${NC}"
    fi
    
    # Flush cache
    echo -e "${YELLOW}Flushing WordPress cache...${NC}"
    wp_cli cache flush
    
    # Optimize database
    echo -e "${YELLOW}Optimizing database...${NC}"
    wp_cli db optimize
    
    echo -e "${GREEN}✓ Verification complete${NC}"
    echo ""
}

# Main script
case "${1:-check}" in
    --core)
        create_backup
        update_core
        verify_site
        ;;
    --plugins)
        create_backup
        update_plugins
        verify_site
        ;;
    --themes)
        create_backup
        update_themes
        verify_site
        ;;
    --all)
        create_backup
        update_core
        update_plugins
        update_themes
        verify_site
        ;;
    --check|check)
        check_updates
        echo -e "${YELLOW}To update, run:${NC}"
        echo -e "  ${GREEN}./scripts/update-wordpress.sh --all${NC}     (update everything)"
        echo -e "  ${GREEN}./scripts/update-wordpress.sh --core${NC}    (update core only)"
        echo -e "  ${GREEN}./scripts/update-wordpress.sh --plugins${NC} (update plugins only)"
        echo -e "  ${GREEN}./scripts/update-wordpress.sh --themes${NC}  (update themes only)"
        exit 0
        ;;
    *)
        echo "Usage: $0 [--check|--core|--plugins|--themes|--all]"
        echo ""
        echo "Options:"
        echo "  --check     Check for available updates (default)"
        echo "  --core      Update WordPress core"
        echo "  --plugins   Update all plugins"
        echo "  --themes    Update all themes"
        echo "  --all       Update everything"
        exit 1
        ;;
esac

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Update Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Important:${NC}"
echo -e "1. Test your website functionality"
echo -e "2. Check WordPress admin for any issues"
echo -e "3. Review plugin/theme compatibility"
echo ""
echo -e "If any issues occur:"
echo -e "  ${GREEN}./scripts/restore-backup.sh <backup_file>${NC}"
echo ""

