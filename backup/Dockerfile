# Backup Container with Cron Support
FROM alpine:3.19

# Install required packages
RUN apk add --no-cache \
    bash \
    mysql-client \
    mariadb-connector-c \
    dcron \
    gzip \
    openssh-client \
    sshpass \
    tzdata

# Set timezone
ENV TZ=Asia/Jakarta
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Create log directory
RUN mkdir -p /var/log && touch /var/log/backup.log

# Note: backup script will be mounted as volume from host
# This keeps it in sync with repository changes

# Setup cron
RUN echo "0 2 * * * /usr/local/bin/backup-db.sh >> /var/log/backup.log 2>&1" > /etc/crontabs/root

# Create entrypoint
RUN echo '#!/bin/sh' > /entrypoint.sh && \
    echo 'echo "Starting backup service with cron..."' >> /entrypoint.sh && \
    echo 'echo "Backup schedule: Daily at 02:00 WIB"' >> /entrypoint.sh && \
    echo 'echo "Backup retention: ${BACKUP_RETENTION_DAYS:-7} days"' >> /entrypoint.sh && \
    echo 'crond -f -l 2' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

