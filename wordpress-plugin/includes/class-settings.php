<?php

if (!defined('ABSPATH')) {
    exit;
}

class WP_OpenWebUI_Settings {
    
    private $settings_option = 'wp_openwebui_connector_settings';
    
    public function __construct() {
        add_action('admin_init', array($this, 'init_settings'));
    }
    
    public function init_settings() {
        register_setting(
            'wp_openwebui_connector_settings_group',
            $this->settings_option,
            array($this, 'sanitize_settings')
        );
        
        add_settings_section(
            'wp_openwebui_connector_main_section',
            __('OpenWebUI Connection Settings', 'wp-openwebui-connector'),
            array($this, 'settings_section_callback'),
            'wp_openwebui_connector_settings'
        );
        
        add_settings_field(
            'openwebui_url',
            __('OpenWebUI URL', 'wp-openwebui-connector'),
            array($this, 'openwebui_url_callback'),
            'wp_openwebui_connector_settings',
            'wp_openwebui_connector_main_section'
        );
        
        add_settings_field(
            'client_id',
            __('OAuth2 Client ID', 'wp-openwebui-connector'),
            array($this, 'client_id_callback'),
            'wp_openwebui_connector_settings',
            'wp_openwebui_connector_main_section'
        );
        
        add_settings_field(
            'client_secret',
            __('OAuth2 Client Secret', 'wp-openwebui-connector'),
            array($this, 'client_secret_callback'),
            'wp_openwebui_connector_settings',
            'wp_openwebui_connector_main_section'
        );
    }
    
    public function settings_section_callback() {
        echo '<p>' . __('Configure your OpenWebUI connection settings below.', 'wp-openwebui-connector') . '</p>';
    }
    
    public function openwebui_url_callback() {
        $settings = get_option($this->settings_option, array());
        $value = isset($settings['openwebui_url']) ? $settings['openwebui_url'] : '';
        
        echo '<input type="url" id="openwebui_url" name="' . $this->settings_option . '[openwebui_url]" value="' . esc_attr($value) . '" class="regular-text" placeholder="https://your-openwebui-instance.com" />';
        echo '<p class="description">' . __('The base URL of your OpenWebUI instance (e.g., https://openwebui.example.com)', 'wp-openwebui-connector') . '</p>';
    }
    
    public function client_id_callback() {
        $settings = get_option($this->settings_option, array());
        $value = isset($settings['client_id']) ? $settings['client_id'] : '';
        
        echo '<input type="text" id="client_id" name="' . $this->settings_option . '[client_id]" value="' . esc_attr($value) . '" class="regular-text" />';
        echo '<p class="description">' . __('OAuth2 Client ID provided by OpenWebUI', 'wp-openwebui-connector') . '</p>';
    }
    
    public function client_secret_callback() {
        $settings = get_option($this->settings_option, array());
        $value = isset($settings['client_secret']) ? $settings['client_secret'] : '';
        
        echo '<input type="password" id="client_secret" name="' . $this->settings_option . '[client_secret]" value="' . esc_attr($value) . '" class="regular-text" />';
        echo '<p class="description">' . __('OAuth2 Client Secret provided by OpenWebUI', 'wp-openwebui-connector') . '</p>';
    }
    
    public function sanitize_settings($input) {
        $sanitized = array();
        
        if (isset($input['openwebui_url'])) {
            $sanitized['openwebui_url'] = esc_url_raw($input['openwebui_url']);
        }
        
        if (isset($input['client_id'])) {
            $sanitized['client_id'] = sanitize_text_field($input['client_id']);
        }
        
        if (isset($input['client_secret'])) {
            $sanitized['client_secret'] = sanitize_text_field($input['client_secret']);
        }
        
        // Update individual options for easy access
        update_option('wp_openwebui_connector_openwebui_url', $sanitized['openwebui_url'] ?? '');
        update_option('wp_openwebui_connector_client_id', $sanitized['client_id'] ?? '');
        update_option('wp_openwebui_connector_client_secret', $sanitized['client_secret'] ?? '');
        
        return $sanitized;
    }
    
    public function get_setting($key, $default = '') {
        $settings = get_option($this->settings_option, array());
        return isset($settings[$key]) ? $settings[$key] : $default;
    }
    
    public function update_setting($key, $value) {
        $settings = get_option($this->settings_option, array());
        $settings[$key] = $value;
        update_option($this->settings_option, $settings);
    }
}