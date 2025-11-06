# Changelog

All notable changes to BPKAD WordPress Docker project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-11-06

### Added
- Initial release of BPKAD WordPress Docker project
- Docker Compose configuration with multi-service architecture
- MariaDB 11.2 with performance optimization for 4GB RAM servers
- PHP-FPM 8.3 with OPcache, APCu, and Redis support
- Nginx 1.25 with security headers and rate limiting
- WordPress latest stable version with Indonesian language
- Automated database backup with 7-day rotation
- Health check scripts for all services
- Docker secrets for secure password management
- Multi-domain support (bpkad.bengkaliskab.go.id and 10.10.10.31)
- Cloudflare integration with real IP forwarding
- Security hardening:
  - XML-RPC disabled
  - File editor disabled
  - Rate limiting on wp-login and wp-admin
  - Security headers (X-Frame-Options, CSP, etc.)
  - Dangerous PHP functions disabled
  - Proper file permissions
- Essential WordPress plugins:
  - Wordfence Security
  - Limit Login Attempts Reloaded
  - UpdraftPlus Backup
  - WP Super Cache
  - Autoptimize
- Comprehensive documentation:
  - README.md with installation and maintenance guides
  - SECURITY.md with security checklist
  - DEPLOY.md with step-by-step deployment guide
- Utility scripts:
  - generate-secrets.sh - Generate secure passwords and salts
  - init-wordpress.sh - WordPress initialization
  - backup-db.sh - Database backup with rotation
  - restore-backup.sh - Database restore
  - healthcheck.sh - Service health monitoring
- Makefile for common operations
- Resource limits and tuning formulas for different RAM sizes

### Configuration
- PHP 8.3 with optimized settings:
  - OPcache: 128MB
  - Memory limit: 256MB
  - Upload max: 64MB
  - Realpath cache: 4096KB
- PHP-FPM pool for 4GB RAM:
  - pm.max_children: 50
  - pm.start_servers: 10
  - pm.min_spare_servers: 5
  - pm.max_spare_servers: 15
- MariaDB optimized for 4GB RAM:
  - innodb_buffer_pool_size: 512MB
  - max_connections: 151
- Nginx rate limiting:
  - wp-login: 5 requests/minute
  - wp-admin: 10 requests/second
  - general: 50 requests/second

### Security
- All passwords managed via Docker secrets
- File permissions properly set (755 for dirs, 644 for files)
- Cloudflare IP ranges configured for real IP detection
- SQL injection and XSS protection via Nginx
- Brute force protection via rate limiting
- Automatic security updates for WordPress core (minor versions)

### Documentation
- Comprehensive README with:
  - Installation guide
  - Configuration examples
  - Maintenance procedures
  - Troubleshooting guide
  - Performance optimization tips
- Security checklist covering:
  - Pre-deployment hardening
  - Post-deployment configuration
  - Monitoring and auditing
  - Incident response plan
  - Compliance requirements (BSSN standards)
- Deployment guide with:
  - Step-by-step instructions
  - Verification procedures
  - Security hardening steps
  - Monitoring setup

### Performance
- OPcache enabled with 10,000 max accelerated files
- FastCGI caching configuration (optional)
- Static file caching (30 days)
- Gzip/Brotli compression
- Database query cache optimization
- Connection pooling and keep-alive

### Backup
- Automated daily database backups at 02:00 WIB
- 7-day backup retention
- Compression with gzip
- Optional remote SFTP backup support
- One-click restore with safety backup

### Monitoring
- Health checks for all services
- Slow query logging
- PHP-FPM status page
- Nginx access and error logs
- MariaDB error and slow query logs
- Docker resource monitoring

## [Unreleased]

### Planned
- Redis integration for object caching
- Elasticsearch for better search
- CDN integration guide
- Multi-site support
- Staging environment setup
- CI/CD pipeline examples
- Prometheus + Grafana monitoring
- Automated testing suite
- WordPress CLI automation scripts

---

## Version History

- **1.0.0** (2024-11-06): Initial production release

