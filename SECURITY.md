# Security Checklist - BPKAD WordPress

Panduan keamanan lengkap untuk WordPress deployment dalam standar website pemerintahan.

## 🔒 Security Layers

```
┌─────────────────────────────────────┐
│  Layer 1: Cloudflare (SSL/DDoS)    │
├─────────────────────────────────────┤
│  Layer 2: NPM + Mikrotik (NAT)     │
├─────────────────────────────────────┤
│  Layer 3: Nginx (WAF/Rate Limit)   │
├─────────────────────────────────────┤
│  Layer 4: WordPress (App Security) │
├─────────────────────────────────────┤
│  Layer 5: PHP-FPM (Execution)      │
├─────────────────────────────────────┤
│  Layer 6: MariaDB (Data Security)  │
├─────────────────────────────────────┤
│  Layer 7: Docker (Isolation)       │
└─────────────────────────────────────┘
```

## ✅ Pre-Deployment Checklist

### 1. Server Hardening (OS Level)

- [ ] **Update sistem operasi**
  ```bash
  sudo apt update && sudo apt upgrade -y
  # atau untuk CentOS/RHEL
  sudo yum update -y
  ```

- [ ] **Configure firewall**
  ```bash
  # UFW (Ubuntu/Debian)
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw allow 22/tcp    # SSH
  sudo ufw allow 80/tcp    # HTTP
  sudo ufw allow 443/tcp   # HTTPS (if needed)
  sudo ufw enable
  
  # Firewalld (CentOS/RHEL)
  sudo firewall-cmd --permanent --add-service=ssh
  sudo firewall-cmd --permanent --add-service=http
  sudo firewall-cmd --permanent --add-service=https
  sudo firewall-cmd --reload
  ```

- [ ] **Secure SSH access**
  ```bash
  # Edit /etc/ssh/sshd_config
  PermitRootLogin no
  PasswordAuthentication no
  PubkeyAuthentication yes
  Port 2222  # Change default port
  
  sudo systemctl restart sshd
  ```

- [ ] **Install fail2ban**
  ```bash
  sudo apt install fail2ban -y
  sudo systemctl enable fail2ban
  sudo systemctl start fail2ban
  ```

- [ ] **Set timezone**
  ```bash
  sudo timedatectl set-timezone Asia/Jakarta
  ```

- [ ] **Enable automatic security updates**
  ```bash
  # Ubuntu/Debian
  sudo apt install unattended-upgrades -y
  sudo dpkg-reconfigure -plow unattended-upgrades
  ```

### 2. Docker Security

- [ ] **Run Docker as non-root user**
  ```bash
  sudo usermod -aG docker $USER
  newgrp docker
  ```

- [ ] **Enable Docker content trust**
  ```bash
  export DOCKER_CONTENT_TRUST=1
  # Add to ~/.bashrc or ~/.zshrc
  ```

- [ ] **Set resource limits** (already in docker-compose.yml)

- [ ] **Enable Docker security scanning**
  ```bash
  docker scan php-fpm:latest
  ```

- [ ] **Secure Docker daemon**
  ```bash
  # Edit /etc/docker/daemon.json
  {
    "live-restore": true,
    "userland-proxy": false,
    "no-new-privileges": true
  }
  sudo systemctl restart docker
  ```

### 3. Application Security

- [ ] **Generate strong secrets**
  ```bash
  ./scripts/generate-secrets.sh
  ```

- [ ] **Verify file permissions**
  ```bash
  chmod 700 secrets/
  chmod 600 secrets/*
  chmod +x scripts/*.sh
  ```

- [ ] **Set proper ownership**
  ```bash
  sudo chown -R $USER:$USER .
  ```

- [ ] **Review nginx configuration**
  - Rate limiting enabled
  - Security headers configured
  - Sensitive files blocked
  - XML-RPC disabled

- [ ] **Review PHP configuration**
  - Dangerous functions disabled
  - expose_php = Off
  - allow_url_include = Off
  - File upload limits set

## 🛡️ Post-Deployment Security

### 1. WordPress Admin Security

- [ ] **Change default admin username**
  ```bash
  docker compose run --rm wp-cli wp user create newadmin admin@bpkad.bengkaliskab.go.id \
    --role=administrator --allow-root
  docker compose run --rm wp-cli wp user delete admin --yes --allow-root
  ```

