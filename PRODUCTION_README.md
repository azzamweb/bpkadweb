# WordPress Production - Quick Reference

**Server**: 10.10.10.31 | **Domain**: bpkad.bengkaliskab.go.id | **Status**: ✅ Running

---

## 📍 Quick Access

```
Website: http://bpkad.bengkaliskab.go.id
Admin: http://bpkad.bengkaliskab.go.id/wp-admin/
Local: http://10.10.10.31
```

## 🔐 Credentials

```bash
# Show all credentials
./scripts/show-credentials.sh

# Show admin password only
cat secrets/wp_admin_password.txt
```

## 🚀 Common Commands

### Status & Monitoring

```bash
cd /var/www/bpkadweb

# Quick status
docker compose ps

# Health check
./scripts/healthcheck.sh

# View logs
docker compose logs -f
docker compose logs php-fpm --tail=50
```

### Backup & Restore

```bash
# Manual backup
docker compose exec backup /usr/local/bin/backup-db.sh

# List backups
docker compose exec backup ls -lh /backups/

# Restore backup
./scripts/restore-backup.sh wordpress_backup_YYYYMMDD_HHMMSS.sql.gz
```

### WordPress Maintenance

```bash
# Update all (WordPress + plugins + themes)
./scripts/update-wordpress.sh --all

# Update core only
./scripts/update-wordpress.sh --core

# Clear cache
docker compose run --rm wp-cli wp cache flush --allow-root

# Optimize database
docker compose run --rm wp-cli wp db optimize --allow-root
```

### Fix Common Issues

```bash
# Fix file permissions (uploads, plugins)
./scripts/fix-permissions.sh

# Fix HTTPS redirect loop
./scripts/fix-https-redirect.sh

# Restart all services
docker compose restart

# Restart specific service
docker compose restart php-fpm
```

## 🔄 Service Management

```bash
# Start services
docker compose up -d

# Stop services
docker compose stop

# Restart services
docker compose restart

# View status
docker compose ps

# Update from git
git pull origin main
```

## 📊 Backup Schedule

- **Frequency**: Daily at 02:00 WIB
- **Retention**: 7 days (auto-rotation)
- **Location**: Docker volume `bpkad_backups`

## 🆘 Emergency Contacts

- **IT Team**: admin@bpkad.bengkaliskab.go.id
- **Documentation**: See `/var/www/bpkadweb/DEPLOYMENT_SUCCESS.md`

## 📚 Full Documentation

```bash
# View documentation index
cat DOCUMENTATION_INDEX.md

# Main docs
cat README.md                    # Complete guide
cat DEPLOYMENT_SUCCESS.md        # Post-deployment
cat SECURITY.md                  # Security guide
cat PRODUCTION_FIX_FINAL.md      # Troubleshooting
```

---

**For complete documentation, see**: `DOCUMENTATION_INDEX.md`

