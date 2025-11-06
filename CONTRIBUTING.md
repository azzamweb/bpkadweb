# Contributing to BPKAD WordPress Docker

Terima kasih atas minat Anda untuk berkontribusi pada project ini!

## 🤝 Cara Berkontribusi

### Melaporkan Bug

Jika Anda menemukan bug, silakan buat issue dengan informasi berikut:

1. **Deskripsi bug** - Jelaskan apa yang terjadi
2. **Langkah reproduksi** - Cara untuk reproduce bug
3. **Expected behavior** - Apa yang seharusnya terjadi
4. **Screenshots** - Jika applicable
5. **Environment**:
   - OS dan versi
   - Docker version
   - Docker Compose version
   - Browser (jika web-related)

### Mengusulkan Fitur Baru

Sebelum mengusulkan fitur baru:

1. Cek issue yang sudah ada untuk memastikan belum ada yang mengusulkan
2. Buat issue baru dengan label "enhancement"
3. Jelaskan:
   - Use case
   - Benefit untuk user
   - Possible implementation approach

### Pull Request Process

1. **Fork** repository ini
2. **Create branch** dari `main`:
   ```bash
   git checkout -b feature/nama-fitur
   # atau
   git checkout -b fix/nama-bug
   ```
3. **Commit** changes dengan message yang jelas:
   ```bash
   git commit -m "Add: Deskripsi fitur"
   git commit -m "Fix: Deskripsi perbaikan"
   ```
4. **Push** ke branch Anda:
   ```bash
   git push origin feature/nama-fitur
   ```
5. **Create Pull Request** ke `main` branch

### Commit Message Guidelines

Gunakan format berikut:

- `Add: ` untuk fitur baru
- `Fix: ` untuk bug fixes
- `Update: ` untuk update existing features
- `Docs: ` untuk documentation changes
- `Refactor: ` untuk code refactoring
- `Test: ` untuk testing
- `Security: ` untuk security improvements
- `Performance: ` untuk performance improvements

Contoh:
```
Add: Redis object caching support
Fix: Database connection timeout issue
Update: PHP-FPM pool configuration for 8GB RAM
Docs: Add troubleshooting guide for backup restore
Security: Enable stricter CSP headers
```

## 📝 Coding Standards

### Docker

- Gunakan official images jika memungkinkan
- Pin specific versions (tidak menggunakan `latest`)
- Include health checks untuk semua services
- Set resource limits
- Use multi-stage builds untuk minimize image size

### Configuration Files

- Include comments untuk bagian penting
- Use meaningful variable names
- Follow existing formatting style
- Include default values yang reasonable

### Scripts

- Bash scripts harus:
  - Include shebang (`#!/bin/bash`)
  - Use `set -e` untuk exit on error
  - Include comments
  - Use functions untuk code reusability
  - Handle errors gracefully
  - Provide user feedback (colors, progress)

### Documentation

- Update README.md jika menambah fitur
- Update SECURITY.md jika ada security changes
- Include inline comments untuk complex code
- Update CHANGELOG.md

## 🧪 Testing

Sebelum submit PR, pastikan:

- [ ] Docker images build successfully
- [ ] All services start without errors
- [ ] Health checks pass
- [ ] WordPress installation works
- [ ] Backup and restore work correctly
- [ ] No security vulnerabilities introduced
- [ ] Documentation updated

Test commands:
```bash
# Build
docker compose build

# Start services
docker compose up -d

# Run health check
./scripts/healthcheck.sh

# Test backup
docker compose exec backup /backup-db.sh

# Check logs for errors
docker compose logs
```

## 📋 Checklist untuk PR

- [ ] Code follows project conventions
- [ ] Changes are tested locally
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] No secrets or sensitive data in code
- [ ] Commit messages are clear and descriptive
- [ ] PR description explains changes

## 🔒 Security

**JANGAN** commit:
- Passwords atau credentials
- Private keys atau certificates
- Actual secrets atau salts
- Production database dumps
- Personal information

Jika tidak sengaja commit sensitive data:
1. Segera hubungi maintainer
2. Rotate credentials yang ter-expose
3. Use `git filter-branch` atau `BFG Repo-Cleaner` untuk remove dari history

## 📞 Kontak

Untuk pertanyaan:
- Email: admin@bpkad.bengkaliskab.go.id
- Create issue di GitHub

## 📄 License

Dengan berkontribusi, Anda setuju bahwa kontribusi Anda akan dilisensikan di bawah MIT License.

---

Terima kasih atas kontribusi Anda! 🙏

