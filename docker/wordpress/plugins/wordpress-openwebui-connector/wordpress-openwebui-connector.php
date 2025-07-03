<?php
/**
 * Plugin Name: WordPress OpenWebUI Connector
 * Plugin URI: https://github.com/ionos-cloud/wp-openwebui
 * Description: Securely connect WordPress to OpenWebUI using OAuth2 and Application Passwords
 * Version: 1.0.0
 * Author: IONOS
 * License: MIT
 * Text Domain: wp-openwebui-connector
 */

if (!defined('ABSPATH')) {
    exit;
}

// Plugin constants
define('WP_OPENWEBUI_CONNECTOR_VERSION', '1.0.0');
define('WP_OPENWEBUI_CONNECTOR_PLUGIN_DIR', plugin_dir_path(__FILE__));
define('WP_OPENWEBUI_CONNECTOR_PLUGIN_URL', plugin_dir_url(__FILE__));

// Include required files
require_once WP_OPENWEBUI_CONNECTOR_PLUGIN_DIR . 'includes/class-oauth-client.php';
require_once WP_OPENWEBUI_CONNECTOR_PLUGIN_DIR . 'includes/class-api-handler.php';
require_once WP_OPENWEBUI_CONNECTOR_PLUGIN_DIR . 'includes/class-settings.php';

class WP_OpenWebUI_Connector {
    
    private $oauth_client;
    private $api_handler;
    private $settings;
    
    public function __construct() {
        $this->init_hooks();
        $this->init_classes();
    }
    
    private function init_hooks() {
        add_action('init', array($this, 'init'));
        add_action('admin_menu', array($this, 'add_admin_menu'));
        add_action('admin_enqueue_scripts', array($this, 'enqueue_admin_scripts'));
        add_action('wp_ajax_wp_openwebui_oauth_callback', array($this, 'handle_oauth_callback'));
        add_action('wp_ajax_wp_openwebui_disconnect', array($this, 'handle_disconnect'));
        add_action('wp_ajax_wp_openwebui_test_connection', array($this, 'test_connection'));
    }
    
    private function init_classes() {
        $this->oauth_client = new WP_OpenWebUI_OAuth_Client();
        $this->api_handler = new WP_OpenWebUI_API_Handler();
        $this->settings = new WP_OpenWebUI_Settings();
    }
    
    public function init() {
        // Plugin initialization
        load_plugin_textdomain('wp-openwebui-connector', false, dirname(plugin_basename(__FILE__)) . '/languages/');
        
        // Handle OAuth callback
        if (isset($_GET['wp_openwebui_oauth_callback'])) {
            $this->handle_oauth_callback();
        }
    }
    
    public function add_admin_menu() {
        add_options_page(
            __('OpenWebUI Connector', 'wp-openwebui-connector'),
            __('OpenWebUI Connector', 'wp-openwebui-connector'),
            'manage_options',
            'wp-openwebui-connector',
            array($this, 'admin_page')
        );
    }
    
    public function enqueue_admin_scripts($hook) {
        if ($hook !== 'settings_page_wp-openwebui-connector') {
            return;
        }
        
        wp_enqueue_script(
            'wp-openwebui-connector-admin',
            WP_OPENWEBUI_CONNECTOR_PLUGIN_URL . 'assets/js/admin.js',
            array('jquery'),
            WP_OPENWEBUI_CONNECTOR_VERSION,
            true
        );
        
        wp_enqueue_style(
            'wp-openwebui-connector-admin',
            WP_OPENWEBUI_CONNECTOR_PLUGIN_URL . 'assets/css/admin.css',
            array(),
            WP_OPENWEBUI_CONNECTOR_VERSION
        );
        
        wp_localize_script('wp-openwebui-connector-admin', 'wpOpenWebUIConnector', array(
            'ajaxurl' => admin_url('admin-ajax.php'),
            'nonce' => wp_create_nonce('wp_openwebui_connector_nonce'),
            'strings' => array(
                'connecting' => __('Connecting...', 'wp-openwebui-connector'),
                'connected' => __('Connected Successfully', 'wp-openwebui-connector'),
                'disconnecting' => __('Disconnecting...', 'wp-openwebui-connector'),
                'disconnected' => __('Disconnected', 'wp-openwebui-connector'),
                'testing' => __('Testing Connection...', 'wp-openwebui-connector'),
                'test_success' => __('Connection Test Successful', 'wp-openwebui-connector'),
                'test_failed' => __('Connection Test Failed', 'wp-openwebui-connector'),
                'error' => __('An error occurred', 'wp-openwebui-connector')
            )
        ));
    }
    
    public function admin_page() {
        include WP_OPENWEBUI_CONNECTOR_PLUGIN_DIR . 'admin/settings-page.php';
    }
    
    public function handle_oauth_callback() {
        check_ajax_referer('wp_openwebui_connector_nonce', 'nonce');
        
        if (!current_user_can('manage_options')) {
            wp_die(__('You do not have sufficient permissions to access this page.', 'wp-openwebui-connector'));
        }
        
        $result = $this->oauth_client->handle_callback();
        
        if ($result['success']) {
            wp_send_json_success($result);
        } else {
            wp_send_json_error($result);
        }
    }
    
    public function handle_disconnect() {
        check_ajax_referer('wp_openwebui_connector_nonce', 'nonce');
        
        if (!current_user_can('manage_options')) {
            wp_die(__('You do not have sufficient permissions to access this page.', 'wp-openwebui-connector'));
        }
        
        $result = $this->oauth_client->disconnect();
        
        if ($result['success']) {
            wp_send_json_success($result);
        } else {
            wp_send_json_error($result);
        }
    }
    
    public function test_connection() {
        check_ajax_referer('wp_openwebui_connector_nonce', 'nonce');
        
        if (!current_user_can('manage_options')) {
            wp_die(__('You do not have sufficient permissions to access this page.', 'wp-openwebui-connector'));
        }
        
        $result = $this->api_handler->test_connection();
        
        if ($result['success']) {
            wp_send_json_success($result);
        } else {
            wp_send_json_error($result);
        }
    }
    
    public static function activate() {
        // Plugin activation
        if (!wp_next_scheduled('wp_openwebui_connector_cleanup')) {
            wp_schedule_event(time(), 'daily', 'wp_openwebui_connector_cleanup');
        }
    }
    
    public static function deactivate() {
        // Plugin deactivation
        wp_clear_scheduled_hook('wp_openwebui_connector_cleanup');
    }
    
    public static function uninstall() {
        // Plugin uninstall
        delete_option('wp_openwebui_connector_settings');
        delete_option('wp_openwebui_connector_connection_status');
    }
}

// Initialize the plugin
new WP_OpenWebUI_Connector();

// Register activation and deactivation hooks
register_activation_hook(__FILE__, array('WP_OpenWebUI_Connector', 'activate'));
register_deactivation_hook(__FILE__, array('WP_OpenWebUI_Connector', 'deactivate'));
register_uninstall_hook(__FILE__, array('WP_OpenWebUI_Connector', 'uninstall'));