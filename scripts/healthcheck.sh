#!/bin/bash
#
# Health Check Script
# Monitors all Docker services and WordPress health
#
# Usage: ./scripts/healthcheck.sh
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Health Check - BPKAD WordPress${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if Docker Compose is running
if ! docker compose ps &>/dev/null; then
    echo -e "${RED}Error: Docker Compose project not found or not running${NC}"
    exit 1
fi

# Function to check service health
check_service() {
    local service=$1
    local status=$(docker compose ps --format json "$service" 2>/dev/null | grep -o '"State":"[^"]*"' | cut -d'"' -f4)
    local health=$(docker compose ps --format json "$service" 2>/dev/null | grep -o '"Health":"[^"]*"' | cut -d'"' -f4)
    
    if [ "$status" == "running" ]; then
        if [ -n "$health" ]; then
            if [ "$health" == "healthy" ]; then
                echo -e "${GREEN}✓${NC} $service: ${GREEN}running (healthy)${NC}"
                return 0
            else
                echo -e "${YELLOW}⚠${NC} $service: ${YELLOW}running ($health)${NC}"
                return 1
            fi
        else
            echo -e "${GREEN}✓${NC} $service: ${GREEN}running${NC}"
            return 0
        fi
    else
        echo -e "${RED}✗${NC} $service: ${RED}$status${NC}"
        return 1
    fi
}

echo -e "${BLUE}Docker Services Status:${NC}"
echo ""

# Check all services
SERVICES=("mariadb" "php-fpm" "nginx" "backup")
FAILED_SERVICES=0

for service in "${SERVICES[@]}"; do
    if ! check_service "$service"; then
        ((FAILED_SERVICES++))
    fi
done

echo ""

# Check WordPress site accessibility
echo -e "${BLUE}WordPress Accessibility Check:${NC}"
echo ""

# Check local access
if curl -sf http://localhost >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} WordPress is accessible on localhost"
else
    echo -e "${RED}✗${NC} WordPress is NOT accessible on localhost"
    ((FAILED_SERVICES++))
fi

# Check admin page
if curl -sf http://localhost/wp-admin/ | grep -q "wp-login" >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} WordPress admin page is accessible"
else
    echo -e "${RED}✗${NC} WordPress admin page is NOT accessible"
fi

echo ""

# Database connectivity check
echo -e "${BLUE}Database Connectivity:${NC}"
echo ""

if docker compose exec -T mariadb mysqladmin ping -h localhost --silent >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Database is responding to ping"
else
    echo -e "${RED}✗${NC} Database is NOT responding"
    ((FAILED_SERVICES++))
fi

echo ""

# Disk usage check
echo -e "${BLUE}Disk Usage:${NC}"
echo ""

echo -e "Database volume:"
docker compose exec mariadb df -h /var/lib/mysql | tail -1

echo ""
echo -e "WordPress volume:"
docker compose exec php-fpm df -h /var/www/html | tail -1

echo ""
echo -e "Backup volume:"
docker compose exec backup df -h /backups | tail -1

echo ""

# Check recent backups
echo -e "${BLUE}Recent Backups:${NC}"
echo ""
BACKUP_COUNT=$(docker compose exec backup find /backups -name "wordpress_backup_*.sql.gz" -type f | wc -l | tr -d ' ')
if [ "$BACKUP_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} Found $BACKUP_COUNT backup(s)"
    echo ""
    docker compose exec backup ls -lht /backups/*.sql.gz 2>/dev/null | head -3 || echo "No backups found"
else
    echo -e "${YELLOW}⚠${NC} No backups found"
fi

echo ""
echo -e "${BLUE}========================================${NC}"

# Final status
if [ $FAILED_SERVICES -eq 0 ]; then
    echo -e "${GREEN}All services are healthy!${NC}"
    echo -e "${BLUE}========================================${NC}"
    exit 0
else
    echo -e "${RED}$FAILED_SERVICES issue(s) detected${NC}"
    echo -e "${BLUE}========================================${NC}"
    exit 1
fi

