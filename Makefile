# Makefile for BPKAD WordPress Docker Project
# Simplifies common Docker operations

.PHONY: help install start stop restart logs status clean backup restore update health

# Default target
help:
	@echo "BPKAD WordPress - Available Commands:"
	@echo ""
	@echo "Setup & Installation:"
	@echo "  make install        - Initial setup (generate secrets, build, init WordPress)"
	@echo "  make secrets        - Generate security secrets"
	@echo ""
	@echo "Container Management:"
	@echo "  make build          - Build Docker images"
	@echo "  make start          - Start all services"
	@echo "  make stop           - Stop all services"
	@echo "  make restart        - Restart all services"
	@echo "  make down           - Stop and remove containers"
	@echo ""
	@echo "Monitoring:"
	@echo "  make logs           - View all logs (follow mode)"
	@echo "  make logs-nginx     - View Nginx logs"
	@echo "  make logs-php       - View PHP-FPM logs"
	@echo "  make logs-db        - View MariaDB logs"
	@echo "  make status         - Show services status"
	@echo "  make health         - Run health check"
	@echo ""
	@echo "Backup & Restore:"
	@echo "  make backup         - Run manual database backup"
	@echo "  make restore        - Restore from backup (interactive)"
	@echo "  make list-backups   - List available backups"
	@echo ""
	@echo "Maintenance:"
	@echo "  make update         - Update WordPress core, plugins, themes"
	@echo "  make optimize-db    - Optimize database"
	@echo "  make clear-cache    - Clear WordPress cache"
	@echo "  make clean          - Clean up Docker resources"
	@echo ""
	@echo "Tools:"
	@echo "  make wp-cli         - Open WP-CLI interactive shell"
	@echo "  make db-cli         - Open database CLI"
	@echo "  make adminer        - Start Adminer (database admin)"
	@echo ""

# Installation
install: secrets build init-wp
	@echo "✓ Installation complete!"
	@echo "Access your site at: http://bpkad.bengkaliskab.go.id or http://10.10.10.31"
	@$(MAKE) health

secrets:
	@./scripts/generate-secrets.sh

build:
	@echo "Building Docker images..."
	@docker compose build --no-cache

init-wp:
	@echo "Initializing WordPress..."
	@docker compose up -d
	@sleep 15
	@docker compose run --rm wp-cli /scripts/init-wordpress.sh

# Container Management
start:
	@echo "Starting all services..."
	@docker compose up -d
	@$(MAKE) status

stop:
	@echo "Stopping all services..."
	@docker compose stop

restart:
	@echo "Restarting all services..."
	@docker compose restart
	@$(MAKE) status

down:
	@echo "Stopping and removing containers..."
	@docker compose down

# Monitoring
logs:
	@docker compose logs -f

logs-nginx:
	@docker compose logs -f nginx

logs-php:
	@docker compose logs -f php-fpm

logs-db:
	@docker compose logs -f mariadb

status:
	@docker compose ps

health:
	@./scripts/healthcheck.sh

# Backup & Restore
backup:
	@echo "Running manual backup..."
	@docker compose exec backup /backup-db.sh

restore:
	@echo "Available backups:"
	@docker compose exec backup ls -lh /backups/
	@read -p "Enter backup filename: " BACKUP_FILE; \
	./scripts/restore-backup.sh $$BACKUP_FILE

list-backups:
	@docker compose exec backup ls -lh /backups/

# Maintenance
update:
	@echo "Updating WordPress core..."
	@docker compose run --rm wp-cli wp core update --allow-root
	@echo "Updating plugins..."
	@docker compose run --rm wp-cli wp plugin update --all --allow-root
	@echo "Updating themes..."
	@docker compose run --rm wp-cli wp theme update --all --allow-root
	@echo "✓ Update complete!"

optimize-db:
	@echo "Optimizing database..."
	@docker compose run --rm wp-cli wp db optimize --allow-root
	@echo "✓ Database optimized!"

clear-cache:
	@echo "Clearing WordPress cache..."
	@docker compose run --rm wp-cli wp cache flush --allow-root
	@echo "✓ Cache cleared!"

clean:
	@echo "Cleaning up Docker resources..."
	@docker system prune -f
	@echo "✓ Cleanup complete!"

# Tools
wp-cli:
	@docker compose run --rm wp-cli bash

db-cli:
	@docker compose exec mariadb mysql -u root -p$$(cat secrets/db_root_password.txt) wordpress

adminer:
	@echo "Starting Adminer..."
	@docker compose --profile tools up -d adminer
	@echo "Access Adminer at: http://10.10.10.31:8080"
	@echo "Server: mariadb"
	@echo "Username: wpuser"
	@echo "Password: (check secrets/db_password.txt)"
	@echo "Database: wordpress"

