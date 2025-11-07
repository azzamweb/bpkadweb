# Lessons Learned - WordPress Docker Deployment

**Project**: BPKAD Kabupaten Bengkalis  
**Period**: November 2024  
**Status**: Successfully Deployed & Documented  

---

## 🎓 Key Lessons from Production Deployment

### 1. HTTPS with Cloudflare & Reverse Proxy

**Problem**: Infinite redirect loop when WordPress URLs changed to HTTPS

**Root Cause**:
- Cloudflare terminates SSL at edge
- Internal communication (Cloudflare → Server) uses HTTP
- WordPress sees HTTP requests
- When URLs set to HTTPS, WordPress tries to redirect → infinite loop

**Solution**:
```php
// wp-config.php - HTTPS Detection
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}
```

**Golden Rule**:
- ✅ WordPress URLs: Always **HTTP** in Settings
- ✅ Add HTTPS detection code to wp-config.php
- ✅ External users get HTTPS (via Cloudflare)
- ✅ No redirect loops!

---

### 2. Mixed Content Errors

**Problem**: Images/CSS/JS not loading on HTTPS pages

**Cause**: WordPress generates HTTP URLs because it doesn't detect HTTPS

**Solution**: Same as #1 - Add HTTPS detection to wp-config.php

**Wrong Approach** ❌:
- Installing plugins (can cause conflicts)
- Database search-replace (risky)
- Changing WordPress URLs to HTTPS (causes redirect loop)

**Right Approach** ✅:
- Add simple HTTPS detection code
- WordPress automatically generates correct URLs
- Works for all content (images, CSS, JS)

---

### 3. Docker Container DNS Resolution

**Problem**: `wp cron test` failed with "Could not resolve host"

**Cause**: Containers can't resolve domain name to local IP

**Solution**: Add `extra_hosts` to docker-compose.yml
```yaml
php-fpm:
  extra_hosts:
    - "bpkad.bengkaliskab.go.id:10.10.10.31"
```

**Learning**: Containers need explicit DNS mapping for local domains

---

### 4. File Permissions After docker cp

**Problem**: After `docker cp`, wp-config.php had wrong ownership (1000:1000)

**Cause**: docker cp preserves host user ownership

**Solution**: Always fix permissions after copy
```bash
docker compose exec -u root php-fpm chown www-data:www-data /path/to/file
docker compose exec -u root php-fpm chmod 644 /path/to/file
```

**Learning**: docker cp != safe for production files. Always check permissions!

---

### 5. Editing wp-config.php Safely

**Problem**: sed/awk with multi-line PHP failed (unbalanced braces, syntax errors)

**Wrong Approach** ❌:
- Complex sed commands with escaped characters
- Automated multi-line insertions
- No validation before deployment

**Right Approach** ✅:
```bash
# Copy out, edit locally, validate, copy back
docker cp container:/file ./file
nano ./file  # Edit with safe editor
php -l ./file  # Validate syntax
docker cp ./file container:/file
docker exec -u root container chown www-data:www-data /file
```

**Learning**: For critical files, manual editing is safer than automation

---

### 6. PHP-FPM Configuration Issues

**Problems Encountered**:
- `process_control_timeout` not supported in all versions
- `listen.allowed_clients = any` causes connection errors
- `opcache.fast_shutdown` deprecated in PHP 7.2+

**Solutions**:
- Remove unsupported directives
- Comment out problematic settings
- Check PHP version compatibility

**Learning**: Always test PHP-FPM config in target environment first

---

### 7. Backup Cron in Docker

**Problem**: `crontab: not found` in Alpine-based backup container

**Cause**: Base images don't include cron by default

**Solution**: Create custom Dockerfile
```dockerfile
FROM alpine:3.19
RUN apk add --no-cache mariadb-client dcron
# Configure cron job
ENTRYPOINT ["crond", "-f", "-l", "2"]
```

**Learning**: Always verify required tools exist in container images

---

### 8. Redis Plugin Conflicts

**Problem**: Really Simple Security plugin caused JavaScript errors

**Cause**: Plugin conflicts with other plugins or theme

**Solution**: 
- Disable problematic plugin
- Use manual wp-config.php method instead
- Simpler is better!

**Learning**: Plugins can introduce complexity. Manual solutions often more reliable.

---

### 9. WordPress REST API Issues

**Problem**: REST API SSL errors, scheduled events failing

**Cause**: WordPress trying to make HTTPS requests to itself internally

**Solution**: Add loopback fix to wp-config.php
```php
add_filter('https_ssl_verify', '__return_false');  // For internal requests only
add_filter('rest_url', function($url) {
    return str_replace('https://', 'http://', $url);  // Internal uses HTTP
});
```

**Learning**: Internal vs external communication needs different handling

---

### 10. Site Health Warnings vs Reality

**Problem**: Site Health showing warnings but site works fine

**Reality Check**:
- REST API warnings: Important for Gutenberg, not critical for Classic Editor
- Object Cache: Nice to have, not required
- Scheduled Events: Works via real cron if WP-Cron doesn't

**Learning**: Site Health is a guide, not gospel. Focus on actual functionality!

---

## 🎯 Best Practices Discovered

### Configuration Management

1. **Always Backup First**
   ```bash
   docker exec container cp /file /file.backup.$(date +%Y%m%d-%H%M%S)
   ```

2. **Always Validate Syntax**
   ```bash
   docker exec container php -l /path/to/php-file
   ```

3. **Always Test Locally First**
   - Don't test on production!
   - Use staging or local environment

