# Must-Use Plugins Guide

Panduan penggunaan dan management Must-Use (MU) Plugins di WordPress BPKAD.

---

## 🎯 Apa Itu MU Plugin?

**Must-Use Plugins** adalah plugin WordPress yang:
- ✅ **Selalu aktif** - tidak bisa di-disable dari admin
- ✅ **Tidak hilang** saat update theme
- ✅ **Tidak hilang** saat ganti theme
- ✅ **Loading cepat** - loaded sebelum regular plugins
- ✅ **Perfect** untuk core customization

**Location**: `/wp-content/mu-plugins/`

---

## 📦 MU Plugins Yang Tersedia

### 1. Remove Metabox for Non-Admin Users

**File**: `remove-metabox-non-admin.php`  
**Purpose**: Menghilangkan metabox Jannah theme pada create/edit post untuk user non-admin

**Features**:
- Hanya admin yang bisa lihat/edit metabox settings
- User biasa (editor, author, contributor) tidak lihat metabox
- Simplify interface untuk user non-admin
- Prevent accidental changes to post settings

**Metabox yang dihilangkan**:
- `tie-post-options` - Post Settings (Jannah)
- `tie-page-options` - Page Settings (Jannah)

**Tested with**: Jannah Theme

---

## 🚀 Deployment

### Deploy ke Production

```bash
cd /Users/hermansyah/dev/bpkad.bengkaliskab.go.id

# Deploy MU plugin
./scripts/deploy-mu-plugin.sh
```

Script ini akan:
1. ✅ Create mu-plugins directory
2. ✅ Copy plugin file
3. ✅ Set correct permissions (644, www-data:www-data)
4. ✅ Validate PHP syntax
5. ✅ Verify installation

### Manual Deployment (Alternative)

```bash
# 1. Create directory
docker compose exec php-fpm mkdir -p /var/www/html/wp-content/mu-plugins

# 2. Copy plugin
docker cp wordpress/mu-plugins/remove-metabox-non-admin.php bpkad-php-fpm:/var/www/html/wp-content/mu-plugins/

# 3. Set permissions
docker compose exec -u root php-fpm chown www-data:www-data /var/www/html/wp-content/mu-plugins/remove-metabox-non-admin.php
docker compose exec -u root php-fpm chmod 644 /var/www/html/wp-content/mu-plugins/remove-metabox-non-admin.php

# 4. Validate
docker compose exec php-fpm php -l /var/www/html/wp-content/mu-plugins/remove-metabox-non-admin.php
```

---

## ✅ Testing

### Test sebagai Non-Admin

1. **Create test user** (Editor role):
```bash
docker compose run --rm wp-cli wp user create testuser test@example.com \
  --role=editor \
  --user_pass=TestPass123! \
  --allow-root
```

2. **Login sebagai test user**:
   - URL: http://bpkad.bengkaliskab.go.id/wp-admin/
   - Username: `testuser`
   - Password: `TestPass123!`

3. **Buat/Edit Post**:
   - Navigate to Posts → Add New
   - Metabox Jannah (Post Settings, Page Settings) **harus hilang**
   - Standard metabox (Featured Image, Categories, Tags) **masih ada**

4. **Login sebagai Admin**:
   - Metabox Jannah **masih ada** dan bisa digunakan

### Verify Installation

```bash
# List MU plugins
docker compose exec php-fpm ls -lh /var/www/html/wp-content/mu-plugins/

# View plugin content
docker compose exec php-fpm cat /var/www/html/wp-content/mu-plugins/remove-metabox-non-admin.php

# Check syntax
docker compose exec php-fpm php -l /var/www/html/wp-content/mu-plugins/remove-metabox-non-admin.php
```

---

## 🔧 Customization

### Menambah Metabox Yang Dihilangkan

Edit file `wordpress/mu-plugins/remove-metabox-non-admin.php`:

```php
function remove_jannah_metaboxes_for_non_admins() {
    if ( ! current_user_can( 'administrator' ) ) {
        
        // Existing metaboxes
        remove_meta_box( 'tie-post-options', 'post', 'normal' );
        remove_meta_box( 'tie-page-options', 'page', 'normal' );
        
        // Add more metaboxes to remove:
        remove_meta_box( 'postcustom', 'post', 'normal' );      // Custom Fields
        remove_meta_box( 'postexcerpt', 'post', 'normal' );     // Excerpt
        remove_meta_box( 'trackbacksdiv', 'post', 'normal' );   // Trackbacks
        remove_meta_box( 'commentstatusdiv', 'post', 'normal' ); // Comments
        remove_meta_box( 'authordiv', 'post', 'normal' );       // Author
    }
}
```

