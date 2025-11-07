# 🛡️ Prevent Future Issues - Quick Guide

**Purpose**: Mencegah masalah yang sudah pernah terjadi terulang lagi  
**Status**: Based on 12 resolved issues in production

---

## ❌ JANGAN PERNAH LAKUKAN INI!

### 1. ❌ Jangan Ganti WordPress URL ke HTTPS

**Jangan**:
```
Settings → General
WordPress Address (URL): https://bpkad.bengkaliskab.go.id  ← SALAH!
Site Address (URL): https://bpkad.bengkaliskab.go.id       ← SALAH!
```

**Harus**:
```
WordPress Address (URL): http://bpkad.bengkaliskab.go.id   ← BENAR!
Site Address (URL): http://bpkad.bengkaliskab.go.id        ← BENAR!
```

**Kenapa**:
- Cloudflare handle SSL di edge
- Internal WordPress pakai HTTP
- Ganti ke HTTPS = redirect loop!
- User tetap lihat HTTPS (via Cloudflare)

**Jika Sudah Terlanjur**:
```bash
./scripts/fix-https-redirect.sh
```

---

### 2. ❌ Jangan Edit wp-config.php Sembarangan

**Jangan**:
- Tambah fungsi `add_filter()` di wp-config.php
- Hapus HTTPS detection code
- Hapus Redis configuration
- Edit tanpa backup

**Harus**:
- Backup dulu: `cp wp-config.php wp-config.php.backup`
- Hanya tambah `define()` atau assign variable
- Untuk `add_filter()` → pakai MU-plugin
- Validate syntax: `php -l wp-config.php`

**HTTPS Detection Code (JANGAN HAPUS!)**:
```php
/* HTTPS Detection from Cloudflare */
if (isset($_SERVER["HTTP_X_FORWARDED_PROTO"]) && $_SERVER["HTTP_X_FORWARDED_PROTO"] === "https") {
    $_SERVER["HTTPS"] = "on";
}
```

**Jika wp-config.php Rusak**:
```bash
# Restore backup
docker compose exec php-fpm cp /var/www/html/wp-config.php.backup /var/www/html/wp-config.php
docker compose restart php-fpm
```

---

### 3. ❌ Jangan Ubah File Permissions Manual

**Jangan**:
```bash
# Di host
chmod 777 wp-content/  # BAHAYA!
chown user:user wp-content/  # SALAH!
```

**Harus**:
```bash
# Pakai script yang sudah disediakan
./scripts/fix-permissions.sh
```

**Correct Permissions**:
```
/var/www/html/wp-content/         → 755, www-data:www-data
/var/www/html/wp-content/uploads/ → 755, www-data:www-data
/var/www/html/wp-config.php       → 644, www-data:www-data
```

**Kenapa**:
- WordPress run sebagai `www-data` (UID 33)
- File harus owned by www-data
- Wrong permissions = upload gagal

---

### 4. ❌ Jangan Stop atau Hapus Redis Service

**Jangan**:
```bash
docker compose stop redis
docker compose rm redis
```

**Kenapa**:
- Performance drop 3x
- Database queries naik 5x
- Cache hit rate jadi 0%
- Website jadi lambat

**Jika Redis Error**:
```bash
# Restart saja
docker compose restart redis

# Verify
docker compose exec php-fpm wp redis info --allow-root
```

---

### 5. ❌ Jangan Modifikasi docker-compose.yml Sembarangan

**Jangan Hapus**:
- `extra_hosts` section (needed for DNS)
- `redis` service (needed for performance)
- `healthcheck` section (needed for monitoring)
- `depends_on` relationships

**Jika Perlu Edit**:
1. Backup dulu: `cp docker-compose.yml docker-compose.yml.backup`
2. Edit dengan hati-hati
3. Validate: `docker compose config`
4. Test: `docker compose up -d`
5. Check: `docker compose ps`

---

## ✅ LAKUKAN INI SECARA RUTIN

### Daily Tasks

```bash
# Cek status semua service
docker compose ps

# Cek backup hari ini
docker compose exec backup ls -lh /backups/ | tail -1
```

---

### Weekly Tasks

```bash
# Cek update tersedia
./scripts/update-wordpress.sh --check

# Optimize database
docker compose run --rm wp-cli wp db optimize --allow-root

# Cek disk space
df -h

# Cek memory usage
free -h
```

---

### Monthly Tasks

```bash
# Update WordPress + plugins + themes
./scripts/update-wordpress.sh --all

# Clean up Docker
./scripts/cleanup.sh

# Review security logs
docker compose logs nginx | grep -i "403\|404\|500" | tail -50

# Save working config
./scripts/save-working-config.sh
```

---

## 🆘 Quick Troubleshooting

### Site Down (HTTP 500)

```bash
# 1. Cek logs
docker compose logs php-fpm --tail=100

# 2. Cek wp-config syntax
docker compose exec php-fpm php -l /var/www/html/wp-config.php

# 3. Restart services
docker compose restart

# 4. Jika masih error, restore config
docker compose exec php-fpm cp /var/www/html/wp-config.php.backup /var/www/html/wp-config.php
docker compose restart php-fpm
```

---

### Redirect Loop

```bash
./scripts/fix-https-redirect.sh
```

**Atau manual**:
```bash
docker compose run --rm wp-cli wp option update home 'http://bpkad.bengkaliskab.go.id' --allow-root
docker compose run --rm wp-cli wp option update siteurl 'http://bpkad.bengkaliskab.go.id' --allow-root
```

---

### Upload Gagal

```bash
./scripts/fix-permissions.sh
```

---

### Redis Tidak Jalan

