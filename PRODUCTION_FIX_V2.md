# Production Fix v2 - PHP-FPM Log Directory

## 🔧 Additional Error Fixed

### Error: PHP-FPM Cannot Create Slowlog
**Error Message**: 
```
ERROR: Unable to create or open slowlog(/var/log/php-fpm/slow.log): No such file or directory (2)
ERROR: failed to post process the configuration
ERROR: FPM initialization failed
```

**Root Cause**: 
- Directory `/var/log/php-fpm/` tidak ada di PHP-FPM container
- PHP-FPM config (`www.conf` & `php.ini`) menggunakan log paths:
  - `/var/log/php-fpm/slow.log`
  - `/var/log/php-fpm/access.log`
  - `/var/log/php-fpm/error.log`
  - `/var/log/php-fpm/opcache.log`

**Solution**: 
Added log directory creation di `php/Dockerfile`:
```dockerfile
# Create log directories for PHP-FPM
RUN mkdir -p /var/log/php-fpm \
    && chown -R www-data:www-data /var/log/php-fpm \
    && chmod 755 /var/log/php-fpm
```

## 🚀 Quick Deploy (Updated)

### Di Production Server

```bash
cd /var/www/bpkadweb

# Pull latest fix
git pull origin main

# Stop containers
docker compose down

# Remove old PHP-FPM image (important!)
docker rmi bpkadweb-php-fpm

# Rebuild with fix
docker compose build --no-cache php-fpm

# Start all services
docker compose up -d

# Wait for services to be healthy
sleep 30

# Verify
docker compose ps
docker compose logs php-fpm --tail=20
```

## ✅ Expected Output (After Fix)

### docker compose ps
```
NAME              STATUS                    PORTS
bpkad-mariadb     Up (healthy)             
bpkad-php-fpm     Up (healthy)             ✓ FIXED!
bpkad-backup      Up                        
bpkad-nginx       Up (healthy)             0.0.0.0:80->80/tcp
```

### docker compose logs php-fpm --tail=20
```
✓ Starting PHP-FPM container...
✓ wp-config.php not found. Waiting for initialization...
✓ [NOTICE] fpm is running, pid 1
✓ [NOTICE] ready to handle connections
```

**No more errors!** 🎉

## 🔍 Verify Logs Working

Test log files creation:

```bash
# Check log directory exists
docker compose exec php-fpm ls -la /var/log/php-fpm/

# Expected output:
# drwxr-xr-x 2 www-data www-data 4096 Nov  7 00:00 .
# -rw-r--r-- 1 www-data www-data    0 Nov  7 00:00 access.log
# -rw-r--r-- 1 www-data www-data    0 Nov  7 00:00 error.log
# -rw-r--r-- 1 www-data www-data    0 Nov  7 00:00 slow.log
```

Test accessing logs:

```bash
# View PHP-FPM access log
docker compose exec php-fpm tail -f /var/log/php-fpm/access.log

# View PHP-FPM error log
docker compose exec php-fpm tail -f /var/log/php-fpm/error.log

# View slow query log
docker compose exec php-fpm tail -f /var/log/php-fpm/slow.log
```

## 📊 Complete Fix Summary

### All Issues Fixed:

| # | Issue | Status | Fix |
|---|-------|--------|-----|
| 1 | PHP-FPM `process_control_timeout` | ✅ Fixed | Removed from www.conf |
| 2 | Backup `crontab: not found` | ✅ Fixed | Custom Dockerfile with cron |
| 3 | Docker Compose version warning | ✅ Fixed | Removed obsolete version |
| 4 | PHP-FPM log directory missing | ✅ Fixed | Create in Dockerfile |

### Files Changed:

```
✅ php/Dockerfile                - Added log directory creation
✅ php/php-fpm.d/www.conf        - Fixed process_control_timeout
✅ backup/Dockerfile              - NEW: Custom backup with cron
✅ docker-compose.yml             - Updated backup, removed version
```

## 🎯 One-Line Deploy

Untuk deploy semua fixes sekaligus:

```bash
cd /var/www/bpkadweb && \
git pull origin main && \
docker compose down && \
docker rmi bpkadweb-php-fpm bpkadweb-backup 2>/dev/null || true && \
docker compose build --no-cache && \
docker compose up -d && \
sleep 30 && \
docker compose ps
```

## 📝 Post-Deployment Checklist

After deployment, verify these:

- [ ] All containers running: `docker compose ps`
- [ ] PHP-FPM healthy (no errors): `docker compose logs php-fpm`
- [ ] PHP-FPM log directory exists: `docker compose exec php-fpm ls -la /var/log/php-fpm/`
- [ ] Backup cron active: `docker compose exec backup ps aux | grep crond`
- [ ] MariaDB healthy: `docker compose exec mariadb mysqladmin ping`
- [ ] Nginx serving: `curl -I http://localhost`
- [ ] Website accessible: Browse to http://10.10.10.31

## 🔄 Initialize WordPress (First Time)

If this is first deployment:

```bash
cd /var/www/bpkadweb

# Generate secrets (if not already done)
./scripts/generate-secrets.sh

# Initialize WordPress
docker compose run --rm wp-cli /scripts/init-wordpress.sh

# Verify website works
curl -I http://localhost
```

## 🆘 If Still Having Issues

### Check Logs Detail:
```bash
# All services
docker compose logs --tail=100

# Specific service with timestamps
docker compose logs --tail=50 --timestamps php-fpm

# Follow logs live
docker compose logs -f
```

### Restart Specific Service:
```bash
# Restart PHP-FPM only
docker compose restart php-fpm

# Check status
docker compose ps php-fpm
```

### Nuclear Option (Full Reset):
```bash
# WARNING: This removes all data including database!
docker compose down -v
docker compose up -d --build

# Then re-initialize WordPress
./scripts/generate-secrets.sh
docker compose run --rm wp-cli /scripts/init-wordpress.sh
```

### Disk Space Check:
```bash
# Check disk space
df -h

# Check Docker disk usage
docker system df

# Clean up if needed
docker system prune -a
```

## 📞 Support

If issues persist:

1. Collect logs: `docker compose logs > logs.txt`
2. Check system: `docker info > docker-info.txt`
3. Check config: `docker compose config > config.txt`
4. Contact: admin@bpkad.bengkaliskab.go.id

Include the collected files when requesting support.

---

**Version**: v2  
**Date**: November 2024  
**Status**: All Known Issues Fixed ✅  
**Ready**: Production Ready 🚀