**Redeploy**:
```bash
./scripts/deploy-mu-plugin.sh
```

### Mencari ID Metabox

1. Login sebagai **Admin**
2. Buka **Create/Edit Post**
3. **Klik kanan** pada metabox yang ingin dihilangkan
4. **Inspect Element** (F12)
5. Cari attribute `id="..."` pada div metabox
6. Gunakan ID tersebut di `remove_meta_box()`

**Example**:
```html
<div id="tie-post-options" class="postbox">
  <!-- metabox content -->
</div>
```
→ ID = `tie-post-options`

```php
remove_meta_box( 'tie-post-options', 'post', 'normal' );
```

### Filter by User Role

Bisa customize untuk role tertentu:

```php
function remove_metabox_for_specific_roles() {
    $user = wp_get_current_user();
    
    // Remove for Editor and Author only
    if ( in_array( 'editor', $user->roles ) || in_array( 'author', $user->roles ) ) {
        remove_meta_box( 'tie-post-options', 'post', 'normal' );
    }
    
    // Remove for all except Admin and Editor
    if ( ! current_user_can( 'administrator' ) && ! current_user_can( 'editor' ) ) {
        remove_meta_box( 'tie-post-options', 'post', 'normal' );
    }
}
```

---

## 🛠️ Management

### List All MU Plugins

```bash
docker compose exec php-fpm ls -lh /var/www/html/wp-content/mu-plugins/
```

### View Plugin Code

```bash
docker compose exec php-fpm cat /var/www/html/wp-content/mu-plugins/remove-metabox-non-admin.php
```

### Edit Plugin (in container)

```bash
docker compose exec php-fpm nano /var/www/html/wp-content/mu-plugins/remove-metabox-non-admin.php
```

**Recommended**: Edit di host, lalu redeploy:
```bash
nano wordpress/mu-plugins/remove-metabox-non-admin.php
./scripts/deploy-mu-plugin.sh
```

### Remove Plugin

```bash
docker compose exec php-fpm rm /var/www/html/wp-content/mu-plugins/remove-metabox-non-admin.php
```

### Backup MU Plugins

```bash
# Backup all MU plugins
docker cp bpkad-php-fpm:/var/www/html/wp-content/mu-plugins ./backup-mu-plugins-$(date +%Y%m%d)
```

---

## 🐛 Troubleshooting

### Plugin Tidak Berfungsi

**Check 1: File exists**
```bash
docker compose exec php-fpm test -f /var/www/html/wp-content/mu-plugins/remove-metabox-non-admin.php && echo "EXISTS" || echo "NOT FOUND"
```

**Check 2: Permissions**
```bash
docker compose exec php-fpm ls -lh /var/www/html/wp-content/mu-plugins/
# Should be: -rw-r--r-- www-data www-data
```

**Check 3: PHP Syntax**
```bash
docker compose exec php-fpm php -l /var/www/html/wp-content/mu-plugins/remove-metabox-non-admin.php
```

**Check 4: User role**
```bash
# Check current user capabilities
docker compose run --rm wp-cli wp user get testuser --allow-root
```

### Metabox Masih Muncul

**Possible causes**:

1. **User adalah Admin** - Plugin hanya affect non-admin
2. **Cache** - Clear browser cache dan WordPress cache
3. **Wrong metabox ID** - Inspect element untuk cari ID yang benar
4. **Plugin not loaded** - Check file exists dan permissions

**Debug**:
```php
// Add to plugin for debugging
add_action( 'admin_notices', function() {
    if ( ! current_user_can( 'administrator' ) ) {
        echo '<div class="notice notice-info"><p>MU Plugin: Metaboxes removed for non-admin</p></div>';
    }
});
```

### Clear Cache

```bash
# Clear WordPress object cache (Redis)
docker compose exec php-fpm wp cache flush --allow-root

# Clear OPcache
docker compose restart php-fpm
```

---

## 📊 WordPress User Roles Reference