```bash
# Restart Redis
docker compose restart redis

# Verify plugin
docker compose exec php-fpm wp plugin list --allow-root | grep redis

# If not active
docker compose exec php-fpm wp plugin activate redis-cache --allow-root
docker compose exec php-fpm wp redis enable --allow-root
```

---

### Database Connection Error

```bash
# Check MariaDB
docker compose ps mariadb

# Check logs
docker compose logs mariadb --tail=50

# Restart MariaDB
docker compose restart mariadb

# Wait 30 seconds
sleep 30

# Test connection
docker compose run --rm wp-cli wp db check --allow-root
```

---

## 📋 Pre-Update Checklist

Sebelum update WordPress/plugin/theme:

```bash
# 1. Backup database
docker compose exec backup /usr/local/bin/backup-db.sh

# 2. Save current config
./scripts/save-working-config.sh

# 3. Check current versions
docker compose run --rm wp-cli wp core version --allow-root
docker compose run --rm wp-cli wp plugin list --allow-root

# 4. Update
./scripts/update-wordpress.sh --all

# 5. Test website
curl -I http://localhost
curl -I https://bpkad.bengkaliskab.go.id

# 6. Check admin
# Login ke wp-admin dan test functionality
```

---

## ⚠️ Expected Site Health Warnings

**Ini NORMAL - jangan diperbaiki!**

WordPress Site Health akan selalu menampilkan:
1. ⚠️ REST API SSL error
2. ⚠️ Loopback request SSL error

**Kenapa**:
- Cloudflare handle SSL di edge
- Internal WordPress pakai HTTP
- WordPress test dirinya via HTTPS
- SSL handshake gagal (expected!)

**Impact**: TIDAK ADA - semua fungsi bekerja 100%

**Action**: ABAIKAN warning ini - purely cosmetic!

---

## 🔒 Security Best Practices

### Passwords

```bash
# JANGAN hardcode password di config
# Gunakan Docker secrets

# Generate new secrets jika perlu
./scripts/generate-secrets.sh
```

### File Access

```bash
# JANGAN chmod 777 apapun!
# Gunakan permissions yang tepat:

Directories:     755 (rwxr-xr-x)
Files:           644 (rw-r--r--)
wp-config.php:   644 (rw-r--r--)
Uploads:         755 (rwxr-xr-x)

Owner: www-data:www-data
```

### Admin Access

```bash
# Limit admin access by IP jika perlu
# Edit nginx/conf.d/bpkad.conf:

location ~ ^/(wp-admin|wp-login\.php) {
    # allow 10.10.10.0/24;  # Internal network
    # allow 103.13.206.0/24;  # Office network
    # deny all;
    
    # ... existing config ...
}
```

---

## 📊 Performance Monitoring

### Check Redis Cache

```bash
# Info
docker compose exec php-fpm wp redis info --allow-root

# Should show:
# - Status: Connected
# - Hit Rate: 80-90%
```

### Check OPcache

```bash
docker compose exec php-fpm php -r "var_dump(opcache_get_status());"

# Should show:
# - opcache_enabled: true
# - cache_full: false
# - hit_rate: >90%
```

### Check Database

```bash
# Table optimization
docker compose run --rm wp-cli wp db optimize --allow-root

# Size check
docker compose run --rm wp-cli wp db size --allow-root --tables

# Query check (slow queries)
docker compose logs mariadb | grep "Slow query"
```

---

## 🎯 Critical Configuration Files

**JANGAN EDIT** tanpa backup:

1. `docker-compose.yml`
2. `nginx/conf.d/bpkad.conf`
3. `php/Dockerfile`
4. `php/php-fpm.d/www.conf`
5. `php/php.ini`
6. `mariadb/my.cnf`

**Jika Harus Edit**:
```bash
# 1. Backup
cp <file> <file>.backup

# 2. Edit
nano <file>

# 3. Validate (for docker-compose.yml)
docker compose config

# 4. Apply
docker compose up -d

# 5. Test
docker compose ps
docker compose logs <service>

# 6. If broken, restore
cp <file>.backup <file>
docker compose up -d
```

---

## 📞 Emergency Contacts

### Service Down
```bash
# Quick restart all
docker compose restart

# Rebuild if needed
docker compose up -d --build

# Check health
./scripts/healthcheck.sh
```

### Data Recovery
```bash
# List backups
docker compose exec backup ls -lh /backups/

# Restore
./scripts/restore-backup.sh <backup_file>

# Verify
docker compose run --rm wp-cli wp db check --allow-root
```

---

## 📚 Important Documentation

**WAJIB BACA**:
1. `FINAL_PRODUCTION_CONFIG.md` - Current working config
2. `UPDATE_LOG.md` - History of all 12 fixes
3. `PRODUCTION_README.md` - Quick commands

**Reference**:
4. `DEPLOYMENT_SUCCESS.md` - Operations guide
5. `SECURITY.md` - Security guide

---

## ✅ Final Reminders

```
✅ WordPress URLs HARUS HTTP (not HTTPS)
✅ Keep HTTPS detection code di wp-config.php
✅ Keep Redis service running
✅ Use ./scripts/ untuk maintenance
✅ Backup before major changes
✅ Ignore Site Health SSL warnings (expected)
✅ Fix permissions dengan script, bukan manual
✅ Don't add add_filter() to wp-config.php
✅ Validate syntax after editing PHP files
✅ Monitor backups daily
✅ Update monthly
```

---

**Ingat**: Configuration sekarang sudah STABLE dan TESTED!  
Jangan ubah tanpa alasan kuat dan tanpa backup!

**Status**: ✅ Production Ready & Stable  
**Last Updated**: November 2024  
**All Issues**: Resolved (12/12 = 100%)

🎉 **Keep it simple, keep it working!** 🎉

