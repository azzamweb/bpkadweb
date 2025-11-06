#!/bin/bash
#
# Cleanup Script
# Cleans up Docker resources, old logs, and temporary files
#
# Usage: ./scripts/cleanup.sh [--all] [--docker] [--logs] [--backups]
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Cleanup Script${NC}"
echo -e "${BLUE}  BPKAD Kabupaten Bengkalis${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to clean Docker resources
cleanup_docker() {
    echo -e "${YELLOW}Cleaning Docker resources...${NC}"
    
    # Remove stopped containers
    echo -e "Removing stopped containers..."
    docker container prune -f
    
    # Remove unused networks
    echo -e "Removing unused networks..."
    docker network prune -f
    
    # Remove dangling images
    echo -e "Removing dangling images..."
    docker image prune -f
    
    # Remove build cache
    echo -e "Removing build cache..."
    docker builder prune -f
    
    echo -e "${GREEN}✓ Docker resources cleaned${NC}"
    echo ""
}

# Function to clean logs
cleanup_logs() {
    echo -e "${YELLOW}Cleaning old log files...${NC}"
    
    # Clean nginx logs older than 30 days
    if docker volume inspect bpkad_nginx_logs >/dev/null 2>&1; then
        docker run --rm -v bpkad_nginx_logs:/logs alpine \
            find /logs -name "*.log" -type f -mtime +30 -delete 2>/dev/null || true
        echo -e "${GREEN}✓ Old nginx logs cleaned${NC}"
    fi
    
    # Rotate current logs
    echo -e "Rotating current logs..."
    docker compose exec nginx nginx -s reopen 2>/dev/null || true
    
    echo -e "${GREEN}✓ Logs cleaned${NC}"
    echo ""
}

# Function to clean old backups
cleanup_backups() {
    echo -e "${YELLOW}Cleaning old backup files...${NC}"
    
    RETENTION_DAYS=7
    echo -e "Keeping backups from last $RETENTION_DAYS days..."
    
    # Clean old backups via backup container
    docker compose exec backup \
        find /backups -name "wordpress_backup_*.sql.gz" -type f -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
    
    # Show remaining backups
    BACKUP_COUNT=$(docker compose exec backup \
        find /backups -name "wordpress_backup_*.sql.gz" -type f | wc -l | tr -d ' ')
    
    echo -e "${GREEN}✓ Old backups cleaned${NC}"
    echo -e "Remaining backups: $BACKUP_COUNT"
    echo ""
}

# Function to optimize database
optimize_database() {
    echo -e "${YELLOW}Optimizing database...${NC}"
    
    # Clean transients
    docker compose run --rm wp-cli wp transient delete --all --allow-root 2>/dev/null || true
    
    # Clean revisions (keep last 5)
    docker compose run --rm wp-cli wp post delete \
        $(docker compose run --rm wp-cli wp post list --post_type=revision --format=ids --allow-root 2>/dev/null) \
        --force --allow-root 2>/dev/null || true
    
    # Optimize tables
    docker compose run --rm wp-cli wp db optimize --allow-root
    
    echo -e "${GREEN}✓ Database optimized${NC}"
    echo ""
}

# Function to clean WordPress cache
cleanup_wordpress_cache() {
    echo -e "${YELLOW}Cleaning WordPress cache...${NC}"
    
    # Flush object cache
    docker compose run --rm wp-cli wp cache flush --allow-root
    
    # Clean plugin cache (WP Super Cache)
    docker compose run --rm wp-cli wp super-cache flush 2>/dev/null || true
    
    echo -e "${GREEN}✓ WordPress cache cleaned${NC}"
    echo ""
}

# Function to show disk usage
show_disk_usage() {
    echo -e "${BLUE}Disk Usage Summary:${NC}"
    echo ""
    
    # Docker system disk usage
    echo -e "${YELLOW}Docker System:${NC}"
    docker system df
    echo ""
    
    # Volume usage
    echo -e "${YELLOW}Docker Volumes:${NC}"
    docker volume ls --format "table {{.Name}}\t{{.Driver}}" | grep bpkad || true
    echo ""
    
    # Backup directory size
    echo -e "${YELLOW}Backup Directory:${NC}"
    docker compose exec backup du -sh /backups 2>/dev/null || echo "Not available"
    echo ""
}

# Parse arguments
case "${1:-basic}" in
    --all)
        cleanup_docker
        cleanup_logs
        cleanup_backups
        optimize_database
        cleanup_wordpress_cache
        show_disk_usage
        ;;
    --docker)
        cleanup_docker
        show_disk_usage
        ;;
    --logs)
        cleanup_logs
        ;;
    --backups)
        cleanup_backups
        ;;
    --cache)
        cleanup_wordpress_cache
        ;;
    basic)
        # Basic cleanup (safe to run regularly)
        cleanup_logs
        cleanup_backups
        cleanup_wordpress_cache
        show_disk_usage
        ;;
    *)
        echo "Usage: $0 [basic|--all|--docker|--logs|--backups|--cache]"
        echo ""
        echo "Options:"
        echo "  basic       Basic cleanup (logs, backups, cache) - default"
        echo "  --all       Complete cleanup (everything)"
        echo "  --docker    Clean Docker resources only"
        echo "  --logs      Clean log files only"
        echo "  --backups   Clean old backups only"
        echo "  --cache     Clean WordPress cache only"
        exit 1
        ;;
esac

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Cleanup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Recommendations:${NC}"
echo -e "- Run basic cleanup weekly"
echo -e "- Run full cleanup (--all) monthly"
echo -e "- Monitor disk usage regularly"
echo ""

