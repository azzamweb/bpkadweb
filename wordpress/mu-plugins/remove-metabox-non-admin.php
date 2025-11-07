<?php
/**
 * Plugin Name: Remove Metabox for Non-Admin Users
 * Description: Menghilangkan metabox Jannah theme pada create/edit post untuk user non-admin
 * Version: 1.0
 * Author: BPKAD IT Team
 * 
 * Must-Use Plugin - Always active, tidak bisa di-disable
 */

// Prevent direct access
if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

/**
 * Remove Jannah theme metaboxes for non-admin users
 * 
 * Fungsi ini akan menghilangkan metabox settings dari Jannah theme
 * pada halaman create/edit post dan page untuk user yang bukan administrator.
 * 
 * @return void
 */
function remove_jannah_metaboxes_for_non_admins() {
    
    // Check if the current user is NOT an administrator
    if ( ! current_user_can( 'administrator' ) ) {
        
        // Post Settings Metabox (Jannah theme)
        remove_meta_box( 'tie-post-options', 'post', 'normal' );
        
        // Page Settings Metabox (Jannah theme)
        remove_meta_box( 'tie-page-options', 'page', 'normal' );
        
        // Additional metaboxes yang mungkin perlu dihilangkan:
        // Uncomment jika perlu
        
        // Remove custom fields metabox
        // remove_meta_box( 'postcustom', 'post', 'normal' );
        
        // Remove excerpt metabox
        // remove_meta_box( 'postexcerpt', 'post', 'normal' );
        
        // Remove trackbacks metabox
        // remove_meta_box( 'trackbacksdiv', 'post', 'normal' );
        
        // Remove comments metabox
        // remove_meta_box( 'commentstatusdiv', 'post', 'normal' );
        
        // Remove author metabox
        // remove_meta_box( 'authordiv', 'post', 'normal' );
        
        // Remove slug metabox
        // remove_meta_box( 'slugdiv', 'post', 'normal' );
        
        /**
         * Cara mencari ID metabox:
         * 1. Login sebagai admin
         * 2. Buka halaman Create/Edit Post
         * 3. Klik kanan pada metabox yang ingin dihilangkan
         * 4. Inspect Element
         * 5. Cari attribute id="..." pada div metabox
         * 6. Tambahkan remove_meta_box() dengan ID tersebut
         * 
         * Format: remove_meta_box( 'metabox-id', 'post', 'normal' );
         */
    }
}

// Hook ke add_meta_boxes dengan priority 999 (dijalankan paling akhir)
add_action( 'add_meta_boxes', 'remove_jannah_metaboxes_for_non_admins', 999 );

/**
 * Log untuk debugging (optional)
 * Uncomment untuk melihat log di debug.log
 */
/*
add_action( 'admin_init', function() {
    if ( ! current_user_can( 'administrator' ) ) {
        error_log( 'Remove Metabox Plugin: Non-admin user detected, metaboxes removed' );
    }
});
*/

/**
 * Fungsi tambahan: Remove metabox untuk post types lain (optional)
 */
/*
function remove_metabox_for_custom_post_types() {
    if ( ! current_user_can( 'administrator' ) ) {
        // Contoh untuk custom post type
        remove_meta_box( 'tie-post-options', 'your_custom_post_type', 'normal' );
    }
}
add_action( 'add_meta_boxes', 'remove_metabox_for_custom_post_types', 999 );
*/