| Role | Capabilities | Affected by Plugin? |
|------|-------------|---------------------|
| **Administrator** | Full access | ❌ No (sees all metaboxes) |
| **Editor** | Publish/manage posts | ✅ Yes (metaboxes hidden) |
| **Author** | Publish own posts | ✅ Yes (metaboxes hidden) |
| **Contributor** | Write posts (no publish) | ✅ Yes (metaboxes hidden) |
| **Subscriber** | Read only | ✅ Yes (no post access anyway) |

---

## 🎯 Best Practices

### 1. ✅ Always Use MU Plugins for Core Functionality

**Good** (MU Plugin):
```php
// wp-content/mu-plugins/remove-metabox.php
function remove_metabox() { ... }
add_action( 'add_meta_boxes', 'remove_metabox', 999 );
```

**Bad** (functions.php):
```php
// theme/functions.php
function remove_metabox() { ... }  // Will be lost on theme update!
```

### 2. ✅ Use Descriptive File Names

**Good**:
- `remove-metabox-non-admin.php`
- `custom-user-roles.php`
- `disable-xml-rpc.php`

**Bad**:
- `functions.php`
- `custom.php`
- `my-plugin.php`

### 3. ✅ Add Plugin Headers

```php
<?php
/**
 * Plugin Name: Descriptive Name
 * Description: What this plugin does
 * Version: 1.0
 * Author: Your Name
 */
```

### 4. ✅ Document Your Code

```php
/**
 * Function description
 * 
 * @param type $param Description
 * @return type Description
 */
function your_function( $param ) {
    // Code with comments
}
```

### 5. ✅ Test Before Deploy

```bash
# Always validate syntax
php -l wordpress/mu-plugins/your-plugin.php

# Test in development first
```

---

## 📚 Common MU Plugin Use Cases

### 1. Disable XML-RPC (Security)

```php
<?php
/**
 * Plugin Name: Disable XML-RPC
 */
add_filter( 'xmlrpc_enabled', '__return_false' );
```

### 2. Disable File Editor (Security)

```php
<?php
/**
 * Plugin Name: Disable File Editor
 */
define( 'DISALLOW_FILE_EDIT', true );
```

### 3. Custom Login Redirect

```php
<?php
/**
 * Plugin Name: Custom Login Redirect
 */
add_filter( 'login_redirect', function( $redirect_to, $request, $user ) {
    if ( is_array( $user->roles ) && in_array( 'editor', $user->roles ) ) {
        return admin_url( 'edit.php' ); // Redirect editors to Posts
    }
    return $redirect_to;
}, 10, 3 );
```

### 4. Remove Admin Bar for Non-Admins

```php
<?php
/**
 * Plugin Name: Hide Admin Bar
 */
add_action( 'after_setup_theme', function() {
    if ( ! current_user_can( 'administrator' ) ) {
        show_admin_bar( false );
    }
});
```

---

## 🔐 Security Considerations

### 1. Always Check User Capabilities

```php
// Good
if ( ! current_user_can( 'administrator' ) ) {
    // Do something
}

// Bad
if ( $user->roles[0] === 'administrator' ) {  // Not reliable
    // Do something
}
```

### 2. Prevent Direct Access

```php
// Always add at the top
if ( ! defined( 'ABSPATH' ) ) {
    exit;
}
```

### 3. Validate and Sanitize Input

```php
// If your plugin accepts input
$input = sanitize_text_field( $_POST['input'] );
```

---

## 📞 Support

### Documentation
- **This file**: `MU_PLUGIN_GUIDE.md`
- **WordPress MU Plugins**: https://wordpress.org/support/article/must-use-plugins/

### Commands Reference
```bash
# Deploy
./scripts/deploy-mu-plugin.sh

# List
docker compose exec php-fpm ls -lh /var/www/html/wp-content/mu-plugins/

# View
docker compose exec php-fpm cat /var/www/html/wp-content/mu-plugins/<plugin-name>.php

# Remove
docker compose exec php-fpm rm /var/www/html/wp-content/mu-plugins/<plugin-name>.php

# Validate
docker compose exec php-fpm php -l /var/www/html/wp-content/mu-plugins/<plugin-name>.php
```

---

## ✅ Summary

```
✅ MU Plugins selalu aktif (tidak bisa disable)
✅ Tidak hilang saat update/ganti theme
✅ Perfect untuk core customization
✅ Loading cepat (sebelum regular plugins)
✅ Simple deployment dengan script
✅ Easy to manage dan maintain
```

---

**Created**: November 2024  
**Status**: Production Ready  
**Version**: 1.0

