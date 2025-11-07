# Production Deployment Checklist

**Project**: BPKAD Kabupaten Bengkalis WordPress  
**Version**: Final - Production Verified  
**Date**: November 2024

---

## ✅ Pre-Deployment Checklist

### Infrastructure

- [ ] Docker & Docker Compose installed (v20.10+)
- [ ] Server resources: Minimum 4GB RAM, 2 CPU cores
- [ ] Disk space: Minimum 20GB available
- [ ] Network access: Ports 80, 443 accessible
- [ ] Domain configured: DNS pointing to server
- [ ] Cloudflare setup: SSL/TLS configured
- [ ] NPM/Reverse Proxy: Configured and tested
- [ ] Git installed and configured

### Security

- [ ] Firewall configured (only necessary ports open)
- [ ] SSH key-based authentication enabled
- [ ] Root login disabled
- [ ] Fail2ban or similar installed
- [ ] Server timezone set (Asia/Jakarta)
- [ ] Log rotation configured

### Backup

- [ ] Backup strategy planned
- [ ] Backup storage available
- [ ] Restore procedure tested
- [ ] Off-site backup configured (optional)

---

## 🚀 Deployment Steps

### Step 1: Clone Repository

```bash
- [ ] cd /var/www
- [ ] git clone https://github.com/azzamweb/bpkadweb.git
- [ ] cd bpkadweb
- [ ] git checkout main
```

### Step 2: Generate Secrets

```bash
- [ ] ./scripts/generate-secrets.sh
- [ ] Verify: ls -la secrets/
- [ ] Check: All 3 secret files created
  - [ ] db_root_password.txt
  - [ ] db_password.txt
  - [ ] wp_admin_password.txt
```

### Step 3: Configure Environment

```bash
- [ ] Copy env.example to .env (if using)
- [ ] Update configuration values
- [ ] Verify docker-compose.yml settings
  - [ ] Domain name correct
  - [ ] Local IP correct (10.10.10.31)
  - [ ] Resource limits appropriate
```

### Step 4: Start Services

```bash
- [ ] docker compose up -d
- [ ] Wait 30 seconds for services to initialize
- [ ] docker compose ps
- [ ] Verify: All services "Up (healthy)"
  - [ ] mariadb (healthy)
  - [ ] redis (healthy)
  - [ ] php-fpm (healthy)
  - [ ] nginx (healthy)
  - [ ] backup (running)
```

### Step 5: Initialize WordPress

```bash
- [ ] docker compose run --rm wp-cli /scripts/init-wordpress.sh
- [ ] Verify: WordPress installed
- [ ] Test: curl -I http://localhost
- [ ] Expected: HTTP 200 OK
```

### Step 6: Configure HTTPS Detection ⭐ CRITICAL!

```bash
- [ ] Add HTTPS detection to wp-config.php
  
  Method: Copy, edit, deploy
  
  docker cp bpkad-php-fpm:/var/www/html/wp-config.php ./wp-config.php.tmp
  
  nano ./wp-config.php.tmp
  
  Add after <?php:
  
  /* HTTPS Detection from Cloudflare */
  if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
      $_SERVER['HTTPS'] = 'on';
  }
  
  Save and exit
  
  docker cp ./wp-config.php.tmp bpkad-php-fpm:/var/www/html/wp-config.php
  
  docker compose exec -u root php-fpm chown www-data:www-data /var/www/html/wp-config.php
  
  docker compose exec -u root php-fpm chmod 644 /var/www/html/wp-config.php
  
- [ ] Verify syntax: docker compose exec php-fpm php -l /var/www/html/wp-config.php
- [ ] Restart: docker compose restart php-fpm nginx
```

### Step 7: Verify WordPress Settings ⭐ CRITICAL!

```bash
- [ ] Login to WordPress admin
- [ ] Go to: Settings → General
- [ ] VERIFY URLs are HTTP (NOT HTTPS!):
  - [ ] WordPress Address (URL): http://bpkad.bengkaliskab.go.id
  - [ ] Site Address (URL): http://bpkad.bengkaliskab.go.id
- [ ] DO NOT change to HTTPS!
```

### Step 8: Enable Redis Cache (Optional)

```bash
- [ ] WordPress admin → Settings → Redis
- [ ] Click "Enable Object Cache"
- [ ] Verify: Status shows "Connected"
```

### Step 9: Fix File Permissions

```bash
- [ ] ./scripts/fix-permissions.sh
- [ ] Verify: No permission errors in logs
```

