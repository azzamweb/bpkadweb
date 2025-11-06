# Installation Checklist - BPKAD WordPress

Checklist lengkap untuk instalasi step-by-step. Centang setiap item setelah selesai.

## 📋 Pre-Installation (Server Setup)

### Server Requirements
- [ ] Server Linux (Ubuntu 20.04+ / Debian 11+ / CentOS 8+)
- [ ] CPU: 2+ cores
- [ ] RAM: 4GB minimum
- [ ] Storage: 50GB+ SSD
- [ ] Network: Static IP 10.10.10.31 configured
- [ ] Domain: bpkad.bengkaliskab.go.id pointing to infrastructure

### Software Installation
- [ ] Docker installed (version 20.10+)
  ```bash
  docker --version
  ```
- [ ] Docker Compose installed (version 2.0+)
  ```bash
  docker compose version
  ```
- [ ] Git installed
  ```bash
  git --version
  ```

### Network Configuration
- [ ] Cloudflare configured for domain
- [ ] NPM (Nginx Proxy Manager) configured: 103.13.206.172
- [ ] Mikrotik NAT configured: 103.13.206.172:8089 → 10.10.10.31:80
- [ ] Port 80 available on server
  ```bash
  sudo netstat -tulpn | grep :80
  ```

### Firewall Configuration
- [ ] Firewall enabled
- [ ] Port 22 (SSH) allowed
- [ ] Port 80 (HTTP) allowed
- [ ] fail2ban installed and configured
  ```bash
  sudo ufw status  # Ubuntu/Debian
  # atau
  sudo firewall-cmd --list-all  # CentOS/RHEL
  ```

### System Optimization
- [ ] Timezone set to Asia/Jakarta
  ```bash
  timedatectl
  ```
- [ ] System updated
  ```bash
  sudo apt update && sudo apt upgrade -y
  ```
- [ ] File limits increased (in /etc/sysctl.conf)
- [ ] Automatic security updates enabled

## 📦 Project Setup

### Get Project Files
- [ ] Project directory created: `/opt/bpkad-wordpress`
- [ ] Project files downloaded/cloned
- [ ] Ownership set to current user
  ```bash
  ls -la /opt/bpkad-wordpress
  ```

### File Permissions
- [ ] Scripts executable
  ```bash
  chmod +x /opt/bpkad-wordpress/scripts/*.sh
  ```
- [ ] PHP entrypoint executable
  ```bash
  chmod +x /opt/bpkad-wordpress/php/docker-entrypoint.sh
  ```

### Generate Secrets
- [ ] Secrets directory created
- [ ] Secrets generated
  ```bash
  ./scripts/generate-secrets.sh
  ```
- [ ] **IMPORTANT**: Passwords saved securely:
  - [ ] Database root password: `_______________`
  - [ ] Database user password: `_______________`
  - [ ] WordPress admin password: `_______________`
- [ ] Secrets directory permissions: 700
- [ ] Secret files permissions: 600
  ```bash
  ls -la secrets/
  ```

## 🏗️ Docker Build & Deploy

### Build Images
- [ ] Docker images built successfully
  ```bash
  docker compose build --no-cache
  ```
- [ ] No build errors in output
- [ ] Images visible in Docker
  ```bash
  docker images | grep bpkad
  ```

### Start Services
- [ ] Services started
  ```bash
  docker compose up -d
  ```
- [ ] All services running
  ```bash
  docker compose ps
  ```
- [ ] Services healthy (wait 2-3 minutes)
- [ ] No errors in logs
  ```bash
  docker compose logs
  ```

### Initialize WordPress
- [ ] WordPress initialization completed
  ```bash
  docker compose run --rm wp-cli /scripts/init-wordpress.sh
  ```
- [ ] **IMPORTANT**: WordPress credentials saved:
  - [ ] Admin URL: `http://bpkad.bengkaliskab.go.id/wp-admin/`
  - [ ] Admin username: `_______________`
  - [ ] Admin password: `_______________`
  - [ ] Admin email: `_______________`
- [ ] wp-config.php created
- [ ] Essential plugins installed and activated

## ✅ Verification

### Service Health
- [ ] Health check passed
  ```bash
  ./scripts/healthcheck.sh
  ```
- [ ] All services show ✓ (green checkmark)
- [ ] No failed services

### Website Access
- [ ] Website accessible from server
  ```bash
  curl -I http://localhost
  # Should return: HTTP/1.1 200 OK
  ```
- [ ] Website accessible via local IP
  ```bash
  curl -I http://10.10.10.31
  ```
- [ ] Website accessible via domain
  ```bash
  curl -I http://bpkad.bengkaliskab.go.id
  ```
- [ ] Admin page accessible
  - [ ] Open: `http://bpkad.bengkaliskab.go.id/wp-admin/`
  - [ ] Login successful
  - [ ] Dashboard loads

### Database Connectivity
- [ ] Database responsive
  ```bash
  docker compose exec mariadb mysqladmin ping
  ```
- [ ] WordPress connected to database
- [ ] No database errors in logs

### Backup System
- [ ] Backup container running
  ```bash
  docker compose ps backup
  ```
- [ ] Manual backup works
  ```bash
  docker compose exec backup /backup-db.sh
  ```
- [ ] Backup file created
  ```bash
  docker compose exec backup ls -lh /backups/
  ```

