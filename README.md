# WordPress Docker - BPKAD Kabupaten Bengkalis

Production-ready WordPress deployment menggunakan Docker Compose dengan fokus pada performance, security, dan reliability untuk website pemerintahan.

## 🎯 Fitur Utama

- **WordPress Latest (Stable)** - Menggunakan versi WordPress terbaru yang stabil
- **MariaDB 11.2** - Database dengan optimasi performa
- **Nginx** - Web server dengan reverse proxy ke PHP-FPM
- **PHP-FPM 8.3** - PHP dengan optimasi performa (OPcache, realpath cache)
- **Security Headers** - Keamanan dasar untuk standar website pemerintahan
- **Auto Backup** - Backup database otomatis setiap hari dengan rotasi
- **Health Checks** - Monitoring kesehatan semua services
- **Docker Secrets** - Password management yang aman
- **Multi-domain Support** - Akses via domain dan IP lokal

## 📋 Spesifikasi Sistem

### Minimum Requirements
- **RAM**: 2GB (4GB recommended)
- **Storage**: 20GB
- **OS**: Linux (Ubuntu 20.04+ / CentOS 8+ / Debian 11+)
- **Docker**: 20.10+
- **Docker Compose**: 2.0+

### Network Architecture
```
Cloudflare (SSL/CDN)
    ↓
NPM (Nginx Proxy Manager) - 103.13.206.172
    ↓
NAT Mikrotik - 103.13.206.172:8089
    ↓
Server Lokal - 10.10.10.31:80 (Docker Nginx)
```

## 🚀 Instalasi Cepat

### 1. Clone atau Download Project

```bash
cd /opt
git clone <repository-url> bpkad-wordpress
cd bpkad-wordpress
```

Atau ekstrak dari zip/tar.gz jika tidak menggunakan git.

### 2. Generate Secrets

```bash
chmod +x scripts/*.sh
./scripts/generate-secrets.sh
```

Script ini akan membuat:
- Database root password
- Database user password  
- WordPress admin password
- WordPress authentication salts

**⚠️ Penting**: Simpan password yang ditampilkan di tempat aman!

### 3. Set File Permissions

```bash
# Set ownership (sesuaikan dengan user yang menjalankan Docker)
sudo chown -R $USER:$USER .

# Set permissions untuk secrets
chmod 700 secrets/
chmod 600 secrets/*

# Set permissions untuk scripts
chmod +x scripts/*.sh
```

### 4. Build dan Start Services

```bash
# Build images
docker compose build --no-cache

# Start services
docker compose up -d

# Lihat logs
docker compose logs -f
```

### 5. Initialize WordPress

```bash
# Jalankan initialization script
docker compose run --rm wp-cli /scripts/init-wordpress.sh
```

Script ini akan:
- Membuat wp-config.php
- Install WordPress dengan bahasa Indonesia
- Set permalink structure
- Install plugin essential (security, cache, backup)
- Set konfigurasi keamanan dasar
- Optimize database

### 6. Verifikasi Installation

```bash
# Jalankan health check
./scripts/healthcheck.sh
```

Atau akses:
- **Website**: http://bpkad.bengkaliskab.go.id atau http://10.10.10.31
- **Admin**: http://bpkad.bengkaliskab.go.id/wp-admin/

## 📁 Struktur Project

```
bpkad-wordpress/
├── docker-compose.yml           # Docker Compose configuration
├── .gitignore                   # Git ignore rules
├── .dockerignore                # Docker ignore rules
├── README.md                    # Dokumentasi ini
├── SECURITY.md                  # Security checklist
│
├── nginx/
│   └── conf.d/
│       └── bpkad.conf          # Nginx site configuration
│
├── php/
│   ├── Dockerfile              # PHP-FPM custom image
│   ├── docker-entrypoint.sh    # PHP-FPM entrypoint
│   ├── php.ini                 # PHP configuration
│   └── php-fpm.d/
│       └── www.conf            # PHP-FPM pool configuration
│
├── mariadb/
│   └── my.cnf                  # MariaDB optimization
│
├── wordpress/
│   └── wp-config.php.template  # WordPress config template
│
├── scripts/
│   ├── generate-secrets.sh     # Generate passwords & salts
│   ├── init-wordpress.sh       # WordPress initialization
│   ├── backup-db.sh           # Database backup script
│   ├── restore-backup.sh      # Database restore script
│   └── healthcheck.sh         # Health monitoring
│
└── secrets/                    # Docker secrets (not in git)
    ├── db_root_password.txt
    ├── db_password.txt
    ├── wp_admin_password.txt
    └── wp_salts.txt
```