- [ ] **Set strong admin password**
  ```bash
  docker compose run --rm wp-cli wp user update USERNAME \
    --user_pass="STRONG_PASSWORD" --allow-root
  ```

- [ ] **Disable file editing** (sudah diset via wp-config.php)
  - Verify: `define('DISALLOW_FILE_EDIT', true);`

- [ ] **Remove unused themes & plugins**
  ```bash
  docker compose run --rm wp-cli wp theme delete twentytwenty twentytwentyone --allow-root
  docker compose run --rm wp-cli wp plugin delete hello --allow-root
  ```

- [ ] **Set proper user roles**
  ```bash
  # Review all users
  docker compose run --rm wp-cli wp user list --allow-root
  
  # Remove unnecessary administrators
  docker compose run --rm wp-cli wp user delete USER_ID --yes --allow-root
  ```

### 2. WordPress Configuration

- [ ] **Disable XML-RPC** (sudah diblok via Nginx)
  - Verify: `curl -X POST http://10.10.10.31/xmlrpc.php`
  - Should return 403 Forbidden

- [ ] **Disable user enumeration**
  ```bash
  # Add to wp-config.php or install plugin
  docker compose run --rm wp-cli wp plugin install stop-user-enumeration --activate --allow-root
  ```

- [ ] **Limit login attempts** (plugin sudah terinstall via init script)
  - Configure di: Settings → Limit Login Attempts

- [ ] **Enable 2FA authentication**
  ```bash
  docker compose run --rm wp-cli wp plugin install two-factor --activate --allow-root
  # Configure di: Users → Your Profile → Two-Factor Options
  ```

- [ ] **Hide WordPress version**
  - Already configured via PHP disable functions

- [ ] **Disable directory browsing** (sudah diset via Nginx)

### 3. Security Plugins Configuration

#### Wordfence Security

- [ ] **Run initial scan**
  - Tools → Wordfence → Scan

- [ ] **Configure firewall**
  - Wordfence → Firewall → Manage Firewall
  - Set to "Extended Protection"

- [ ] **Enable real-time IP blocklist**
  - Wordfence → Firewall → Brute Force Protection
  - Enable all protection options

- [ ] **Configure email alerts**
  - Wordfence → All Options → Email Alerts
  - Set admin email for critical alerts

- [ ] **Enable two-factor authentication**
  - Wordfence → Login Security

#### Limit Login Attempts Reloaded

- [ ] **Configure lockout settings**
  - Settings → Limit Login Attempts
  - Max attempts: 3
  - Lockout duration: 60 minutes
  - Long lockout: 24 hours after 3 lockouts

- [ ] **Enable email notifications**

#### UpdraftPlus Backup

- [ ] **Configure backup schedule**
  - Settings → UpdraftPlus Backups
  - Database: Daily
  - Files: Weekly
  - Retention: 7 days

- [ ] **Set remote backup destination**
  - Google Drive / Dropbox / SFTP
  - Configure credentials

- [ ] **Test restore**
  - Run a test restore to verify backups work

### 4. Database Security

- [ ] **Secure database credentials** (sudah menggunakan Docker secrets)

- [ ] **Change database table prefix**
  ```bash
  # If not using default 'wp_'
  docker compose run --rm wp-cli wp db prefix wp123_ --allow-root
  ```

- [ ] **Disable remote database access**
  - Sudah configured: bind-address = 0.0.0.0 (hanya di Docker network)

- [ ] **Regular database optimization**
  ```bash
  # Setup cron job
  0 3 * * 0 docker compose run --rm wp-cli wp db optimize --allow-root
  ```

- [ ] **Enable binary logging** (sudah enabled di my.cnf)
  - Untuk point-in-time recovery

### 5. File System Security

- [ ] **Set WordPress file permissions**
  ```bash
  docker compose exec php-fpm find /var/www/html -type d -exec chmod 755 {} \;
  docker compose exec php-fpm find /var/www/html -type f -exec chmod 644 {} \;
  docker compose exec php-fpm chmod 600 /var/www/html/wp-config.php
  ```

- [ ] **Protect wp-config.php**
  - Already protected via Nginx configuration

