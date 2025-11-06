# Git Repository Setup - bpkadweb

Panduan setup git repository untuk project BPKAD WordPress.

## 📊 Current Git Status

```bash
Repository: Initialized ✅
Remote: https://github.com/azzamweb/bpkad.bengkaliskab.go.id.git
Branch: main
Commits: 1 (first commit)
All files: Committed ✅
```

## 🔄 Option 1: Rename Repository (Recommended)

Jika ingin mengubah nama repository dari `bpkad.bengkaliskab.go.id` → `bpkadweb`:

### Step 1: Rename di GitHub

1. Buka: https://github.com/azzamweb/bpkad.bengkaliskab.go.id
2. Klik **Settings** (⚙️)
3. Di bagian **General** → **Repository name**
4. Ganti menjadi: `bpkadweb`
5. Klik **Rename**

### Step 2: Update Remote URL di Local

```bash
cd /Users/hermansyah/dev/bpkad.bengkaliskab.go.id

# Update remote URL
git remote set-url origin https://github.com/azzamweb/bpkadweb.git

# Verify
git remote -v
```

**Output expected:**
```
origin  https://github.com/azzamweb/bpkadweb.git (fetch)
origin  https://github.com/azzamweb/bpkadweb.git (push)
```

### Step 3: Test Push

```bash
# Test connection
git push origin main

# Should work without issues
```

✅ **Done!** Repository sekarang bernama `bpkadweb`

---

## 🆕 Option 2: Create New Repository

Jika ingin membuat repository baru dengan nama `bpkadweb`:

### Step 1: Create New Repository di GitHub

1. Buka: https://github.com/new
2. **Repository name**: `bpkadweb`
3. **Description**: "WordPress Docker untuk BPKAD Kabupaten Bengkalis"
4. **Visibility**: Private atau Public (sesuai kebutuhan)
5. **JANGAN** initialize dengan README, .gitignore, atau license (sudah ada)
6. Klik **Create repository**

### Step 2: Update Remote URL

```bash
cd /Users/hermansyah/dev/bpkad.bengkaliskab.go.id

# Remove old remote
git remote remove origin

# Add new remote
git remote add origin https://github.com/azzamweb/bpkadweb.git

# Verify
git remote -v
```

### Step 3: Push ke Repository Baru

```bash
# Push main branch
git push -u origin main

# Verify di GitHub
```

✅ **Done!** Repository baru `bpkadweb` telah dibuat

---

## 🔗 Option 3: Add Multiple Remotes

Jika ingin keep keduanya (bpkad.bengkaliskab.go.id dan bpkadweb):

```bash
cd /Users/hermansyah/dev/bpkad.bengkaliskab.go.id

# Keep existing as 'origin'
# Add new remote as 'bpkadweb'
git remote add bpkadweb https://github.com/azzamweb/bpkadweb.git

# Push to both
git push origin main
git push bpkadweb main

# View all remotes
git remote -v
```

**Output:**
```
origin      https://github.com/azzamweb/bpkad.bengkaliskab.go.id.git (fetch)
origin      https://github.com/azzamweb/bpkad.bengkaliskab.go.id.git (push)
bpkadweb    https://github.com/azzamweb/bpkadweb.git (fetch)
bpkadweb    https://github.com/azzamweb/bpkadweb.git (push)
```

---

## 📝 Recommended Git Workflow

### Daily Development

```bash
# Check status
git status

# Add changes
git add .

# Commit with meaningful message
git commit -m "Update: description of changes"

# Push to remote
git push origin main
```

### Create Feature Branch

```bash
# Create and switch to new branch
git checkout -b feature/nama-fitur

# Make changes, then commit
git add .
git commit -m "Add: new feature description"

# Push feature branch
git push origin feature/nama-fitur

# Merge to main (after review)
git checkout main
git merge feature/nama-fitur
git push origin main
```

### Update from Remote

```bash
# Pull latest changes
git pull origin main

# Or fetch and merge
git fetch origin
git merge origin/main
```