## 🔒 Security Configuration

### WordPress Admin
- [ ] Logged into WordPress admin
- [ ] Admin username changed (not "admin")
  ```bash
  # Create new admin, delete old admin
  docker compose run --rm wp-cli wp user create newadmin email@example.com --role=administrator --allow-root
  docker compose run --rm wp-cli wp user delete admin --yes --allow-root
  ```
- [ ] Strong password set
- [ ] Admin email verified

### Security Plugins
- [ ] **Wordfence** configured:
  - [ ] License key entered (if applicable)
  - [ ] Initial scan completed
  - [ ] Firewall enabled (Extended Protection)
  - [ ] Email alerts configured
  - [ ] Two-factor authentication enabled
  
- [ ] **Limit Login Attempts** configured:
  - [ ] Max attempts: 3
  - [ ] Lockout duration: 60 minutes
  - [ ] Email notifications enabled

- [ ] **UpdraftPlus Backup** configured:
  - [ ] Backup schedule set (Daily DB, Weekly Files)
  - [ ] Remote storage configured (Google Drive/Dropbox/SFTP)
  - [ ] Test backup performed
  - [ ] Test restore performed

### Additional Security
- [ ] XML-RPC disabled (verified blocked)
  ```bash
  curl -X POST http://10.10.10.31/xmlrpc.php
  # Should return: 403 Forbidden
  ```
- [ ] File editor disabled (in wp-config.php)
- [ ] Unused themes deleted
- [ ] Unused plugins deleted
- [ ] All plugins updated to latest
- [ ] All themes updated to latest

### Cloudflare Configuration
- [ ] SSL/TLS: Full or Full (Strict)
- [ ] Always Use HTTPS: On
- [ ] HSTS: Enabled
- [ ] Auto Minify: CSS, JS, HTML
- [ ] Page rules created for caching
- [ ] Firewall rules configured
- [ ] Bot protection enabled

## 📊 Monitoring Setup

### Log Monitoring
- [ ] Log rotation configured
  ```bash
  cat /etc/logrotate.d/docker-wordpress
  ```
- [ ] Can view logs without errors
  ```bash
  docker compose logs nginx
  docker compose logs php-fpm
  docker compose logs mariadb
  ```

### Health Monitoring
- [ ] Cron job for health check added
  ```bash
  crontab -l | grep healthcheck
  ```
- [ ] Health check runs successfully in cron

### Backup Monitoring
- [ ] Automatic backup cron verified
- [ ] Backup logs accessible
- [ ] Backup retention working (7 days)

## 📝 Documentation

### Credentials Saved
- [ ] All passwords saved in password manager
- [ ] Server access credentials documented
- [ ] Database credentials documented
- [ ] WordPress admin credentials documented
- [ ] Cloudflare credentials documented
- [ ] Emergency contact list created

### Runbook Created
- [ ] How to restart services documented
- [ ] How to restore backup documented
- [ ] How to update WordPress documented
- [ ] Troubleshooting guide reviewed
- [ ] Emergency procedures documented

### Team Training
- [ ] Team trained on WordPress admin
- [ ] Team trained on content creation
- [ ] Team trained on plugin updates
- [ ] Team trained on checking security alerts
- [ ] Team knows who to contact for issues

## 🎉 Final Steps

### Performance Testing
- [ ] Website loads quickly
- [ ] Admin dashboard responsive
- [ ] Images loading correctly
- [ ] Forms working (test contact form if any)

### Content Setup
- [ ] Theme selected and configured
- [ ] Basic pages created (About, Contact, etc.)
- [ ] Initial content added
- [ ] Media library organized

### Go Live Checklist
- [ ] All testing completed
- [ ] Backups verified
- [ ] Monitoring active
- [ ] Team trained
- [ ] Documentation complete
- [ ] Emergency contacts ready
- [ ] Maintenance schedule set

### Post-Launch
- [ ] Monitor for 24 hours
- [ ] Check error logs daily for first week
- [ ] Verify backups running
- [ ] Review security alerts
- [ ] User feedback collected

## 📅 Maintenance Schedule

### Daily
- [ ] Check backup completion
- [ ] Review critical security alerts
- [ ] Monitor uptime

### Weekly
- [ ] Review access logs
- [ ] Check for WordPress/plugin updates
- [ ] Run security scan (Wordfence)
- [ ] Verify backup restore (sample)

### Monthly
- [ ] Update WordPress core (if not auto-updated)
- [ ] Update all plugins and themes
- [ ] Review user accounts
- [ ] Optimize database
- [ ] Review and rotate logs
- [ ] Full security audit

### Quarterly
- [ ] Full system backup test
- [ ] Disaster recovery drill
- [ ] Penetration testing
- [ ] Review security policies
- [ ] Team security training

## ✍️ Sign-Off

**Installation Completed By**: _______________________  
**Date**: _______________________  
**Verified By**: _______________________  
**Date**: _______________________  

**Production Ready**: [ ] YES [ ] NO  
**Security Verified**: [ ] YES [ ] NO  
**Backups Tested**: [ ] YES [ ] NO  
**Team Trained**: [ ] YES [ ] NO  

---

**Notes / Issues During Installation**:

```
[Add any notes, issues encountered, or special configurations here]







```

---

**Next Review Date**: _______________________

**Congratulations! Your WordPress site is now live! 🎉**