- [ ] **Prevent PHP execution in uploads**
  - Already configured via Nginx

- [ ] **Regular malware scanning**
  ```bash
  # Via Wordfence
  docker compose run --rm wp-cli wp wordfence scan --allow-root
  ```

### 6. Network Security

- [ ] **Configure Cloudflare**
  - [ ] Enable SSL/TLS (Full or Strict)
  - [ ] Enable DDoS protection
  - [ ] Configure firewall rules
  - [ ] Enable bot protection
  - [ ] Set up page rules for caching
  - [ ] Enable security level to High

- [ ] **Configure NPM (Nginx Proxy Manager)**
  - [ ] Set up SSL certificates
  - [ ] Configure rate limiting
  - [ ] Enable block common exploits
  - [ ] Set up access lists if needed

- [ ] **Configure Mikrotik NAT**
  - [ ] Port forwarding: 8089 → 10.10.10.31:80
  - [ ] Enable firewall rules
  - [ ] Set connection limits
  - [ ] Enable connection tracking

- [ ] **Monitor failed login attempts**
  ```bash
  docker compose logs nginx | grep "wp-login"
  ```

## 🔍 Security Monitoring

### 1. Log Monitoring

- [ ] **Set up log rotation**
  ```bash
  # Create /etc/logrotate.d/docker-wordpress
  /var/lib/docker/volumes/bpkad_nginx_logs/_data/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 root root
    sharedscripts
  }
  ```

- [ ] **Monitor access logs**
  ```bash
  docker compose logs -f nginx | grep -E "403|404|500"
  ```

- [ ] **Monitor PHP errors**
  ```bash
  docker compose logs -f php-fpm | grep -i error
  ```

- [ ] **Monitor database slow queries**
  ```bash
  docker compose exec mariadb tail -f /var/lib/mysql/slow-query.log
  ```

### 2. Intrusion Detection

- [ ] **Install AIDE (Advanced Intrusion Detection)**
  ```bash
  sudo apt install aide -y
  sudo aideinit
  sudo cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db
  
  # Daily check via cron
  0 5 * * * /usr/bin/aide --check
  ```

- [ ] **Monitor WordPress file changes**
  ```bash
  # Via Wordfence
  # Tools → Wordfence → Scan → Monitor file changes
  ```

- [ ] **Set up alerts for suspicious activity**
  - Configure Wordfence email alerts
  - Set up fail2ban email notifications

### 3. Regular Security Audits

- [ ] **Weekly security scan**
  ```bash
  # Wordfence scan
  docker compose run --rm wp-cli wp wordfence scan --allow-root
  
  # Check for outdated software
  docker compose run --rm wp-cli wp core check-update --allow-root
  docker compose run --rm wp-cli wp plugin list --update=available --allow-root
  docker compose run --rm wp-cli wp theme list --update=available --allow-root
  ```

- [ ] **Monthly vulnerability check**
  ```bash
  # Check WordPress vulnerability database
  docker compose run --rm wp-cli wp plugin list --allow-root
  # Cross-reference with: https://wpscan.com/
  ```

- [ ] **Quarterly penetration testing**
  - Use tools: WPScan, Nikto, OWASP ZAP
  - Or hire professional security auditor

## 🚨 Incident Response Plan

### 1. If Site is Compromised

1. **Immediate Actions**
   ```bash
   # Take site offline
   docker compose stop nginx
   
   # Create forensic backup
   docker compose exec php-fpm tar czf /tmp/compromised-site.tar.gz /var/www/html
   docker compose cp php-fpm:/tmp/compromised-site.tar.gz ./
   
   # Backup database
   ./scripts/backup-db.sh
   ```

2. **Investigation**
   ```bash
   # Check access logs
   docker compose logs nginx > nginx-logs.txt
   
   # Scan for malware
   docker compose run --rm wp-cli wp wordfence scan --allow-root
   
   # Check file modifications
   docker compose exec php-fpm find /var/www/html -type f -mtime -7
   ```

3. **Cleanup**
   ```bash
   # Restore from clean backup
   ./scripts/restore-backup.sh <backup_file>
   
   # Reset all passwords
   ./scripts/generate-secrets.sh
   
   # Update WordPress core, plugins, themes
   docker compose run --rm wp-cli wp core update --allow-root
   docker compose run --rm wp-cli wp plugin update --all --allow-root
   docker compose run --rm wp-cli wp theme update --all --allow-root
   ```