4. **Keep It Simple**
   - Avoid complex automation for critical files
   - Manual > Automated for sensitive configs

5. **Document Everything**
   - What worked
   - What didn't
   - Why

### Docker Best Practices

1. **Use -u root When Needed**
   ```bash
   docker compose exec -u root container command
   ```

2. **Check Container User**
   ```bash
   docker exec container whoami
   ```

3. **Always Fix Permissions**
   - After docker cp
   - After file edits
   - Check: `ls -la`

4. **Use Named Volumes**
   - Better than bind mounts
   - Easier backups
   - Better performance

5. **Health Checks Are Critical**
   - Helps orchestration
   - Monitors service status
   - Enables auto-restart

### WordPress Specific

1. **Never Store Secrets in Git**
   - Use Docker secrets
   - Use .env (in .gitignore)
   - Use wp-config.php (not in git)

2. **Separate Concerns**
   - WordPress URLs: HTTP (internal)
   - User Access: HTTPS (via proxy)
   - Detection: Headers (X-Forwarded-Proto)

3. **Minimize Plugins**
   - Only use essential plugins
   - Test before production
   - Manual config > plugin when possible

4. **Monitor Everything**
   - Logs: `docker compose logs`
   - Health: `./scripts/healthcheck.sh`
   - Backups: Verify daily

5. **Clear Cache Often**
   - After config changes
   - After updates
   - When debugging

---

## 🚨 Common Pitfalls & How to Avoid

### Pitfall 1: "It Works on My Machine"

**Problem**: Local works, production fails

**Avoid**:
- Test in production-like environment
- Use same PHP version
- Same web server config
- Same network setup

### Pitfall 2: Over-Automation

**Problem**: Complex scripts that break in edge cases

**Avoid**:
- Keep scripts simple
- Add validation at each step
- Provide manual fallback
- Test failure scenarios

### Pitfall 3: Assuming Container Behavior

**Problem**: Expecting containers to work like VMs

**Avoid**:
- Understand container networking
- Know which user runs processes
- Check what's installed in image
- Read Dockerfile

### Pitfall 4: Ignoring Logs

**Problem**: Not checking logs until things break

**Avoid**:
- Monitor logs proactively
- Set up log rotation
- Use centralized logging
- Check for warnings, not just errors

### Pitfall 5: No Rollback Plan

**Problem**: Can't undo changes when they go wrong

**Avoid**:
- Always backup before changes
- Keep old configs
- Document rollback procedure
- Test restore process

---

## 📈 Evolution of Approach

### Initial Approach (Didn't Work)

```bash
# Try to automate everything with sed
sed -i 's/complex/pattern/' file  # ❌ Failed with multi-line PHP

# Use complex script
./auto-fix-everything.sh  # ❌ Broke wp-config.php
```

### Intermediate (Getting Better)

```bash
# Python script with validation
python3 fix-wpconfig.py  # ⚠️ Still had issues with quote counting

# Better but still automated
```

### Final Approach (Works!)

```bash
# Copy, edit manually, validate, deploy
docker cp container:/file ./file
nano ./file  # ✅ Safe, visible, testable
php -l ./file  # ✅ Validated
docker cp ./file container:/file  # ✅ Deployed
```

**Lesson**: Sometimes old school is best school!

---

## 💡 Key Insights

### 1. Simplicity Wins

Complex automated solutions often fail in unexpected ways. Simple, manual processes are:
- Easier to understand
- Easier to debug
- More reliable
- More maintainable

### 2. Validate Everything

Never assume:
- File copied successfully → Check it exists
- Syntax is correct → Run php -l
- Permissions are right → Run ls -la
- Service restarted → Check docker compose ps

### 3. Documentation is Critical

Good documentation:
- Saves hours of debugging
- Helps team members
- Provides reference for future
- Makes maintenance easier

### 4. Production is Different

What works locally might not work in production:
- Different network setup
- Different security policies
- Different resource constraints
- Different user expectations

### 5. Backup Everything

Before any change:
- Backup files
- Backup database
- Backup configs
- Test restore

---

## 🎓 Skills Developed

### Technical

- ✅ Docker networking & DNS
- ✅ Nginx reverse proxy config
- ✅ PHP-FPM optimization
- ✅ MariaDB tuning
- ✅ WordPress security hardening
- ✅ SSL/TLS with Cloudflare
- ✅ Linux file permissions
- ✅ Shell scripting best practices

### Process

- ✅ Systematic troubleshooting
- ✅ Root cause analysis
- ✅ Documentation practices
- ✅ Version control workflow
- ✅ Production deployment
- ✅ Incident response
- ✅ Risk management

---

## 🚀 What Worked Well

1. **Incremental approach** - Fix one thing at a time
2. **Always backup** - Never regretted having backup
3. **Validate syntax** - Caught many errors before deployment
4. **Clear documentation** - Easy to reference later
5. **Simple solutions** - Less complex = less problems
6. **Git commits** - Easy to track changes and rollback

---

## 🎯 Final Takeaway

**The best solution is often not the most clever or automated, but the one that:**
- ✅ Works reliably
- ✅ Is easy to understand
- ✅ Is easy to maintain
- ✅ Is well documented
- ✅ Can be debugged quickly

---

**Remember**: 
> "Make it work, then make it better. Don't try to make it perfect from the start."

**Status**: All lessons documented and applied in production ✅  
**Result**: WordPress running smoothly in production 🚀  
**Date**: November 2024

