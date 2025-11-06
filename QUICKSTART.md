# Quick Start Guide - BPKAD WordPress

Panduan singkat untuk setup WordPress dalam 15 menit.

## ⚡ Prerequisites

- Server Linux dengan 4GB RAM minimum
- Docker & Docker Compose terinstall
- Port 80 tersedia
- Koneksi internet

## 🚀 5 Langkah Deploy

### 1️⃣ Clone/Download Project

```bash
cd /opt
git clone <repo-url> bpkad-wordpress
# Atau extract dari zip/tar.gz
cd bpkad-wordpress
```

### 2️⃣ Generate Secrets

```bash
chmod +x scripts/*.sh
./scripts/generate-secrets.sh
```

**💾 SAVE THE PASSWORDS!** Simpan di tempat aman.

### 3️⃣ Build & Start

```bash
docker compose build
docker compose up -d
```

Tunggu ~2 menit sampai semua services healthy.

### 4️⃣ Initialize WordPress

```bash
docker compose run --rm wp-cli /scripts/init-wordpress.sh
```

**💾 SAVE THE ADMIN CREDENTIALS!**

### 5️⃣ Verify

```bash
./scripts/healthcheck.sh
```

## ✅ Access

- **Website**: http://bpkad.bengkaliskab.go.id
- **Local**: http://10.10.10.31
- **Admin**: http://bpkad.bengkaliskab.go.id/wp-admin/

## 🎯 Next Steps

1. Login ke WordPress admin
2. Change admin password
3. Configure Wordfence (Security → Wordfence)
4. Setup UpdraftPlus backup (Settings → UpdraftPlus)
5. Add content

## 🔧 Common Commands

```bash
# View logs
docker compose logs -f

# Restart services
docker compose restart

# Stop services
docker compose stop

# Manual backup
docker compose exec backup /backup-db.sh

# Update WordPress
docker compose run --rm wp-cli wp core update --allow-root
```

## 🆘 Troubleshooting

### Services won't start?
```bash
docker compose logs
docker compose down
docker compose up -d
```

### Can't access website?
```bash
curl http://localhost
docker compose ps nginx
```

### Database error?
```bash
docker compose restart mariadb
docker compose logs mariadb
```

## 📖 Full Documentation

- **Complete Guide**: [README.md](README.md)
- **Deployment**: [DEPLOY.md](DEPLOY.md)  
- **Security**: [SECURITY.md](SECURITY.md)

## 📞 Support

Email: admin@bpkad.bengkaliskab.go.id

---

**That's it! Your WordPress is ready! 🎉**