---

## 🔐 Git Security Best Practices

### Never Commit Secrets

✅ Already configured in `.gitignore`:
```
secrets/
*.key
*.pem
*.crt
*.txt (in secrets/)
.env
```

### Verify Before Commit

```bash
# Check what will be committed
git status
git diff --cached

# Check if secrets accidentally added
git ls-files | grep -E "secrets|\.env|\.key|password"
# Should return nothing or only .env.example
```

### Remove Accidentally Committed Secrets

If you accidentally commit secrets:

```bash
# Remove file from git (keep local copy)
git rm --cached secrets/db_password.txt

# Commit the removal
git commit -m "Security: remove accidentally committed secrets"

# For already pushed commits, consider:
# 1. Rotate all exposed credentials immediately
# 2. Use git filter-branch or BFG Repo-Cleaner
# 3. Force push (be careful!)
```

---

## 📋 Git Commands Reference

### Essential Commands

```bash
# Status
git status                    # Check working directory status
git log --oneline            # View commit history
git remote -v                # View remotes

# Stage & Commit
git add .                    # Stage all changes
git add file.txt             # Stage specific file
git commit -m "message"      # Commit with message
git commit --amend           # Amend last commit

# Push & Pull
git push origin main         # Push to remote
git pull origin main         # Pull from remote
git fetch origin             # Fetch without merge

# Branches
git branch                   # List local branches
git branch -a                # List all branches
git checkout -b new-branch   # Create and switch
git branch -d branch-name    # Delete local branch

# Undo Changes
git restore file.txt         # Discard changes in file
git restore --staged file    # Unstage file
git reset --soft HEAD~1      # Undo last commit (keep changes)
git reset --hard HEAD~1      # Undo last commit (discard changes)
```

### Advanced Commands

```bash
# Stash changes
git stash                    # Save changes temporarily
git stash pop                # Apply stashed changes
git stash list               # List all stashes

# Cherry-pick
git cherry-pick <commit>     # Apply specific commit

# Rebase
git rebase main              # Rebase current branch on main

# Tags
git tag v1.0.0               # Create tag
git push origin v1.0.0       # Push tag
git tag -l                   # List tags
```

---

## 🌿 Branch Strategy

### For Small Team

**Simple Flow:**
```
main (production)
  └─ develop (staging)
      ├─ feature/user-auth
      ├─ feature/backup-system
      └─ fix/database-connection
```

**Workflow:**
1. Develop in `feature/*` or `fix/*` branches
2. Merge to `develop` for testing
3. Merge `develop` to `main` for production

### For Solo/Small Project

**Single Branch:**
```
main (production)
```

Just commit directly to `main` for quick updates.

---

## 🔄 .gitignore Reference

Current `.gitignore` includes:

```gitignore
# Secrets and sensitive data
secrets/
*.key
*.pem
*.crt

# Environment files
.env
*.local

# Logs
logs/
*.log

# Backups
backups/
*.sql
*.sql.gz
*.tar.gz

# WordPress uploads
wp-content/uploads/
wp-content/cache/

# OS files
.DS_Store
Thumbs.db

# Editor files
.vscode/
.idea/
*.swp
```

---

## 📞 Git Resources

### Documentation
- Git Official: https://git-scm.com/doc
- GitHub Guides: https://guides.github.com
- Git Cheat Sheet: https://education.github.com/git-cheat-sheet-education.pdf

### Tools
- **GitHub Desktop**: GUI for Git
- **GitKraken**: Advanced Git client
- **Sourcetree**: Free Git GUI

---

## ✅ Quick Setup Summary

**For renaming to "bpkadweb":**

```bash
# 1. Rename di GitHub (Settings → Rename)
# 2. Update local remote:
git remote set-url origin https://github.com/azzamweb/bpkadweb.git
git remote -v  # Verify
git push origin main  # Test
```

**Done! 🎉**

---

**Last Updated**: November 2024  
**Repository**: bpkadweb

