# Deployment Guide - BPKAD WordPress

Panduan step-by-step deployment dari awal hingga production-ready.

## 🎯 Prerequisites

Sebelum memulai, pastikan server sudah memenuhi requirements:

### Hardware
- **CPU**: 2 cores minimum (4 cores recommended)
- **RAM**: 4GB minimum (8GB recommended)
- **Storage**: 50GB SSD minimum
- **Network**: 100Mbps minimum

### Software
- **OS**: Ubuntu 20.04+ / Debian 11+ / CentOS 8+
- **Docker**: Version 20.10+
- **Docker Compose**: Version 2.0+
- **Git**: Latest version

### Network
- **IP Address**: 10.10.10.31 (static)
- **Domain**: bpkad.bengkaliskab.go.id
- **Cloudflare**: Already configured
- **NPM**: 103.13.206.172
- **Mikrotik NAT**: 103.13.206.172:8089 → 10.10.10.31:80

## 📦 Step 1: Prepare Server

### 1.1 Update System

```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git vim ufw fail2ban

# CentOS/RHEL
sudo yum update -y
sudo yum install -y curl wget git vim firewalld fail2ban
```

### 1.2 Configure Firewall

```bash
# Ubuntu/Debian (UFW)
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw enable
sudo ufw status

# CentOS/RHEL (Firewalld)
sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
```

### 1.3 Install Docker

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Enable Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Verify installation
docker --version
```

### 1.4 Install Docker Compose

```bash
# Download Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make executable
sudo chmod +x /usr/local/bin/docker-compose

# Create symlink (optional)
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Verify installation
docker-compose --version
```

### 1.5 Configure System Resources

```bash
# Increase file limits
sudo tee -a /etc/sysctl.conf <<EOF
fs.file-max = 65535
net.core.somaxconn = 1024
net.ipv4.tcp_max_syn_backlog = 2048
vm.overcommit_memory = 1
EOF

sudo sysctl -p

# Set ulimit
echo "* soft nofile 65535" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65535" | sudo tee -a /etc/security/limits.conf
```

## 🚀 Step 2: Deploy Application

### 2.1 Get Application Code

```bash
# Create directory
sudo mkdir -p /opt/bpkad-wordpress
sudo chown $USER:$USER /opt/bpkad-wordpress
cd /opt/bpkad-wordpress

# Option 1: Clone from Git
git clone <repository-url> .

# Option 2: Upload via SCP/SFTP
# From your local machine:
# scp -r bpkad-wordpress/ user@10.10.10.31:/opt/

# Option 3: Download from archive
# wget <archive-url> -O bpkad-wordpress.tar.gz
# tar -xzf bpkad-wordpress.tar.gz
```

### 2.2 Set Permissions

```bash
cd /opt/bpkad-wordpress

# Set ownership
sudo chown -R $USER:$USER .

