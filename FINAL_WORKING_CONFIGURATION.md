# Final Working Configuration - Production Verified ✅

**Project**: BPKAD Kabupaten Bengkalis WordPress  
**Status**: ✅ **PRODUCTION WORKING**  
**Date**: November 2024  
**Server**: 10.10.10.31  
**Domain**: bpkad.bengkaliskab.go.id

---

## 🎉 SUCCESS STATUS

All issues resolved and verified working in production:

```
✅ WordPress: Running & Accessible
✅ HTTPS: Working via Cloudflare (no Mixed Content)
✅ Redis: Available (optional to enable)
✅ Permissions: Correct (www-data:www-data)
✅ Performance: Optimized (PHP-FPM, MariaDB tuned)
✅ Security: Hardened (headers, rate limiting)
✅ Backups: Automated (daily at 02:00 WIB)
✅ DNS Resolution: Fixed (extra_hosts)
✅ File Uploads: Working
```

---

## 🔧 Critical Configuration (MUST HAVE)

### 1. WordPress Settings - NEVER CHANGE THESE!

**Settings → General** MUST be:

```
WordPress Address (URL): http://bpkad.bengkaliskab.go.id  ← HTTP!
Site Address (URL): http://bpkad.bengkaliskab.go.id       ← HTTP!
```

**⚠️ CRITICAL**: NEVER change to HTTPS! This will cause infinite redirect loop!

**Why**: Cloudflare handles HTTPS externally. Internal WordPress uses HTTP.

---

### 2. wp-config.php - HTTPS Detection (REQUIRED!)

Add this code **immediately after** `<?php` opening tag:

```php
<?php

/* HTTPS Detection from Cloudflare/Reverse Proxy */
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}

// Rest of wp-config.php...
```

**Purpose**: Fixes Mixed Content errors (images/CSS/JS not loading on HTTPS)

**How to add**:
```bash
cd /var/www/bpkadweb

# Add HTTPS detection
docker compose exec php-fpm sh -c 'cat > /tmp/https-fix.txt << "EOF"

/* HTTPS Detection from Cloudflare */
if (isset($_SERVER["HTTP_X_FORWARDED_PROTO"]) && $_SERVER["HTTP_X_FORWARDED_PROTO"] === "https") {
    $_SERVER["HTTPS"] = "on";
}
EOF
'

docker compose exec php-fpm sh -c 'awk "NR==1{print; print \"\"; system(\"cat /tmp/https-fix.txt\")} NR>1" /var/www/html/wp-config.php > /tmp/wp-new.php && mv /tmp/wp-new.php /var/www/html/wp-config.php'

docker compose exec -u root php-fpm chown www-data:www-data /var/www/html/wp-config.php
docker compose exec -u root php-fpm chmod 644 /var/www/html/wp-config.php
docker compose restart php-fpm
```

---

### 3. Docker Compose - DNS Resolution Fix

**File**: `docker-compose.yml`

Add `extra_hosts` to `php-fpm` and `wp-cli` services:

```yaml
php-fpm:
  extra_hosts:
    - "bpkad.bengkaliskab.go.id:10.10.10.31"  # ← Required!
  # ... rest of config

wp-cli:
  extra_hosts:
    - "bpkad.bengkaliskab.go.id:10.10.10.31"  # ← Required!
  # ... rest of config
```

**Purpose**: Allows containers to resolve domain to local IP (fixes cron, REST API)

---

### 4. Redis Cache (Optional but Recommended)

**File**: `docker-compose.yml` - Redis service already configured ✅

**To enable**:
```bash
# Via WordPress admin (easiest)
Go to: Settings → Redis → Click "Enable Object Cache"

# Or via WP-CLI
docker compose run --rm wp-cli wp redis enable --allow-root
```

**Benefits**:
- 🚀 50-80% reduction in database queries
- 🚀 2x faster page loads
- 🚀 Better performance under load

---

## 📋 File Permissions (Critical!)

### Correct Permissions

```bash
# wp-config.php
-rw-r--r-- www-data:www-data 644

# wp-content/
drwxr-xr-x www-data:www-data 755

# wp-content/uploads/
drwxr-xr-x www-data:www-data 755

# wp-content/plugins/
drwxr-xr-x www-data:www-data 755

# wp-content/themes/
drwxr-xr-x www-data:www-data 755
```

### Fix Script (If Needed)

```bash
cd /var/www/bpkadweb

# Run permissions fix script
./scripts/fix-permissions.sh

# Or manual
docker compose exec -u root php-fpm chown -R www-data:www-data /var/www/html
docker compose exec -u root php-fpm find /var/www/html -type d -exec chmod 755 {} \;
docker compose exec -u root php-fpm find /var/www/html -type f -exec chmod 644 {} \;
docker compose exec -u root php-fpm chmod -R 755 /var/www/html/wp-content
```

---

## 🎯 Deployment Workflow (Tested & Working)

