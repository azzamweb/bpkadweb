# 🎯 START HERE - BPKAD WordPress Docker

## Selamat Datang! 👋

Project WordPress production-ready untuk BPKAD Kabupaten Bengkalis telah siap digunakan.

## 📚 Dokumentasi Urutan Baca

Silakan baca dokumentasi dalam urutan berikut:

### 1️⃣ **QUICKSTART.md** ⚡
**Untuk**: Quick deploy 15 menit  
**Isi**: 5 langkah deployment cepat  
**Baca jika**: Anda familiar dengan Docker dan ingin deploy cepat

### 2️⃣ **DEPLOY.md** 📖
**Untuk**: Step-by-step deployment lengkap  
**Isi**: Panduan detail dari server setup sampai production  
**Baca jika**: First time deploy atau butuh panduan detail

### 3️⃣ **README.md** 📘
**Untuk**: Dokumentasi lengkap  
**Isi**: Configuration, maintenance, troubleshooting  
**Baca jika**: Sudah deploy, butuh info maintenance/troubleshooting

### 4️⃣ **SECURITY.md** 🔒
**Untuk**: Security hardening  
**Isi**: Security checklist, monitoring, incident response  
**Baca jika**: Concern dengan security (wajib untuk production!)

### 5️⃣ **INSTALLATION_CHECKLIST.md** ✅
**Untuk**: Installation tracking  
**Isi**: Checklist lengkap untuk installation  
**Gunakan**: Print dan centang saat instalasi

### 6️⃣ **PROJECT_STRUCTURE.md** 🗂️
**Untuk**: Understanding project structure  
**Isi**: Penjelasan setiap file dan directory  
**Baca jika**: Ingin memahami struktur project

## ⚡ Quick Commands

Jika sudah familiar dengan project ini:

```bash
# First time installation
make install

# Start services
make start

# View logs
make logs

# Run backup
make backup

# Health check
make health

# Stop services
make stop
```

## 🎯 What This Project Provides

✅ **WordPress Latest** - Versi stable dengan bahasa Indonesia  
✅ **MariaDB 11.2** - Database optimized  
✅ **PHP-FPM 8.3** - Dengan OPcache, APCu, Redis  
✅ **Nginx 1.25** - Reverse proxy dengan security headers  
✅ **Auto Backup** - Daily backup dengan 7-day retention  
✅ **Security** - Hardened untuk standar pemerintahan  
✅ **Multi-domain** - Domain + IP lokal support  
✅ **Cloudflare Ready** - Real IP forwarding configured  

## 🏗️ Architecture Overview

```
Internet
   ↓
Cloudflare (SSL/CDN/DDoS)
   ↓
NPM (103.13.206.172)
   ↓
Mikrotik NAT (103.13.206.172:8089)
   ↓
Server (10.10.10.31:80)
   ↓
┌─────────────────────────────────┐
│  Docker Compose Stack           │
│  ┌───────────┐   ┌───────────┐ │
│  │   Nginx   │ → │  PHP-FPM  │ │
│  └───────────┘   └─────┬─────┘ │
│                        ↓         │
│                  ┌───────────┐  │
│                  │  MariaDB  │  │
│                  └───────────┘  │
│                                  │
│  ┌───────────┐   ┌───────────┐ │
│  │  Backup   │   │  WP-CLI   │ │
│  └───────────┘   └───────────┘ │
└─────────────────────────────────┘
```

## 📦 What's Included

### Docker Services (7)
1. **mariadb** - Database server
2. **php-fpm** - PHP processor
3. **nginx** - Web server
4. **wp-cli** - WordPress CLI tools
5. **backup** - Automated backup
6. **adminer** - DB admin (optional)

### Scripts (7)
1. `generate-secrets.sh` - Generate passwords
2. `init-wordpress.sh` - Initialize WP
3. `backup-db.sh` - Database backup
4. `restore-backup.sh` - Restore backup
5. `healthcheck.sh` - Health monitoring
6. `update-wordpress.sh` - Update WP
7. `cleanup.sh` - Resource cleanup

