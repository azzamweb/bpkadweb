# Project Structure - BPKAD WordPress Docker

Dokumentasi lengkap struktur project dan penjelasan setiap file.

## 📁 Root Directory

```
bpkad.bengkaliskab.go.id/
├── docker-compose.yml                    # Docker Compose utama (7 services)
├── docker-compose.override.yml.example   # Override untuk development
├── .gitignore                           # Git ignore rules
├── .dockerignore                        # Docker ignore rules
├── .cursorignore                        # Cursor AI ignore rules
├── env.example                          # Environment variables template
├── Makefile                             # Shortcut commands (make install, make backup, dll)
├── LICENSE                              # MIT License
├── README.md                            # Dokumentasi utama ⭐
├── QUICKSTART.md                        # Quick start 15 menit ⚡
├── DEPLOY.md                            # Step-by-step deployment guide 📖
├── SECURITY.md                          # Security checklist & hardening 🔒
├── CHANGELOG.md                         # Version history
├── CONTRIBUTING.md                      # Contribution guidelines
└── PROJECT_STRUCTURE.md                 # File ini
```

### File Details

#### `docker-compose.yml` ⭐ CORE
- **Services**: mariadb, php-fpm, nginx, wp-cli, backup, adminer
- **Networks**: frontend (public), backend (internal)
- **Volumes**: db_data, wp_data, nginx_logs, backups
- **Secrets**: db_root_password, db_password, wp_admin_password
- **Health Checks**: Semua services punya healthcheck
- **Resource Limits**: Memory dan CPU limits untuk stability

#### `Makefile` 🛠️ UTILITY
Shortcuts untuk operasi umum:
```bash
make install      # Full installation
make start        # Start services
make logs         # View logs
make backup       # Manual backup
make update       # Update WordPress
make health       # Run health check
```

#### Documentation Files 📚
- **README.md**: Dokumentasi lengkap (installation, configuration, troubleshooting)
- **QUICKSTART.md**: Quick deploy dalam 15 menit
- **DEPLOY.md**: Step-by-step deployment guide dengan verification
- **SECURITY.md**: Security checklist, hardening, incident response
- **CHANGELOG.md**: Version history dan release notes
- **CONTRIBUTING.md**: Guidelines untuk contributor

## 🐳 Docker Configuration

### `nginx/` Directory

```
nginx/
└── conf.d/
    └── bpkad.conf    # Nginx site configuration
```

#### `bpkad.conf` (Nginx Config)
- **Server Names**: bpkad.bengkaliskab.go.id, 10.10.10.31
- **Security Features**:
  - Rate limiting (wp-login: 5/min, wp-admin: 10/s, general: 50/s)
  - Security headers (X-Frame-Options, CSP, etc.)
  - Cloudflare real IP forwarding
  - Block sensitive files (.env, .git, wp-config.php)
  - XML-RPC disabled
  - Dangerous HTTP methods blocked
- **Performance**:
  - FastCGI optimization
  - Static file caching (30 days)
  - Connection keep-alive
- **Upload Limits**: 64MB

### `php/` Directory

```
php/
├── Dockerfile              # Custom PHP-FPM image
├── docker-entrypoint.sh    # Container startup script
├── php.ini                 # PHP configuration
└── php-fpm.d/
    └── www.conf           # PHP-FPM pool configuration
```

#### `Dockerfile` (PHP-FPM Image)
- **Base**: php:8.3-fpm-alpine
- **Extensions**:
  - Database: mysqli, pdo_mysql
  - Images: gd, imagick
  - Core: intl, mbstring, xml, zip, exif, bcmath
  - Cache: opcache, redis, apcu
- **WordPress**: Pre-downloaded latest stable
- **Security**: www-data user, proper permissions

#### `php.ini` (PHP Config)
- **Memory**: 256MB
- **Upload**: 64MB
- **Execution Time**: 300s
- **OPcache**: 128MB, 10000 files
- **Realpath Cache**: 4096KB, 600s TTL
- **Security**: Dangerous functions disabled, expose_php off

#### `www.conf` (PHP-FPM Pool)
**Tuning for 4GB RAM**:
- `pm = dynamic`
- `pm.max_children = 50` (formula: (RAM - 1.5GB) / 50MB)
- `pm.start_servers = 10` (20% of max)
- `pm.min_spare_servers = 5` (10% of max)
- `pm.max_spare_servers = 15` (30% of max)
- `pm.max_requests = 500`