# Set script permissions
chmod +x scripts/*.sh

# Create secrets directory
mkdir -p secrets
chmod 700 secrets
```

### 2.3 Generate Secrets

```bash
# Generate all secrets
./scripts/generate-secrets.sh

# Save the generated passwords!
# Copy them to a secure location (password manager)
```

**⚠️ IMPORTANT**: Save these credentials securely:
- Database root password
- Database user password
- WordPress admin password

### 2.4 Configure Environment (Optional)

```bash
# Copy env.example if you need custom configuration
cp env.example .env

# Edit if needed (default values are already good)
vim .env
```

## 🏗️ Step 3: Build and Start Services

### 3.1 Build Docker Images

```bash
# Build all images
docker compose build --no-cache

# Verify images
docker images | grep bpkad
```

### 3.2 Start Services

```bash
# Start all services in background
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f
```

Wait until all services are healthy (usually 1-2 minutes).

### 3.3 Initialize WordPress

```bash
# Run WordPress initialization
docker compose run --rm wp-cli /scripts/init-wordpress.sh

# This will:
# - Create wp-config.php
# - Install WordPress
# - Set Indonesian language
# - Configure security settings
# - Install essential plugins
# - Set up permalink structure
```

Save the WordPress admin credentials shown at the end!

## ✅ Step 4: Verify Deployment

### 4.1 Run Health Check

```bash
./scripts/healthcheck.sh
```

Expected output: All services should show ✓ (healthy).

### 4.2 Test Website Access

```bash
# Test from server
curl -I http://localhost
curl -I http://10.10.10.31

# Expected: HTTP/1.1 200 OK
```

### 4.3 Test from External Network

From your workstation:
```bash
# Test local IP (if in same network)
curl -I http://10.10.10.31

# Test domain (via Cloudflare → NPM → Mikrotik → Server)
curl -I http://bpkad.bengkaliskab.go.id
```

### 4.4 Verify WordPress Admin

1. Open browser: http://bpkad.bengkaliskab.go.id/wp-admin/
2. Login with credentials from initialization step
3. Verify you can access dashboard

### 4.5 Check Installed Plugins

```bash
docker compose run --rm wp-cli wp plugin list --allow-root
```

Should show:
- ✅ Wordfence Security (active)
- ✅ Limit Login Attempts Reloaded (active)
- ✅ UpdraftPlus Backup (active)
- ✅ WP Super Cache (active)
- ✅ Autoptimize (active)

## 🔒 Step 5: Security Hardening

### 5.1 Change Admin Username

```bash
# Create new admin user
docker compose run --rm wp-cli wp user create bpkadadmin admin@bpkad.bengkaliskab.go.id \
  --role=administrator --user_pass='YOUR_STRONG_PASSWORD' --allow-root

# Delete default admin
docker compose run --rm wp-cli wp user delete admin --yes --allow-root
```

### 5.2 Configure Security Plugins

#### Wordfence Setup
1. Go to: Wordfence → Dashboard
2. Enter license key (free or premium)
3. Go to: Wordfence → Firewall → Manage Firewall
4. Click: "Optimize Firewall"
5. Enable "Extended Protection"
6. Run initial scan: Tools → Wordfence → Start New Scan

#### Limit Login Attempts
1. Go to: Settings → Limit Login Attempts
2. Configure:
   - Max attempts: 3
   - Lockout duration: 60 minutes
   - Long lockout: 24 hours
3. Enable email notifications

#### UpdraftPlus Backup
1. Go to: Settings → UpdraftPlus Backups
2. Click: Settings tab
3. Configure:
   - Files backup: Weekly
   - Database backup: Daily
   - Retain: 7 backups
4. Choose remote storage (recommended):
   - Google Drive / Dropbox / SFTP
5. Test backup: Backup / Restore tab → Backup Now

### 5.3 Configure Cloudflare

Access Cloudflare dashboard for bpkad.bengkaliskab.go.id:

#### SSL/TLS Settings
1. SSL/TLS → Overview → Full (recommended) or Full (strict)
2. SSL/TLS → Edge Certificates:
   - ✅ Always Use HTTPS: On
   - ✅ HTTP Strict Transport Security (HSTS): Enable
   - ✅ Minimum TLS Version: 1.2
   - ✅ Automatic HTTPS Rewrites: On

#### Firewall Settings
1. Security → WAF → Create firewall rule:
   - Name: "Block xmlrpc"
   - Expression: `(http.request.uri.path contains "xmlrpc.php")`
   - Action: Block

2. Create another rule:
   - Name: "Rate limit wp-login"
   - Expression: `(http.request.uri.path contains "wp-login.php")`
   - Action: Challenge

#### Speed Settings
1. Speed → Optimization:
   - ✅ Auto Minify: CSS, JavaScript, HTML
   - ✅ Brotli: On

2. Caching → Configuration:
   - Caching Level: Standard
   - Browser Cache TTL: 4 hours
   - Create Page Rule:
     - URL: `bpkad.bengkaliskab.go.id/wp-content/*`
     - Settings: Cache Level = Cache Everything

## 🔄 Step 6: Setup Monitoring & Backup

### 6.1 Verify Backup Cron

```bash
# Check backup container is running
docker compose ps backup

# Trigger manual backup to test
docker compose exec backup /backup-db.sh

# Verify backup was created
docker compose exec backup ls -lh /backups/
```

### 6.2 Setup System Monitoring (Optional)

```bash
# Install monitoring tools
sudo apt install htop iotop nethogs -y

# Check resources
htop
docker stats
```

### 6.3 Setup Log Rotation

```bash
# Create logrotate config
sudo tee /etc/logrotate.d/docker-wordpress <<EOF
/var/lib/docker/volumes/bpkad_nginx_logs/_data/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 root root
    sharedscripts
    postrotate
        docker compose -f /opt/bpkad-wordpress/docker-compose.yml exec nginx nginx -s reopen
    endscript
}
EOF
```

### 6.4 Setup Cron for Health Checks

```bash
# Add to crontab
crontab -e

# Add these lines:
# Health check every 5 minutes
*/5 * * * * /opt/bpkad-wordpress/scripts/healthcheck.sh >> /var/log/bpkad-health.log 2>&1

