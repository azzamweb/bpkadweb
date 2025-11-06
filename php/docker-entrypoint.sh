#!/bin/sh
set -e

# PHP-FPM Entrypoint Script
# Handles WordPress initialization and proper startup

echo "Starting PHP-FPM container..."

# If wp-config.php doesn't exist, copy from template
if [ ! -f /var/www/html/wp-config.php ] && [ -f /var/www/html/wp-config-sample.php ]; then
    echo "wp-config.php not found. Waiting for initialization..."
fi

# Ensure proper permissions (when running as www-data)
if [ "$(id -u)" = "0" ]; then
    echo "Running as root, fixing permissions..."
    chown -R www-data:www-data /var/www/html
    find /var/www/html -type d -exec chmod 755 {} \;
    find /var/www/html -type f -exec chmod 644 {} \;
fi

# Execute the main command
exec "$@"