**Includes tuning guide for 2GB, 8GB, 16GB RAM**

### `mariadb/` Directory

```
mariadb/
└── my.cnf    # MariaDB configuration
```

#### `my.cnf` (MariaDB Config)
**Optimized for 4GB RAM**:
- `innodb_buffer_pool_size = 512M` (most important!)
- `max_connections = 151`
- Binary logging enabled (for point-in-time recovery)
- Slow query log enabled (2s threshold)
- UTF8MB4 character set
- Security: local_infile disabled

**Includes tuning guide for different RAM sizes**

### `wordpress/` Directory

```
wordpress/
└── wp-config.php.template    # WordPress config template
```

#### `wp-config.php.template`
- Database credentials placeholders
- WordPress salts placeholders
- Multi-domain support (domain + local IP)
- Cloudflare compatibility
- Security settings:
  - DISALLOW_FILE_EDIT = true
  - Proper SSL detection
  - Real IP from Cloudflare
- Performance:
  - Memory limits: 256M / 512M
  - Post revisions: 5
  - Autosave: 3 minutes
  - Trash: 7 days

## 🔧 Scripts Directory

```
scripts/
├── generate-secrets.sh      # Generate passwords & salts
├── init-wordpress.sh        # Initialize WordPress
├── backup-db.sh            # Database backup with rotation
├── restore-backup.sh       # Database restore
├── healthcheck.sh          # Service health monitoring
├── update-wordpress.sh     # Update WP core/plugins/themes
└── cleanup.sh              # Cleanup Docker resources
```

### Script Details

#### `generate-secrets.sh` 🔑
**Purpose**: Generate secure passwords and WordPress salts

**Generates**:
- `secrets/db_root_password.txt` (32 chars)
- `secrets/db_password.txt` (32 chars)
- `secrets/wp_admin_password.txt` (24 chars)
- `secrets/wp_salts.txt` (from WordPress API)

**Features**:
- Check for existing secrets (prevent overwrite)
- Proper file permissions (600)
- Display generated passwords
- Fetch salts from WordPress API or generate locally

**Usage**:
```bash
./scripts/generate-secrets.sh
# Save the displayed passwords!
```

#### `init-wordpress.sh` 🚀
**Purpose**: Initialize WordPress installation

**Actions**:
1. Wait for database ready
2. Create wp-config.php
3. Install WordPress (Indonesian)
4. Set permalink structure
5. Configure security (DISALLOW_FILE_EDIT)
6. Install essential plugins:
   - Wordfence Security
   - Limit Login Attempts Reloaded
   - UpdraftPlus Backup
   - WP Super Cache
   - Autoptimize
7. Update all plugins/themes
8. Optimize database
9. Set file permissions

**Usage**:
```bash
docker compose run --rm wp-cli /scripts/init-wordpress.sh
```

#### `backup-db.sh` 💾
**Purpose**: Automated database backup

**Features**:
- Compressed backup (gzip)
- Rotation (keep 7 days)
- Timestamp in filename
- Optional SFTP remote upload
- Logging

**Runs**: Daily at 02:00 WIB via cron

**Manual Usage**:
```bash
docker compose exec backup /backup-db.sh
```

#### `restore-backup.sh` ♻️
**Purpose**: Restore database from backup

**Features**:
- Interactive (list available backups)
- Confirmation required
- Safety backup before restore
- Verify backup file exists

**Usage**:
```bash
./scripts/restore-backup.sh wordpress_backup_20240101_120000.sql.gz
```

#### `healthcheck.sh` 🏥
**Purpose**: Monitor service health

**Checks**:
- All Docker services status
- WordPress accessibility
- Database connectivity
- Disk usage (volumes)
- Recent backups count

**Usage**:
```bash
./scripts/healthcheck.sh
# Exit code 0 = healthy, 1 = issues
```

#### `update-wordpress.sh` 🔄
**Purpose**: Update WordPress safely

**Options**:
- `--check`: Check for updates (default)
- `--core`: Update WordPress core
- `--plugins`: Update all plugins
- `--themes`: Update all themes
- `--all`: Update everything

**Features**:
- Safety backup before update
- Version comparison
- Site verification after update
- Cache flush
- Database optimization

**Usage**:
```bash
./scripts/update-wordpress.sh --check
./scripts/update-wordpress.sh --all
```

