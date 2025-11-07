#!/usr/bin/env python3
"""
Safe wp-config.php editor
Adds Redis and REST API configuration safely
"""

import sys
import os
import re
from datetime import datetime

def backup_file(filepath):
    """Create timestamped backup"""
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    backup_path = f"{filepath}.backup.{timestamp}"
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    with open(backup_path, 'w') as f:
        f.write(content)
    
    print(f"✓ Backup created: {backup_path}")
    return backup_path

def remove_old_configs(content):
    """Remove any existing Redis and REST API configs"""
    
    # Remove Redis config lines
    content = re.sub(r'/\*\s*Redis Object Cache Configuration\s*\*/\s*\n', '', content)
    content = re.sub(r"define\('WP_REDIS_[^']+',\s*[^)]+\);\s*\n", '', content)
    
    # Remove REST API config lines
    content = re.sub(r'/\*\s*Fix REST API Loopback[^*]*\*/\s*\n', '', content)
    content = re.sub(r"if\s*\(!defined\('WP_HTTP_BLOCK_EXTERNAL'\)\)[^}]+}\s*\n", '', content)
    content = re.sub(r"add_filter\('https_ssl_verify'[^;]+;\s*\n", '', content)
    content = re.sub(r"add_filter\('https_local_ssl_verify'[^;]+;\s*\n", '', content)
    content = re.sub(r"add_filter\('http_request_host_is_external'[^;]+;\s*\n", '', content)
    content = re.sub(r"add_filter\('rest_url'[^}]+}\);\s*\n", '', content, flags=re.MULTILINE | re.DOTALL)
    
    # Remove empty lines (more than 2 consecutive)
    content = re.sub(r'\n\n\n+', '\n\n', content)
    
    return content

def add_configs(content):
    """Add Redis and REST API configurations"""
    
    # Configuration to add
    new_config = """
/* Redis Object Cache Configuration */
define('WP_REDIS_HOST', 'redis');
define('WP_REDIS_PORT', 6379);
define('WP_REDIS_TIMEOUT', 1);
define('WP_REDIS_READ_TIMEOUT', 1);
define('WP_REDIS_DATABASE', 0);

/* Fix REST API Loopback - Use HTTP Internally */
if (!defined('WP_HTTP_BLOCK_EXTERNAL')) {
    define('WP_HTTP_BLOCK_EXTERNAL', false);
}
add_filter('https_ssl_verify', '__return_false');
add_filter('https_local_ssl_verify', '__return_false');
add_filter('http_request_host_is_external', '__return_false');
add_filter('rest_url', function($url) {
    return str_replace('https://', 'http://', $url);
});

"""
    
    # Find insertion point (before "That's all")
    markers = [
        "/* That's all, stop editing! Happy publishing. */",
        "/* That's all, stop editing! Happy blogging. */",
        "/* That's all, stop editing!",
    ]
    
    for marker in markers:
        if marker in content:
            content = content.replace(marker, new_config + marker)
            print(f"✓ Config inserted before: {marker}")
            return content
    
    # If no marker found, add before closing PHP tag or at end
    if '?>' in content:
        content = content.replace('?>', new_config + '?>')
        print("✓ Config inserted before closing PHP tag")
    else:
        content = content + new_config
        print("✓ Config appended to end of file")
    
    return content

def validate_php_syntax(content):
    """Basic PHP syntax validation"""
    
    # Check balanced braces
    open_braces = content.count('{')
    close_braces = content.count('}')
    if open_braces != close_braces:
        return False, f"Unbalanced braces: {open_braces} open, {close_braces} close"
    
    # Check balanced parentheses
    open_parens = content.count('(')
    close_parens = content.count(')')
    if open_parens != close_parens:
        return False, f"Unbalanced parentheses: {open_parens} open, {close_parens} close"
    
    # Check for basic syntax issues
    if 'define(' in content and not re.search(r"define\('[^']+',\s*[^)]+\)", content):
        return False, "Invalid define() syntax"
    
    return True, "OK"

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 fix-wpconfig-safe.py /path/to/wp-config.php")
        sys.exit(1)
    
    filepath = sys.argv[1]
    
    if not os.path.exists(filepath):
        print(f"✗ Error: File not found: {filepath}")
        sys.exit(1)
    
    print("=" * 50)
    print("Safe wp-config.php Editor")
    print("=" * 50)
    print()
    
    # Step 1: Backup
    print("[1/6] Creating backup...")
    try:
        backup_path = backup_file(filepath)
    except Exception as e:
        print(f"✗ Backup failed: {e}")
        sys.exit(1)
    
    # Step 2: Read original
    print("[2/6] Reading original file...")
    try:
        with open(filepath, 'r') as f:
            original_content = f.read()
        print(f"✓ Read {len(original_content)} bytes")
    except Exception as e:
        print(f"✗ Read failed: {e}")
        sys.exit(1)
    
    # Step 3: Remove old configs
    print("[3/6] Cleaning old configurations...")
    cleaned_content = remove_old_configs(original_content)
    print("✓ Old configs removed")
    
    # Step 4: Add new configs
    print("[4/6] Adding new configurations...")
    new_content = add_configs(cleaned_content)
    
    # Step 5: Validate
    print("[5/6] Validating syntax...")
    valid, message = validate_php_syntax(new_content)
    if not valid:
        print(f"✗ Validation failed: {message}")
        print(f"✓ Original file unchanged")
        sys.exit(1)
    print(f"✓ Validation passed: {message}")
    
    # Step 6: Write
    print("[6/6] Writing updated file...")
    try:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"✓ Wrote {len(new_content)} bytes")
    except Exception as e:
        print(f"✗ Write failed: {e}")
        print(f"Restoring from backup: {backup_path}")
        with open(backup_path, 'r') as f:
            with open(filepath, 'w') as fw:
                fw.write(f.read())
        sys.exit(1)
    
    print()
    print("=" * 50)
    print("✅ SUCCESS! Configuration updated")
    print("=" * 50)
    print()
    print("Backup saved to:", backup_path)
    print()
    print("Next steps:")
    print("1. Restart PHP-FPM: docker compose restart php-fpm")
    print("2. Enable Redis: WordPress Admin → Settings → Redis")
    print("3. Check Site Health: WordPress Admin → Tools → Site Health")
    
    return 0

if __name__ == '__main__':
    sys.exit(main())

