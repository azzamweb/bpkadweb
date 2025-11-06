#!/bin/bash
#
# Database Restore Script
# Restores database from backup file
#
# Usage: ./scripts/restore-backup.sh <backup_file>
#        Example: ./scripts/restore-backup.sh wordpress_backup_20240101_120000.sql.gz
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if backup file is provided
if [ $# -eq 0 ]; then
    echo -e "${RED}Error: Backup file not specified${NC}"
    echo ""
    echo "Usage: $0 <backup_file>"
    echo "Example: $0 wordpress_backup_20240101_120000.sql.gz"
    echo ""
    echo "Available backups:"
    docker compose exec backup ls -lh /backups/
    exit 1
fi

BACKUP_FILE=$1

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Database Restore Script${NC}"
echo -e "${YELLOW}  BPKAD Kabupaten Bengkalis${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Confirm restore
echo -e "${RED}WARNING: This will overwrite the current database!${NC}"
echo -e "Backup file: ${GREEN}$BACKUP_FILE${NC}"
echo ""
read -p "Are you sure you want to continue? (yes/no): " -r
echo ""

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${YELLOW}Restore cancelled.${NC}"
    exit 0
fi

echo -e "${GREEN}Starting database restore...${NC}"

# Check if backup file exists in container
if ! docker compose exec backup test -f "/backups/$BACKUP_FILE"; then
    echo -e "${RED}Error: Backup file not found in container!${NC}"
    echo ""
    echo "Available backups:"
    docker compose exec backup ls -lh /backups/
    exit 1
fi

# Create a safety backup before restore
SAFETY_BACKUP="pre_restore_$(date +%Y%m%d_%H%M%S).sql.gz"
echo -e "${YELLOW}Creating safety backup: $SAFETY_BACKUP${NC}"
docker compose exec backup /backup-db.sh

# Read database password
DB_PASSWORD=$(docker compose exec backup cat /run/secrets/db_password)
DB_ROOT_PASSWORD=$(docker compose exec backup cat /run/secrets/db_root_password 2>/dev/null || echo "")

if [ -z "$DB_PASSWORD" ]; then
    echo -e "${RED}Error: Could not read database password${NC}"
    exit 1
fi

# Restore the backup
echo -e "${GREEN}Restoring database from backup...${NC}"

docker compose exec -T backup bash -c "
    set -e
    
    # Read passwords from secrets
    if [ -f /run/secrets/db_root_password ]; then
        PASSWORD=\$(cat /run/secrets/db_root_password)
        USER='root'
    else
        PASSWORD=\$(cat /run/secrets/db_password)
        USER='wpuser'
    fi
    
    # Decompress and restore
    gunzip -c /backups/$BACKUP_FILE | mysql \
        --host=mariadb \
        --user=\$USER \
        --password=\$PASSWORD \
        wordpress
    
    if [ \$? -eq 0 ]; then
        echo 'Database restored successfully'
    else
        echo 'Error: Database restore failed!'
        exit 1
    fi
"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Database Restored Successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${YELLOW}Important:${NC}"
    echo -e "1. Safety backup created: ${GREEN}$SAFETY_BACKUP${NC}"
    echo -e "2. Please verify your website is working correctly"
    echo -e "3. Clear WordPress cache if needed"
    echo ""
    echo -e "To clear cache, run:"
    echo -e "${GREEN}docker compose run --rm wp-cli wp cache flush --allow-root${NC}"
    echo ""
else
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}  Database Restore Failed!${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo -e "${YELLOW}Your original database is still intact.${NC}"
    echo -e "Safety backup is available at: ${GREEN}$SAFETY_BACKUP${NC}"
    echo ""
    exit 1
fi