#### `cleanup.sh` 🧹
**Purpose**: Clean up resources

**Options**:
- `basic`: Logs, backups, cache (default)
- `--all`: Everything
- `--docker`: Docker resources only
- `--logs`: Logs only
- `--backups`: Old backups only
- `--cache`: WordPress cache only

**Cleans**:
- Docker stopped containers
- Unused networks
- Dangling images
- Old logs (30+ days)
- Old backups (7+ days)
- WordPress cache/transients
- Database optimization

**Usage**:
```bash
./scripts/cleanup.sh          # Basic cleanup
./scripts/cleanup.sh --all    # Full cleanup
```

## 🔐 Secrets Directory

```
secrets/                          # NOT in git!
├── README.md                    # Documentation
├── db_root_password.txt         # MariaDB root password
├── db_password.txt              # WordPress DB user password
├── wp_admin_password.txt        # WordPress admin password
└── wp_salts.txt                 # WordPress auth salts
```

**⚠️ Security**:
- Directory: 700 permissions
- Files: 600 permissions
- Never commit to git
- Backup encrypted

## 📊 Docker Volumes

Persistent data storage:

```
volumes/
├── bpkad_db_data/          # MariaDB database
├── bpkad_wp_data/          # WordPress files
├── bpkad_nginx_logs/       # Nginx access/error logs
└── bpkad_backups/          # Database backups
```

**Management**:
```bash
# List volumes
docker volume ls | grep bpkad

# Inspect volume
docker volume inspect bpkad_wp_data

# Backup volume
docker run --rm -v bpkad_wp_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/wp-data-backup.tar.gz /data

# Restore volume
docker run --rm -v bpkad_wp_data:/data -v $(pwd):/backup \
  alpine tar xzf /backup/wp-data-backup.tar.gz -C /
```

## 🎯 Quick Reference

### Essential Commands

```bash
# Installation
./scripts/generate-secrets.sh
docker compose build
docker compose up -d
docker compose run --rm wp-cli /scripts/init-wordpress.sh

# Monitoring
docker compose ps
docker compose logs -f
./scripts/healthcheck.sh

# Backup & Restore
docker compose exec backup /backup-db.sh
./scripts/restore-backup.sh <backup_file>

# Maintenance
./scripts/update-wordpress.sh --all
./scripts/cleanup.sh
docker compose run --rm wp-cli wp cache flush --allow-root

# Stop/Start
docker compose stop
docker compose start
docker compose restart
docker compose down
```

### Important Files to Review

**Before Deployment**:
1. ✅ `DEPLOY.md` - Deployment steps
2. ✅ `SECURITY.md` - Security checklist
3. ✅ `nginx/conf.d/bpkad.conf` - Server config
4. ✅ `php/php-fpm.d/www.conf` - PHP pool tuning

**After Deployment**:
1. ✅ Check `secrets/` directory exists with proper permissions
2. ✅ Verify `docker compose ps` - all healthy
3. ✅ Run `./scripts/healthcheck.sh`
4. ✅ Test website access

### Tuning for Your Server

**2GB RAM**:
- `php/php-fpm.d/www.conf`: max_children=25
- `mariadb/my.cnf`: innodb_buffer_pool_size=256M

**8GB RAM**:
- `php/php-fpm.d/www.conf`: max_children=100
- `mariadb/my.cnf`: innodb_buffer_pool_size=1G

**16GB RAM**:
- `php/php-fpm.d/www.conf`: max_children=200
- `mariadb/my.cnf`: innodb_buffer_pool_size=2G

## 📞 Need Help?

- **Installation Issues**: See `DEPLOY.md`
- **Security Questions**: See `SECURITY.md`
- **Performance Tuning**: See `README.md` → Performance Optimization
- **Troubleshooting**: See `README.md` → Troubleshooting

## 🎉 Summary

**Total Files**: 30+ files
**Total Lines**: ~5000+ lines of configuration and scripts
**Docker Services**: 7 services (mariadb, php-fpm, nginx, wp-cli, backup, adminer, optional)
**Scripts**: 7 utility scripts
**Documentation**: 8 markdown files

**Production Ready**: ✅  
**Security Hardened**: ✅  
**Well Documented**: ✅  
**Easy to Deploy**: ✅  
**Easy to Maintain**: ✅

---

**Last Updated**: November 2024  
**Project Version**: 1.0.0