### Documentation (10)
1. `README.md` - Main documentation
2. `QUICKSTART.md` - Quick start guide
3. `DEPLOY.md` - Deployment guide
4. `SECURITY.md` - Security checklist
5. `PROJECT_STRUCTURE.md` - Project overview
6. `INSTALLATION_CHECKLIST.md` - Installation tracker
7. `CHANGELOG.md` - Version history
8. `CONTRIBUTING.md` - Contribution guide
9. `LICENSE` - MIT License
10. `00-START-HERE.md` - This file

### Configuration Files (8)
1. `docker-compose.yml` - Main compose file
2. `nginx/conf.d/bpkad.conf` - Nginx config
3. `php/Dockerfile` - PHP-FPM image
4. `php/php.ini` - PHP config
5. `php/php-fpm.d/www.conf` - FPM pool config
6. `mariadb/my.cnf` - MariaDB config
7. `wordpress/wp-config.php.template` - WP config template
8. `Makefile` - Command shortcuts

## 🚀 Quick Installation (15 Minutes)

### Prerequisites
- Server Linux (4GB RAM)
- Docker & Docker Compose installed
- Port 80 available

### Steps

```bash
# 1. Navigate to project
cd /opt/bpkad-wordpress

# 2. Make scripts executable
chmod +x scripts/*.sh php/docker-entrypoint.sh

# 3. Generate secrets
./scripts/generate-secrets.sh
# ⚠️ SAVE THE PASSWORDS!

# 4. Build and start
docker compose build
docker compose up -d

# 5. Initialize WordPress
docker compose run --rm wp-cli /scripts/init-wordpress.sh
# ⚠️ SAVE THE ADMIN CREDENTIALS!

# 6. Verify
./scripts/healthcheck.sh
```

## 🎉 After Installation

### Access Points
- **Website**: http://bpkad.bengkaliskab.go.id
- **Local**: http://10.10.10.31
- **Admin**: http://bpkad.bengkaliskab.go.id/wp-admin/

### Important Next Steps
1. ✅ Login to WordPress admin
2. ✅ Change admin password
3. ✅ Configure Wordfence Security
4. ✅ Setup UpdraftPlus remote backup
5. ✅ Review SECURITY.md checklist
6. ✅ Add your content

## 🆘 Need Help?

### Common Issues

**Services won't start?**
```bash
docker compose logs
docker compose down
docker compose up -d
```

**Can't access website?**
```bash
curl http://localhost
docker compose ps
./scripts/healthcheck.sh
```

**Database error?**
```bash
docker compose logs mariadb
docker compose restart mariadb
```

### Documentation
- Installation issues → `DEPLOY.md`
- Configuration → `README.md`
- Security → `SECURITY.md`
- Project structure → `PROJECT_STRUCTURE.md`

### Contact
- Email: admin@bpkad.bengkaliskab.go.id

## 📋 Pre-Deployment Checklist

Before running installation, ensure:

- [ ] Docker installed and running
- [ ] Docker Compose installed
- [ ] Port 80 is available
- [ ] Domain DNS configured
- [ ] Cloudflare configured
- [ ] NPM configured
- [ ] Mikrotik NAT configured
- [ ] Server has internet access
- [ ] Server timezone set to Asia/Jakarta
- [ ] Firewall configured (allow port 80)

## 🎓 Learning Path

### For Beginners
1. Read `QUICKSTART.md` for overview
2. Read `DEPLOY.md` thoroughly
3. Follow `INSTALLATION_CHECKLIST.md`
4. Read `SECURITY.md` for hardening
5. Keep `README.md` handy for maintenance

### For Experienced Users
1. Skim `README.md` for overview
2. Review `docker-compose.yml`
3. Check configuration files
4. Run `make install`
5. Review `SECURITY.md` checklist