### Initial Deploy

```bash
cd /var/www/bpkadweb

# 1. Start services
docker compose up -d

# 2. Initialize WordPress (if not done)
./scripts/init-wordpress.sh

# 3. Fix HTTPS detection
# Add code to wp-config.php (see section 2 above)

# 4. Enable Redis (optional)
# Via WordPress admin: Settings → Redis → Enable

# 5. Fix permissions if needed
./scripts/fix-permissions.sh

# 6. Verify
docker compose ps
curl -I http://localhost  # Should return 200
```

### After Git Pull

```bash
cd /var/www/bpkadweb

# Pull changes
git pull origin main

# Rebuild if needed
docker compose build

# Restart services
docker compose up -d

# Check status
docker compose ps
./scripts/healthcheck.sh
```

---

## 🚨 Common Issues & Solutions

### Issue 1: ERR_TOO_MANY_REDIRECTS

**Cause**: WordPress URLs set to HTTPS in Settings → General

**Solution**:
```bash
# Reset URLs to HTTP
docker compose run --rm wp-cli wp option update home 'http://bpkad.bengkaliskab.go.id' --allow-root
docker compose run --rm wp-cli wp option update siteurl 'http://bpkad.bengkaliskab.go.id' --allow-root

# Clear cache
docker compose run --rm wp-cli wp cache flush --allow-root

# Clear browser cache
```

### Issue 2: Mixed Content Warnings

**Cause**: HTTPS detection not configured in wp-config.php

**Solution**: Add HTTPS detection code (see section 2 above)

### Issue 3: Images Not Loading on HTTPS

**Cause**: Same as Issue 2 - Missing HTTPS detection

**Solution**: Add HTTPS detection code to wp-config.php

### Issue 4: Upload Errors

**Cause**: Wrong file permissions

**Solution**:
```bash
./scripts/fix-permissions.sh
```

### Issue 5: Could Not Resolve Host (cron errors)

**Cause**: Missing extra_hosts in docker-compose.yml

**Solution**: Add extra_hosts to php-fpm and wp-cli (see section 3 above)

### Issue 6: HTTP 500 Error

**Cause**: PHP syntax error in wp-config.php

**Solution**:
```bash
# Restore from backup
docker compose exec php-fpm cp /var/www/html/wp-config.php.backup /var/www/html/wp-config.php

# Check syntax
docker compose exec php-fpm php -l /var/www/html/wp-config.php

# Restart
docker compose restart php-fpm
```

---

## 📊 Architecture Overview

### Network Flow (Working Configuration)

```
Internet (HTTPS)
    ↓
Cloudflare CDN (SSL/TLS Termination)
  • SSL certificate
  • DDoS protection
  • CDN caching
    ↓ (HTTP)
NPM Proxy (103.13.206.172)
    ↓
Mikrotik NAT (Port forwarding 8089 → 10.10.10.31:80)
    ↓
Docker Nginx (Port 80)
  • Reverse proxy
  • Security headers
  • Rate limiting
  • Static file caching
    ↓
PHP-FPM (Port 9000)
  • WordPress application
  • OPcache enabled
  • Optimized for 4GB RAM
    ↓
MariaDB (Port 3306)
  • Database
  • InnoDB optimized
  ↓
Redis (Port 6379) - Optional
  • Object cache
  • Performance boost
```

### Key Points

1. **HTTPS** only at Cloudflare edge
2. **HTTP** internally (NPM → Mikrotik → Docker)
3. **WordPress** uses HTTP URLs
4. **HTTPS detection** via X-Forwarded-Proto header

---

## 🔒 Security Configuration (Production)

### Nginx Security Headers

```nginx
# Already configured in nginx/conf.d/bpkad.conf
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
```

### Rate Limiting

```nginx
# Already configured
limit_req_zone $binary_remote_addr zone=wp_login:10m rate=5r/m;
limit_req_zone $binary_remote_addr zone=wp_admin:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=general:10m rate=50r/s;
```

### WordPress Security

```php
// Already in wp-config.php via init script
define('DISALLOW_FILE_EDIT', true);
define('WP_POST_REVISIONS', 5);
define('AUTOSAVE_INTERVAL', 300);
define('EMPTY_TRASH_DAYS', 7);
```

### Installed Security Plugins

```
✅ Wordfence Security
✅ Limit Login Attempts Reloaded
✅ UpdraftPlus (Backup)
```

---

## 🚀 Performance Optimization (Active)

### PHP-FPM Configuration

**Tuned for 4GB RAM**:
```ini
pm = dynamic
pm.max_children = 50
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 15
pm.max_requests = 500
```

### OPcache

```ini
opcache.enable = 1
opcache.memory_consumption = 128
opcache.max_accelerated_files = 10000
opcache.revalidate_freq = 2
```

### MariaDB

```ini
innodb_buffer_pool_size = 512M
max_connections = 151
```