## 🔧 Konfigurasi

### Tuning untuk Different RAM Sizes

#### 2GB RAM Server
```bash
# Edit php/php-fpm.d/www.conf
pm.max_children = 25
pm.start_servers = 5
pm.min_spare_servers = 3
pm.max_spare_servers = 8

# Edit mariadb/my.cnf
innodb_buffer_pool_size = 256M
max_connections = 100
```

#### 8GB RAM Server
```bash
# Edit php/php-fpm.d/www.conf
pm.max_children = 100
pm.start_servers = 20
pm.min_spare_servers = 10
pm.max_spare_servers = 30

# Edit mariadb/my.cnf
innodb_buffer_pool_size = 1G
max_connections = 200
```

#### 16GB RAM Server
```bash
# Edit php/php-fpm.d/www.conf
pm.max_children = 200
pm.start_servers = 40
pm.min_spare_servers = 20
pm.max_spare_servers = 60

# Edit mariadb/my.cnf
innodb_buffer_pool_size = 2G
max_connections = 300
```

### Tuning Formula
```
pm.max_children = (Available RAM - OS/DB/Nginx) / Average PHP Process Size
                = (Total RAM - 1.5GB) / 50MB

pm.start_servers = 20% of max_children
pm.min_spare_servers = 10% of max_children
pm.max_spare_servers = 30% of max_children
```

## 🔐 Keamanan

### Security Features Implemented

✅ Nginx security headers (X-Frame-Options, X-Content-Type-Options, etc.)  
✅ Rate limiting untuk wp-login.php dan wp-admin  
✅ Deny akses ke file sensitif (.env, .git, wp-config.php)  
✅ XML-RPC disabled  
✅ File editor disabled (DISALLOW_FILE_EDIT)  
✅ Docker secrets untuk password  
✅ PHP dangerous functions disabled  
✅ Proper file permissions  
✅ Cloudflare real IP forwarding  
✅ Limit login attempts (via plugin)  
✅ Wordfence security (via plugin)

Lihat [SECURITY.md](SECURITY.md) untuk checklist lengkap.

## 💾 Backup & Restore

### Automatic Backup

Backup otomatis berjalan setiap hari pukul 02:00 WIB melalui cron container. Backup disimpan di volume `bpkad_backups` dengan rotasi 7 hari.

```bash
# Lihat backup yang tersedia
docker compose exec backup ls -lh /backups/

# Trigger manual backup
docker compose exec backup /backup-db.sh
```

### Manual Backup

```bash
# Backup database
docker compose exec mariadb mysqldump \
  -u root -p$(cat secrets/db_root_password.txt) \
  wordpress | gzip > backup_$(date +%Y%m%d).sql.gz

# Backup WordPress files
docker compose exec php-fpm tar czf /tmp/wp-files.tar.gz /var/www/html
docker compose cp php-fpm:/tmp/wp-files.tar.gz ./wp-files_$(date +%Y%m%d).tar.gz
```

### Restore dari Backup

```bash
# List available backups
docker compose exec backup ls -lh /backups/

# Restore specific backup
./scripts/restore-backup.sh wordpress_backup_20240101_120000.sql.gz
```

⚠️ **Restore akan membuat safety backup terlebih dahulu!**

## 📊 Monitoring & Maintenance

### Check Services Status

```bash
# View all services
docker compose ps

# View logs
docker compose logs -f

# View specific service logs
docker compose logs -f nginx
docker compose logs -f php-fpm
docker compose logs -f mariadb

# Run health check
./scripts/healthcheck.sh
```

### WordPress Maintenance Commands

```bash
# Update WordPress core
docker compose run --rm wp-cli wp core update --allow-root

# Update all plugins
docker compose run --rm wp-cli wp plugin update --all --allow-root

# Update all themes
docker compose run --rm wp-cli wp theme update --all --allow-root

# Optimize database
docker compose run --rm wp-cli wp db optimize --allow-root

# Clear cache
docker compose run --rm wp-cli wp cache flush --allow-root

# Check WordPress version
docker compose run --rm wp-cli wp core version --allow-root

# List installed plugins
docker compose run --rm wp-cli wp plugin list --allow-root
```

### Database Management

```bash
# Access database via Adminer (enable tools profile first)
docker compose --profile tools up -d adminer
# Access: http://10.10.10.31:8080

# Direct MySQL access
docker compose exec mariadb mysql -u root -p$(cat secrets/db_root_password.txt) wordpress

# Database size
docker compose exec mariadb mysql -u root -p$(cat secrets/db_root_password.txt) -e "
  SELECT 
    table_schema AS 'Database',
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
  FROM information_schema.tables
  WHERE table_schema = 'wordpress'
  GROUP BY table_schema;
"
```