4. **Bring site back online**
   ```bash
   docker compose up -d
   ./scripts/healthcheck.sh
   ```

### 2. If Database is Compromised

1. **Immediate Actions**
   ```bash
   # Stop database access
   docker compose stop mariadb
   
   # Backup current state
   docker compose start mariadb
   ./scripts/backup-db.sh
   docker compose stop mariadb
   ```

2. **Recovery**
   ```bash
   # Restore from clean backup
   ./scripts/restore-backup.sh <clean_backup>
   
   # Change database passwords
   ./scripts/generate-secrets.sh
   
   # Restart services
   docker compose up -d
   ```

### 3. DDoS Attack Response

1. **Enable Cloudflare Under Attack Mode**
   - Cloudflare Dashboard → Under Attack Mode → On

2. **Increase rate limiting**
   ```bash
   # Edit nginx/conf.d/bpkad.conf
   # Reduce rate limits temporarily
   limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;
   
   docker compose restart nginx
   ```

3. **Monitor attack patterns**
   ```bash
   docker compose logs nginx | grep -E "limit_req|limiting"
   ```

## 📋 Security Compliance (Pemerintah)

### Standar Keamanan Website Pemerintah (BSSN)

- [ ] **Enkripsi data in-transit** (HTTPS via Cloudflare)
- [ ] **Enkripsi data at-rest** (Docker volumes)
- [ ] **Strong authentication** (2FA enabled)
- [ ] **Access control** (Role-based access)
- [ ] **Audit logging** (All logs retained)
- [ ] **Regular backups** (Daily automated)
- [ ] **Patch management** (Update schedule)
- [ ] **Security monitoring** (24/7 via Wordfence)
- [ ] **Incident response plan** (Documented above)
- [ ] **Security awareness training** (Team training)

### GDPR / Privacy Compliance

- [ ] **Privacy policy page**
- [ ] **Cookie consent**
- [ ] **Data retention policy**
- [ ] **User data export capability**
- [ ] **Right to deletion implementation**

## 🔄 Regular Maintenance Schedule

### Daily
- [ ] Check backup completion
- [ ] Review critical security alerts
- [ ] Monitor resource usage

### Weekly
- [ ] Review access logs for anomalies
- [ ] Check for WordPress/plugin updates
- [ ] Run security scan (Wordfence)
- [ ] Test backup restore (monthly sample)

### Monthly
- [ ] Update WordPress core (if not auto-updated)
- [ ] Update all plugins and themes
- [ ] Review user accounts and permissions
- [ ] Optimize database
- [ ] Review and rotate logs
- [ ] Security audit

### Quarterly
- [ ] Full system backup test
- [ ] Disaster recovery drill
- [ ] Penetration testing
- [ ] Review and update security policies
- [ ] Security training for team

### Annually
- [ ] Comprehensive security audit
- [ ] Review compliance with regulations
- [ ] Update incident response plan
- [ ] External security assessment

## 📞 Emergency Contacts

### Internal
- **IT Admin**: [Your Phone]
- **Security Team**: [Your Email]
- **Backup Admin**: [Backup Contact]

### External
- **Hosting Provider**: [Provider Contact]
- **Domain Registrar**: [Registrar Contact]
- **Security Consultant**: [Consultant Contact]

### Government
- **BSSN (Badan Siber dan Sandi Negara)**: csirt@bssn.go.id
- **ID-SIRTII**: sirtii@bssn.go.id
- **Kominfo**: [Local Kominfo Contact]

## 🔗 Security Resources

- **OWASP Top 10**: https://owasp.org/www-project-top-ten/
- **WordPress Security**: https://wordpress.org/support/article/hardening-wordpress/
- **BSSN Guidelines**: https://bssn.go.id/
- **WPScan Vulnerability Database**: https://wpscan.com/
- **Docker Security**: https://docs.docker.com/engine/security/

---

**Last Updated**: November 2024  
**Security Officer**: BPKAD IT Team  
**Review Cycle**: Quarterly

⚠️ **This is a living document. Update regularly based on new threats and requirements.**