### Step 10: Security Configuration

```bash
- [ ] Verify security plugins active:
  - [ ] Wordfence Security
  - [ ] Limit Login Attempts Reloaded
- [ ] Configure Wordfence firewall
- [ ] Test login rate limiting
- [ ] Verify XML-RPC disabled
```

---

## ✅ Post-Deployment Verification

### Website Access

- [ ] Test HTTP: http://bpkad.bengkaliskab.go.id
- [ ] Test HTTPS: https://bpkad.bengkaliskab.go.id
- [ ] Test Local IP: http://10.10.10.31
- [ ] Expected: All return HTTP 200
- [ ] Expected: No Mixed Content warnings on HTTPS

### WordPress Admin

- [ ] Login: http://bpkad.bengkaliskab.go.id/wp-admin/
- [ ] Username: admin
- [ ] Password: cat secrets/wp_admin_password.txt
- [ ] Verify: Dashboard accessible
- [ ] Verify: No errors or warnings

### Services Health

```bash
- [ ] docker compose ps
  Expected: All services "Up (healthy)"
  
- [ ] ./scripts/healthcheck.sh
  Expected: All checks pass
  
- [ ] docker compose logs --tail=50
  Expected: No ERROR messages
```

### Redis Cache

```bash
- [ ] docker compose exec redis redis-cli ping
  Expected: PONG
  
- [ ] docker compose exec php-fpm php -r "$r = new Redis(); echo $r->connect('redis', 6379) ? 'OK' : 'FAIL';"
  Expected: OK
  
- [ ] WordPress → Settings → Redis
  Expected: Status "Connected"
```

### Backups

```bash
- [ ] docker compose exec backup ls -lh /backups/
  Expected: See backup files
  
- [ ] docker compose exec backup /usr/local/bin/backup-db.sh
  Expected: New backup created
  
- [ ] Verify backup file exists and has size > 0
```

### Performance

- [ ] Test page load time: < 2 seconds
- [ ] Check PHP-FPM status: docker compose exec php-fpm php-fpm-healthcheck
- [ ] Check MariaDB connections: docker compose exec mariadb mysqladmin status
- [ ] Check Redis memory: docker compose exec redis redis-cli info memory

### Security

- [ ] Test rate limiting:
  - [ ] Try rapid wp-login requests (should be limited)
  - [ ] Try rapid admin page loads (should be limited)
- [ ] Test .git access: curl http://localhost/.git/
  Expected: 404 or 403
- [ ] Test wp-config access: curl http://localhost/wp-config.php
  Expected: 404 or 403
- [ ] Check security headers: curl -I https://bpkad.bengkaliskab.go.id
  Expected: X-Frame-Options, X-Content-Type-Options, etc.

---

## 🔒 Security Hardening Checklist

### Server Level

- [ ] UFW firewall configured
- [ ] Fail2ban configured for SSH, WordPress
- [ ] SSH root login disabled
- [ ] SSH key-based auth only
- [ ] Unused services disabled
- [ ] System updates applied
- [ ] Log rotation configured

### Docker Level

- [ ] Docker secrets used for passwords
- [ ] No secrets in environment variables
- [ ] Resource limits configured
- [ ] Health checks enabled
- [ ] Restart policies set
- [ ] Networks properly isolated

### WordPress Level

- [ ] File editor disabled (DISALLOW_FILE_EDIT)
- [ ] Admin over HTTPS forced
- [ ] Strong admin password
- [ ] Unused plugins removed
- [ ] All plugins updated
- [ ] Default admin username changed
- [ ] Database prefix changed (optional)
- [ ] Security plugins active

### Nginx Level

- [ ] Security headers configured
- [ ] Rate limiting enabled
- [ ] Sensitive files blocked (.git, .env, etc.)
- [ ] PHP execution blocked in uploads
- [ ] X-Forwarded-For logging configured
- [ ] Client body size limited

---

## 📊 Monitoring Setup

### Logs to Monitor

```bash
- [ ] docker compose logs -f  # Real-time
- [ ] docker compose logs php-fpm --tail=100  # PHP errors
- [ ] docker compose logs nginx --tail=100  # Access logs
- [ ] docker compose logs mariadb --tail=100  # DB errors
```

### Health Checks

```bash
- [ ] ./scripts/healthcheck.sh  # All services
- [ ] curl -I http://localhost  # HTTP status
- [ ] docker compose ps  # Container status
```

### Metrics to Track

