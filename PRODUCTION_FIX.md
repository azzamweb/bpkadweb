# Production Deployment - Quick Fix Guide

## 🔧 Errors Fixed

### Error 1: PHP-FPM Configuration ❌ → ✅
**Error**: `unknown entry 'process_control_timeout'`

**Root Cause**: Directive `process_control_timeout` tidak didukung di semua versi PHP-FPM.

**Fix Applied**: Removed dari `php/php-fpm.d/www.conf` line 69

### Error 2: Backup Container Cron ❌ → ✅
**Error**: `crontab: not found`

**Root Cause**: MariaDB image tidak include cron/crontab.

**Fix Applied**: 
- Created custom backup Dockerfile (`backup/Dockerfile`)
- Uses Alpine Linux dengan mysql-client dan dcron
- Proper cron setup dengan entrypoint

### Error 3: Docker Compose Version Warning ⚠️ → ✅
**Warning**: `the attribute 'version' is obsolete`

**Fix Applied**: Removed `version: '3.8'` from docker-compose.yml (tidak diperlukan di Compose V2)

## 🚀 Deploy Instructions (After Fix)

### Step 1: Pull Latest Changes

Jika menggunakan git:
```bash
cd /var/www/bpkadweb
git pull origin main
```

Atau jika manual update, pastikan files ini ter-update:
- ✅ `php/php-fpm.d/www.conf` (line 69 fixed)
- ✅ `backup/Dockerfile` (new file)
- ✅ `docker-compose.yml` (backup service updated, version removed)

### Step 2: Stop Existing Containers

```bash
cd /var/www/bpkadweb
docker compose down
```

### Step 3: Remove Old Containers (if any)

```bash
# Remove old containers
docker rm -f bpkad-php-fpm bpkad-backup 2>/dev/null || true

# Remove old images (optional but recommended)
docker rmi bpkadweb-php-fpm bpkadweb-backup 2>/dev/null || true
```

### Step 4: Rebuild Images

```bash
cd /var/www/bpkadweb

# Build with no cache to ensure clean build
docker compose build --no-cache
```

Expected output:
```
✓ Building php-fpm...
✓ Building backup...
```

### Step 5: Start Services

```bash
docker compose up -d
```

Expected output:
```
✓ Container bpkad-mariadb    Healthy
✓ Container bpkad-php-fpm    Healthy
✓ Container bpkad-backup     Started
✓ Container bpkad-nginx      Started
```

### Step 6: Verify Services

```bash
# Check all services status
docker compose ps

# Should show all services running and healthy
```

Expected output:
```
NAME              STATUS                    PORTS
bpkad-mariadb     Up (healthy)             
bpkad-php-fpm     Up (healthy)             
bpkad-backup      Up                        
bpkad-nginx       Up (healthy)             0.0.0.0:80->80/tcp
```

### Step 7: Check Logs

```bash
# View logs to ensure no errors
docker compose logs --tail=50

# Or specific service
docker compose logs php-fpm
docker compose logs backup
```

**PHP-FPM should show**:
```
✓ Starting PHP-FPM container...
✓ [pool www] pm = dynamic
✓ [pool www] pm.max_children = 50
✓ NOTICE: ready to handle connections
```

**Backup should show**:
```
✓ Starting backup service with cron...
✓ Backup schedule: Daily at 02:00 WIB
✓ Backup retention: 7 days
```

### Step 8: Initialize WordPress (First Time Only)

Jika ini deployment pertama kali:

```bash
# Generate secrets first (if not done)
cd /var/www/bpkadweb
./scripts/generate-secrets.sh

# Initialize WordPress
docker compose run --rm wp-cli /scripts/init-wordpress.sh
```

### Step 9: Test Website

```bash
# Test from server
curl -I http://localhost

# Test from local network
curl -I http://10.10.10.31

# Expected: HTTP/1.1 200 OK
```

### Step 10: Test Backup

```bash
# Trigger manual backup to test
docker compose exec backup /usr/local/bin/backup-db.sh

# Check backup created
docker compose exec backup ls -lh /backups/

# Should show backup file: wordpress_backup_YYYYMMDD_HHMMSS.sql.gz
```

## 🔍 Troubleshooting

### If PHP-FPM Still Fails

```bash
# Check config syntax
docker compose exec php-fpm php-fpm -t

# View detailed logs
docker compose logs php-fpm --tail=100

# Restart service
docker compose restart php-fpm
```

### If Backup Container Fails

```bash
# Check backup logs
docker compose logs backup

# Test cron is running
docker compose exec backup ps aux | grep crond

# Test backup script manually
docker compose exec backup /usr/local/bin/backup-db.sh
```

### If Services Won't Start

```bash
# Check disk space
df -h

# Check Docker daemon
sudo systemctl status docker

# View all logs
docker compose logs

# Full reset (nuclear option)
docker compose down -v  # WARNING: This removes volumes!
docker compose up -d --build
```

## ✅ Verification Checklist

After deployment, verify:

- [ ] All containers running: `docker compose ps`
- [ ] PHP-FPM healthy: No config errors in logs
- [ ] Backup cron active: `docker compose exec backup ps aux | grep crond`
- [ ] MariaDB healthy: `docker compose exec mariadb mysqladmin ping`
- [ ] Nginx serving: `curl -I http://localhost`
- [ ] Website accessible: Browse to http://10.10.10.31
- [ ] WordPress admin accessible: http://10.10.10.31/wp-admin/
- [ ] Backup working: Manual test successful

## 📊 Quick Status Check Script

Save this as `check-status.sh`:

```bash
#!/bin/bash
echo "=== BPKAD WordPress Status ==="
echo ""
echo "1. Docker Compose Services:"
docker compose ps
echo ""
echo "2. PHP-FPM Status:"
docker compose exec php-fpm php-fpm -t 2>&1 | head -5
echo ""
echo "3. Backup Cron Status:"
docker compose exec backup ps aux | grep -v grep | grep crond
echo ""
echo "4. Website Status:"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost
echo ""
echo "5. Disk Usage:"
df -h /var/lib/docker
echo ""
echo "6. Recent Backups:"
docker compose exec backup ls -lht /backups/ | head -5
```

Run it:
```bash
chmod +x check-status.sh
./check-status.sh
```

## 🆘 Emergency Rollback

If deployment fails completely:

```bash
# Stop everything
docker compose down

# Restore from backup (if database was changed)
./scripts/restore-backup.sh <backup_file>

# Start with old version
# (use git to revert changes first if needed)
docker compose up -d
```

## 📞 Support

If issues persist after following this guide:

1. Check logs: `docker compose logs > debug.log`
2. Check system: `docker info`
3. Check disk: `df -h`
4. Contact: admin@bpkad.bengkaliskab.go.id

---

**Last Updated**: November 2024  
**Fixes Applied**: PHP-FPM config, Backup cron, Docker Compose version  
**Status**: Ready for Production ✅