# Weekly database optimization
0 3 * * 0 cd /opt/bpkad-wordpress && docker compose run --rm wp-cli wp db optimize --allow-root

# Monthly WordPress updates (optional - be careful with auto-updates)
# 0 4 1 * * cd /opt/bpkad-wordpress && docker compose run --rm wp-cli wp core update --allow-root
```

## 📝 Step 7: Documentation & Handover

### 7.1 Document Credentials

Create a secure document with:
- ✅ Server IP and access credentials
- ✅ Database passwords (from secrets/)
- ✅ WordPress admin credentials
- ✅ Cloudflare account details
- ✅ NPM credentials
- ✅ Mikrotik access details
- ✅ Emergency contacts

Store in password manager (e.g., Bitwarden, 1Password, KeePass).

### 7.2 Create Runbook

Document common operations:
- How to restart services
- How to restore from backup
- How to update WordPress
- How to view logs
- Emergency contacts

### 7.3 Team Training

Train the team on:
- Basic WordPress administration
- How to create content
- How to update plugins (safely)
- How to check security alerts
- Who to contact for issues

## 🎉 Deployment Complete!

### Access Points

- **Website**: http://bpkad.bengkaliskab.go.id
- **Local IP**: http://10.10.10.31
- **Admin**: http://bpkad.bengkaliskab.go.id/wp-admin/
- **Adminer** (if enabled): http://10.10.10.31:8080

### Next Steps

1. ✅ Change admin password after first login
2. ✅ Complete Wordfence setup and run first scan
3. ✅ Configure UpdraftPlus remote backup
4. ✅ Add actual content to website
5. ✅ Configure theme and customize design
6. ✅ Add SSL certificate (via Cloudflare)
7. ✅ Test all functionality
8. ✅ Announce to users

### Regular Maintenance

- **Daily**: Check backups, review security alerts
- **Weekly**: Check for updates, review logs
- **Monthly**: Update WordPress/plugins, optimize database
- **Quarterly**: Security audit, disaster recovery test

## 🆘 Troubleshooting

### Services won't start
```bash
# Check logs
docker compose logs

# Check disk space
df -h

# Restart Docker
sudo systemctl restart docker
docker compose up -d
```

### Can't access website
```bash
# Check if Nginx is running
docker compose ps nginx

# Check Nginx logs
docker compose logs nginx

# Test from server
curl -I http://localhost
```

### Database connection errors
```bash
# Check MariaDB status
docker compose ps mariadb
docker compose logs mariadb

# Restart MariaDB
docker compose restart mariadb
```

## 📞 Support

For issues during deployment:
- Check logs: `docker compose logs`
- Run health check: `./scripts/healthcheck.sh`
- Review documentation: `README.md` and `SECURITY.md`
- Contact: admin@bpkad.bengkaliskab.go.id

---

**Deployment Date**: _________________  
**Deployed By**: _________________  
**Verified By**: _________________