- [ ] Page load time
- [ ] Server CPU usage
- [ ] Server memory usage
- [ ] Disk space available
- [ ] Database size
- [ ] Backup file size
- [ ] Docker volume sizes

---

## 🆘 Troubleshooting Checklist

### If Site Returns 500 Error

```bash
- [ ] Check PHP-FPM logs: docker compose logs php-fpm --tail=50
- [ ] Check wp-config.php syntax: docker compose exec php-fpm php -l /var/www/html/wp-config.php
- [ ] Restore backup if needed: docker compose exec php-fpm cp /var/www/html/wp-config.php.backup /var/www/html/wp-config.php
- [ ] Restart services: docker compose restart php-fpm nginx
```

### If Redirect Loop (ERR_TOO_MANY_REDIRECTS)

```bash
- [ ] Check WordPress URLs: wp option get home && wp option get siteurl
- [ ] Reset to HTTP: 
  docker compose run --rm wp-cli wp option update home 'http://bpkad.bengkaliskab.go.id' --allow-root
  docker compose run --rm wp-cli wp option update siteurl 'http://bpkad.bengkaliskab.go.id' --allow-root
- [ ] Clear cache: docker compose run --rm wp-cli wp cache flush --allow-root
- [ ] Clear browser cache and test
```

### If Mixed Content Warnings

```bash
- [ ] Verify HTTPS detection in wp-config.php
- [ ] Check X-Forwarded-Proto header: curl -I https://bpkad.bengkaliskab.go.id
- [ ] Clear WordPress cache
- [ ] Clear browser cache
```

### If Upload Errors

```bash
- [ ] Run: ./scripts/fix-permissions.sh
- [ ] Check ownership: docker compose exec php-fpm ls -la /var/www/html/wp-content/uploads
- [ ] Expected: www-data:www-data 755
```

### If Services Won't Start

```bash
- [ ] Check logs: docker compose logs --tail=100
- [ ] Check disk space: df -h
- [ ] Check Docker status: docker info
- [ ] Rebuild if needed: docker compose build --no-cache
```

---

## 📝 Documentation Review

### Required Reading

- [ ] [FINAL_WORKING_CONFIGURATION.md](FINAL_WORKING_CONFIGURATION.md) ⭐⭐⭐
- [ ] [LESSONS_LEARNED.md](LESSONS_LEARNED.md) ⭐
- [ ] [DEPLOYMENT_SUCCESS.md](DEPLOYMENT_SUCCESS.md)
- [ ] [SECURITY.md](SECURITY.md)

### Reference Documents

- [ ] [README.md](README.md) - Complete reference
- [ ] [QUICKSTART.md](QUICKSTART.md) - Quick deploy guide
- [ ] [PRODUCTION_FIX_FINAL.md](PRODUCTION_FIX_FINAL.md) - Troubleshooting
- [ ] [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md) - All docs index

---

## 🎯 Final Verification

### Critical Settings

- [ ] WordPress URLs are HTTP (not HTTPS!)
- [ ] HTTPS detection code in wp-config.php
- [ ] extra_hosts configured in docker-compose.yml
- [ ] File permissions correct (www-data:www-data)
- [ ] All services healthy
- [ ] Backups running
- [ ] Security plugins active

### Access Test

- [ ] Website loads: https://bpkad.bengkaliskab.go.id
- [ ] No Mixed Content warnings
- [ ] Images load correctly
- [ ] Admin accessible
- [ ] Can create/edit posts
- [ ] Can upload media

### Performance Test

- [ ] Page load < 2 seconds
- [ ] No PHP errors in logs
- [ ] Redis connected (if enabled)
- [ ] Database responding
- [ ] No memory issues

---

## ✅ Sign-Off

- [ ] All checklist items completed
- [ ] Documentation reviewed
- [ ] Credentials securely stored
- [ ] Backup verified
- [ ] Monitoring configured
- [ ] Handover completed

**Deployed By**: _________________  
**Date**: _________________  
**Verified By**: _________________  
**Production Ready**: ✅ Yes / ❌ No

---

## 📞 Support Contacts

**Technical Support**: admin@bpkad.bengkaliskab.go.id  
**Repository**: https://github.com/azzamweb/bpkadweb  
**Documentation**: See DOCUMENTATION_INDEX.md

---

**Note**: This checklist is based on actual production deployment and all issues encountered. Follow it carefully to avoid common pitfalls!

✅ **All items checked = Production Ready!** 🚀