### For System Administrators
1. Review `PROJECT_STRUCTURE.md`
2. Study security configurations
3. Plan backup strategy
4. Setup monitoring
5. Create maintenance schedule

## 🔧 Tuning for Your Server

Default configuration is optimized for **4GB RAM**.

**If your server has different RAM**:

### 2GB RAM
Edit these files:
- `php/php-fpm.d/www.conf`: Set `pm.max_children = 25`
- `mariadb/my.cnf`: Set `innodb_buffer_pool_size = 256M`

### 8GB RAM
Edit these files:
- `php/php-fpm.d/www.conf`: Set `pm.max_children = 100`
- `mariadb/my.cnf`: Set `innodb_buffer_pool_size = 1G`

### 16GB RAM
Edit these files:
- `php/php-fpm.d/www.conf`: Set `pm.max_children = 200`
- `mariadb/my.cnf`: Set `innodb_buffer_pool_size = 2G`

After editing, rebuild:
```bash
docker compose down
docker compose build
docker compose up -d
```

## 🌟 Features Highlight

### Security
- ✅ Docker secrets for passwords
- ✅ Rate limiting (login, admin, general)
- ✅ Security headers (X-Frame-Options, CSP, etc.)
- ✅ XML-RPC disabled
- ✅ File editor disabled
- ✅ Dangerous PHP functions disabled
- ✅ Cloudflare real IP forwarding
- ✅ Fail2ban compatible

### Performance
- ✅ OPcache enabled (128MB)
- ✅ PHP-FPM optimized pools
- ✅ MariaDB query cache
- ✅ Static file caching (30 days)
- ✅ Gzip compression
- ✅ Keep-alive connections
- ✅ APCu object caching
- ✅ Redis support

### Backup & Recovery
- ✅ Automated daily backups
- ✅ 7-day retention
- ✅ Compressed backups (gzip)
- ✅ One-click restore
- ✅ Safety backup before restore
- ✅ Optional remote SFTP backup

### Monitoring
- ✅ Health checks for all services
- ✅ Resource limits
- ✅ Slow query logging
- ✅ PHP-FPM status page
- ✅ Nginx access/error logs
- ✅ Automated health monitoring script

## 💡 Tips

### Makefile Shortcuts
Instead of typing long `docker compose` commands, use `make`:

```bash
make install    # Full installation
make start      # docker compose up -d
make stop       # docker compose stop
make restart    # docker compose restart
make logs       # docker compose logs -f
make backup     # Manual backup
make health     # Health check
make update     # Update WordPress
```

### Regular Maintenance
Add to your calendar:
- **Daily**: Check backups completed
- **Weekly**: Review logs, run security scan
- **Monthly**: Update WordPress/plugins, optimize DB
- **Quarterly**: Full backup test, security audit

### Best Practices
1. Always backup before updates
2. Test updates in staging first (if available)
3. Monitor logs regularly
4. Keep strong passwords
5. Enable 2FA for admin accounts
6. Review security alerts promptly
7. Document all changes

## 📞 Support

### Self-Service
1. Check documentation first
2. Review logs: `docker compose logs`
3. Run health check: `./scripts/healthcheck.sh`
4. Search issues in project repo

### Contact
- **Email**: admin@bpkad.bengkaliskab.go.id
- **Emergency**: [Your emergency contact]

## 🎉 Ready to Deploy?

Follow these simple steps:

1. ✅ Read this file completely
2. ✅ Choose your documentation path (Quick or Detailed)
3. ✅ Check prerequisites
4. ✅ Follow installation steps
5. ✅ Run health check
6. ✅ Complete security checklist
7. ✅ Start using WordPress!

---

**Project Version**: 1.0.0  
**Last Updated**: November 2024  
**Maintained By**: BPKAD IT Team

**Good luck with your deployment! 🚀**