## 🔄 Update & Upgrade

### Update Docker Images

```bash
# Pull latest images
docker compose pull

# Recreate containers with new images
docker compose up -d --force-recreate

# Clean up old images
docker image prune -a
```

### Update WordPress

```bash
# Via WP-CLI
docker compose run --rm wp-cli wp core update --allow-root

# Or via WordPress admin interface
# Navigate to: Dashboard → Updates
```

### Rollback Strategy

```bash
# Stop services
docker compose down

# Restore from backup
./scripts/restore-backup.sh <backup_file>

# Start services
docker compose up -d
```

## 🐛 Troubleshooting

### Services Won't Start

```bash
# Check logs
docker compose logs

# Check disk space
df -h

# Check Docker daemon
sudo systemctl status docker

# Rebuild images
docker compose down
docker compose build --no-cache
docker compose up -d
```

### WordPress White Screen / 500 Error

```bash
# Check PHP-FPM logs
docker compose logs php-fpm

# Check Nginx logs
docker compose logs nginx

# Enable WordPress debug
docker compose exec php-fpm bash
# Edit wp-config.php: define('WP_DEBUG', true);

# Check file permissions
docker compose exec php-fpm ls -la /var/www/html/
```

### Database Connection Error

```bash
# Check MariaDB status
docker compose ps mariadb
docker compose logs mariadb

# Test database connection
docker compose exec mariadb mysqladmin ping -h localhost

# Restart MariaDB
docker compose restart mariadb
```

### Performance Issues

```bash
# Check resource usage
docker stats

# Check slow queries
docker compose exec mariadb mysql -u root -p$(cat secrets/db_root_password.txt) \
  -e "SELECT * FROM mysql.slow_log ORDER BY start_time DESC LIMIT 10;"

# Optimize database
docker compose run --rm wp-cli wp db optimize --allow-root

# Clear WordPress cache
docker compose run --rm wp-cli wp cache flush --allow-root

# Review PHP-FPM status
curl http://localhost/status
```

## 📈 Performance Optimization

### Enable OPcache Monitoring

```bash
# Install OPcache GUI (optional)
docker compose exec php-fpm bash
cd /var/www/html/wp-content
wget https://raw.githubusercontent.com/amnuts/opcache-gui/master/index.php -O opcache.php
# Access: http://10.10.10.31/wp-content/opcache.php
```

### Enable FastCGI Cache (Nginx)

Edit `nginx/conf.d/bpkad.conf` dan uncomment bagian fastcgi_cache, lalu:

```bash
docker compose restart nginx
```

### Install Redis for Object Caching

```bash
# Add Redis service to docker-compose.yml
# Install Redis Object Cache plugin
docker compose run --rm wp-cli wp plugin install redis-cache --activate --allow-root
docker compose run --rm wp-cli wp redis enable --allow-root
```

## 🔒 Hardening Checklist

- [ ] Change default admin username dari "admin"
- [ ] Set strong password untuk semua akun
- [ ] Enable 2FA authentication
- [ ] Configure Wordfence firewall
- [ ] Set up fail2ban on host
- [ ] Enable HTTPS (via Cloudflare)
- [ ] Regular security updates
- [ ] Monitor access logs
- [ ] Set up intrusion detection
- [ ] Regular backup testing

Lihat [SECURITY.md](SECURITY.md) untuk checklist lengkap.

## 📝 Maintenance Schedule

### Daily
- ✅ Automatic database backup (02:00 WIB)
- ✅ Automatic health checks

### Weekly
- [ ] Review error logs
- [ ] Check disk usage
- [ ] Review security logs (Wordfence)
- [ ] Test backup restore

### Monthly
- [ ] Update WordPress core (minor versions auto-update)
- [ ] Update plugins and themes
- [ ] Optimize database
- [ ] Review and rotate logs
- [ ] Security audit

### Quarterly
- [ ] Full system backup
- [ ] Disaster recovery test
- [ ] Performance audit
- [ ] Security penetration testing

## 🆘 Support & Contact

- **Email**: admin@bpkad.bengkaliskab.go.id
- **Website**: https://bpkad.bengkaliskab.go.id

## 📜 License

Copyright © 2024 BPKAD Kabupaten Bengkalis. All rights reserved.

## 🙏 Acknowledgments

- WordPress Community
- Docker Community
- Nginx Community
- MariaDB Foundation

---

**Last Updated**: November 2024  
**Maintained by**: BPKAD IT Team