### Redis (If Enabled)

```
maxmemory: 256MB
policy: allkeys-lru
persistence: AOF
```

---

## 💾 Backup System (Working)

### Automated Backups

```
Schedule: Daily at 02:00 WIB
Retention: 7 days (auto-rotation)
Location: Docker volume bpkad_backups
Format: wordpress_backup_YYYYMMDD_HHMMSS.sql.gz
```

### Manual Backup

```bash
# Trigger backup manually
docker compose exec backup /usr/local/bin/backup-db.sh

# List backups
docker compose exec backup ls -lh /backups/

# Restore backup
./scripts/restore-backup.sh wordpress_backup_YYYYMMDD_HHMMSS.sql.gz
```

---

## 📝 Essential Scripts

All scripts located in `/var/www/bpkadweb/scripts/`:

```bash
# Credentials
./scripts/show-credentials.sh           # Display admin & DB credentials

# Maintenance
./scripts/healthcheck.sh                 # Check all services health
./scripts/update-wordpress.sh --all      # Update WP/plugins/themes
./scripts/cleanup.sh                     # Clean Docker resources

# Backup & Restore
./scripts/backup-db.sh                   # Manual backup trigger
./scripts/restore-backup.sh <file>       # Restore from backup

# Fixes
./scripts/fix-permissions.sh             # Fix file permissions
./scripts/fix-https-redirect.sh          # Fix HTTPS redirect loop
```

---

## ✅ Production Verification Checklist

### Daily Checks

- [ ] All containers running: `docker compose ps`
- [ ] Website accessible: HTTP 200
- [ ] No errors in logs: `docker compose logs --tail=50`
- [ ] Backup exists: Latest backup in `/backups/`

### Weekly Checks

- [ ] Check for updates: WordPress/plugins/themes
- [ ] Review security logs: Wordfence dashboard
- [ ] Verify disk space: `df -h`
- [ ] Test restore procedure

### Monthly Checks

- [ ] Full security audit: Run Site Health
- [ ] Performance review: Page load times
- [ ] Database optimization: `wp db optimize`
- [ ] Review and update plugins

---

## 🎯 Best Practices (Learned from Troubleshooting)

### DO's ✅

1. **ALWAYS** keep WordPress URLs as HTTP in Settings
2. **ALWAYS** add HTTPS detection to wp-config.php
3. **ALWAYS** use `docker compose exec -u root` for file operations
4. **ALWAYS** backup before making changes
5. **ALWAYS** test wp-config.php syntax after editing
6. **ALWAYS** clear cache after configuration changes
7. **ALWAYS** fix permissions after docker cp operations

### DON'Ts ❌

1. **NEVER** change WordPress URLs to HTTPS in Settings → General
2. **NEVER** edit wp-config.php without backup
3. **NEVER** use complex sed/awk for multi-line PHP code
4. **NEVER** assume docker cp maintains correct ownership
5. **NEVER** skip syntax validation (php -l)
6. **NEVER** install untested plugins on production
7. **NEVER** forget to clear browser cache after fixes

---

## 📞 Support & Resources

### Quick Access

```
Website: http://bpkad.bengkaliskab.go.id
HTTPS: https://bpkad.bengkaliskab.go.id (via Cloudflare)
Admin: http://bpkad.bengkaliskab.go.id/wp-admin/
Server: 10.10.10.31
```

### Credentials

```bash
# View all credentials
cd /var/www/bpkadweb
./scripts/show-credentials.sh
```

### Documentation

```
DOCUMENTATION_INDEX.md          - Complete documentation index
DEPLOYMENT_SUCCESS.md           - Post-deployment operations
PRODUCTION_FIX_FINAL.md         - All production fixes
SECURITY.md                     - Security hardening guide
README.md                       - Complete reference
```

### Contact

```
Email: admin@bpkad.bengkaliskab.go.id
Team: BPKAD IT Team
Repository: https://github.com/azzamweb/bpkadweb
```

---

## 🎊 Final Status

```
┌────────────────────────────────────────────────┐
│  ✅ PRODUCTION WORKING & VERIFIED              │
│                                                │
│  • WordPress: Running                          │
│  • HTTPS: Working (Cloudflare)                 │
│  • Mixed Content: Fixed                        │
│  • Permissions: Correct                        │
│  • Performance: Optimized                      │
│  • Security: Hardened                          │
│  • Backups: Automated                          │
│                                                │
│  🎉 READY FOR PRODUCTION USE! 🎉              │
└────────────────────────────────────────────────┘
```

**Configuration Last Updated**: November 2024  
**Status**: ✅ **PRODUCTION VERIFIED**  
**Maintained By**: BPKAD IT Team  

---

**This configuration has been tested, verified, and is currently running in production.**  
**All settings are proven to work and can be used as authoritative reference.**

🚀 **WordPress BPKAD Kabupaten Bengkalis - Production Ready!** 🚀

