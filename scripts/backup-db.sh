#!/bin/bash
#
# Database Backup Script
# Performs daily backup with rotation
#
# Usage: Runs automatically via cron in backup container
#        Or manually: docker compose exec backup /backup-db.sh
#

set -e

# Configuration
BACKUP_DIR="/backups"
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-7}
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="wordpress_backup_${DATE}.sql.gz"

# Database credentials
DB_HOST=${MYSQL_HOST:-mariadb}
DB_NAME=${MYSQL_DATABASE:-wordpress}
DB_USER=${MYSQL_USER:-wpuser}

# Read password from secret
if [ -f /run/secrets/db_password ]; then
    DB_PASSWORD=$(cat /run/secrets/db_password)
elif [ -f /run/secrets/db_root_password ]; then
    DB_PASSWORD=$(cat /run/secrets/db_root_password)
    DB_USER="root"
else
    echo "Error: Database password not found!"
    exit 1
fi

# Create backup directory if not exists
mkdir -p "$BACKUP_DIR"

# Log function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting database backup..."

# Perform backup
log "Backing up database: $DB_NAME"

# Use mysqldump with compression
mysqldump \
    --host="$DB_HOST" \
    --user="$DB_USER" \
    --password="$DB_PASSWORD" \
    --single-transaction \
    --quick \
    --lock-tables=false \
    --add-drop-table \
    --databases "$DB_NAME" \
    | gzip > "$BACKUP_DIR/$BACKUP_FILE"

# Check if backup was successful
if [ $? -eq 0 ]; then
    log "Backup completed successfully: $BACKUP_FILE"
    
    # Get file size
    BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
    log "Backup size: $BACKUP_SIZE"
else
    log "Error: Backup failed!"
    exit 1
fi

# Rotate old backups
log "Rotating old backups (keeping last $RETENTION_DAYS days)..."
find "$BACKUP_DIR" -name "wordpress_backup_*.sql.gz" -type f -mtime +$RETENTION_DAYS -delete

# Count remaining backups
BACKUP_COUNT=$(find "$BACKUP_DIR" -name "wordpress_backup_*.sql.gz" -type f | wc -l)
log "Current backup count: $BACKUP_COUNT"

# Optional: Upload to remote SFTP server
if [ -n "$SFTP_HOST" ] && [ -n "$SFTP_USER" ]; then
    log "Uploading backup to remote SFTP server..."
    
    if command -v sshpass &> /dev/null && command -v sftp &> /dev/null; then
        SFTP_PORT=${SFTP_PORT:-22}
        SFTP_REMOTE_PATH=${SFTP_REMOTE_PATH:-/backups}
        
        # Upload using SFTP
        sshpass -p "$SFTP_PASSWORD" sftp -P "$SFTP_PORT" -o StrictHostKeyChecking=no \
            "${SFTP_USER}@${SFTP_HOST}" <<EOF
cd $SFTP_REMOTE_PATH
put $BACKUP_DIR/$BACKUP_FILE
quit
EOF
        
        if [ $? -eq 0 ]; then
            log "Backup uploaded to SFTP server successfully"
        else
            log "Warning: Failed to upload backup to SFTP server"
        fi
    else
        log "Warning: sshpass or sftp not installed, skipping remote upload"
    fi
fi

# Optional: Upload to cloud storage (AWS S3, Google Cloud Storage, etc.)
# Add your cloud upload logic here if needed

log "Backup process completed"

# Display disk usage
DISK_USAGE=$(df -h "$BACKUP_DIR" | tail -1 | awk '{print $5}')
log "Backup directory disk usage: $DISK_USAGE"

exit 0

