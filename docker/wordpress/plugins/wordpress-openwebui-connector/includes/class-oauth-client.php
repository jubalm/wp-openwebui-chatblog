<?php

if (!defined('ABSPATH')) {
    exit;
}

class WP_OpenWebUI_OAuth_Client {
    
    private $openwebui_url;
    private $client_id;
    private $client_secret;
    private $redirect_uri;
    
    public function __construct() {
        $this->openwebui_url = get_option('wp_openwebui_connector_openwebui_url', '');
        $this->client_id = get_option('wp_openwebui_connector_client_id', '');
        $this->client_secret = get_option('wp_openwebui_connector_client_secret', '');
        $this->redirect_uri = admin_url('options-general.php?page=wp-openwebui-connector&wp_openwebui_oauth_callback=1');
    }
    
    /**
     * Generate OAuth2 authorization URL
     */
    public function get_authorization_url() {
        $state = wp_create_nonce('wp_openwebui_oauth_state');
        update_option('wp_openwebui_connector_oauth_state', $state);
        
        $params = array(
            'response_type' => 'code',
            'client_id' => $this->client_id,
            'redirect_uri' => $this->redirect_uri,
            'scope' => 'openid profile email',
            'state' => $state,
            'site_url' => home_url(),
            'site_name' => get_bloginfo('name')
        );
        
        return $this->openwebui_url . '/api/wordpress/oauth/authorize?' . http_build_query($params);
    }
    
    /**
     * Handle OAuth callback from OpenWebUI
     */
    public function handle_callback() {
        try {
            // Verify state parameter
            $state = sanitize_text_field($_GET['state'] ?? '');
            $stored_state = get_option('wp_openwebui_connector_oauth_state', '');
            
            if (!$state || !hash_equals($stored_state, $state)) {
                return array(
                    'success' => false,
                    'message' => __('Invalid state parameter', 'wp-openwebui-connector')
                );
            }
            
            // Check for error in callback
            if (isset($_GET['error'])) {
                $error = sanitize_text_field($_GET['error']);
                $error_description = sanitize_text_field($_GET['error_description'] ?? '');
                
                return array(
                    'success' => false,
                    'message' => sprintf(__('OAuth error: %s - %s', 'wp-openwebui-connector'), $error, $error_description)
                );
            }
            
            // Get authorization code
            $code = sanitize_text_field($_GET['code'] ?? '');
            if (!$code) {
                return array(
                    'success' => false,
                    'message' => __('No authorization code received', 'wp-openwebui-connector')
                );
            }
            
            // Exchange code for tokens
            $token_response = $this->exchange_code_for_tokens($code);
            
            if (!$token_response['success']) {
                return $token_response;
            }
            
            // Store tokens and connection info
            $this->store_connection_info($token_response['data']);
            
            // Clean up state
            delete_option('wp_openwebui_connector_oauth_state');
            
            return array(
                'success' => true,
                'message' => __('Successfully connected to OpenWebUI', 'wp-openwebui-connector'),
                'redirect' => admin_url('options-general.php?page=wp-openwebui-connector&connected=1')
            );
            
        } catch (Exception $e) {
            return array(
                'success' => false,
                'message' => sprintf(__('Connection error: %s', 'wp-openwebui-connector'), $e->getMessage())
            );
        }
    }
    
    /**
     * Exchange authorization code for tokens
     */
    private function exchange_code_for_tokens($code) {
        $token_url = $this->openwebui_url . '/api/wordpress/oauth/token';
        
        $body = array(
            'grant_type' => 'authorization_code',
            'code' => $code,
            'redirect_uri' => $this->redirect_uri,
            'client_id' => $this->client_id,
            'client_secret' => $this->client_secret
        );
        
        $response = wp_remote_post($token_url, array(
            'body' => $body,
            'headers' => array(
                'Content-Type' => 'application/x-www-form-urlencoded'
            ),
            'timeout' => 30,
            'sslverify' => true
        ));
        
        if (is_wp_error($response)) {
            return array(
                'success' => false,
                'message' => sprintf(__('Token exchange failed: %s', 'wp-openwebui-connector'), $response->get_error_message())
            );
        }
        
        $response_code = wp_remote_retrieve_response_code($response);
        $response_body = wp_remote_retrieve_body($response);
        
        if ($response_code !== 200) {
            return array(
                'success' => false,
                'message' => sprintf(__('Token exchange failed with status %d: %s', 'wp-openwebui-connector'), $response_code, $response_body)
            );
        }
        
        $token_data = json_decode($response_body, true);
        
        if (!$token_data || !isset($token_data['access_token'])) {
            return array(
                'success' => false,
                'message' => __('Invalid token response', 'wp-openwebui-connector')
            );
        }
        
        return array(
            'success' => true,
            'data' => $token_data
        );
    }
    
    /**
     * Store connection information
     */
    private function store_connection_info($token_data) {
        $connection_info = array(
            'access_token' => $token_data['access_token'],
            'refresh_token' => $token_data['refresh_token'] ?? '',
            'token_type' => $token_data['token_type'] ?? 'Bearer',
            'expires_in' => $token_data['expires_in'] ?? 3600,
            'expires_at' => time() + ($token_data['expires_in'] ?? 3600),
            'scope' => $token_data['scope'] ?? '',
            'created_at' => current_time('timestamp')
        );
        
        update_option('wp_openwebui_connector_connection_info', $connection_info);
        update_option('wp_openwebui_connector_connection_status', 'connected');
    }
    
    /**
     * Get stored access token
     */
    public function get_access_token() {
        $connection_info = get_option('wp_openwebui_connector_connection_info', array());
        
        if (empty($connection_info['access_token'])) {
            return false;
        }
        
        // Check if token is expired
        if (isset($connection_info['expires_at']) && time() > $connection_info['expires_at']) {
            // Try to refresh token
            $refreshed = $this->refresh_token();
            if ($refreshed) {
                $connection_info = get_option('wp_openwebui_connector_connection_info', array());
                return $connection_info['access_token'];
            }
            return false;
        }
        
        return $connection_info['access_token'];
    }
    
    /**
     * Refresh access token
     */
    private function refresh_token() {
        $connection_info = get_option('wp_openwebui_connector_connection_info', array());
        
        if (empty($connection_info['refresh_token'])) {
            return false;
        }
        
        $token_url = $this->openwebui_url . '/api/wordpress/oauth/token';
        
        $body = array(
            'grant_type' => 'refresh_token',
            'refresh_token' => $connection_info['refresh_token'],
            'client_id' => $this->client_id,
            'client_secret' => $this->client_secret
        );
        
        $response = wp_remote_post($token_url, array(
            'body' => $body,
            'headers' => array(
                'Content-Type' => 'application/x-www-form-urlencoded'
            ),
            'timeout' => 30,
            'sslverify' => true
        ));
        
        if (is_wp_error($response)) {
            return false;
        }
        
        $response_code = wp_remote_retrieve_response_code($response);
        $response_body = wp_remote_retrieve_body($response);
        
        if ($response_code !== 200) {
            return false;
        }
        
        $token_data = json_decode($response_body, true);
        
        if (!$token_data || !isset($token_data['access_token'])) {
            return false;
        }
        
        $this->store_connection_info($token_data);
        
        return true;
    }
    
    /**
     * Disconnect from OpenWebUI
     */
    public function disconnect() {
        try {
            // Revoke token at OpenWebUI
            $access_token = $this->get_access_token();
            if ($access_token) {
                $revoke_url = $this->openwebui_url . '/api/wordpress/oauth/revoke';
                
                wp_remote_post($revoke_url, array(
                    'headers' => array(
                        'Authorization' => 'Bearer ' . $access_token,
                        'Content-Type' => 'application/x-www-form-urlencoded'
                    ),
                    'body' => array(
                        'token' => $access_token
                    ),
                    'timeout' => 30,
                    'sslverify' => true
                ));
            }
            
            // Clear local storage
            delete_option('wp_openwebui_connector_connection_info');
            delete_option('wp_openwebui_connector_connection_status');
            delete_option('wp_openwebui_connector_oauth_state');
            
            return array(
                'success' => true,
                'message' => __('Successfully disconnected from OpenWebUI', 'wp-openwebui-connector')
            );
            
        } catch (Exception $e) {
            return array(
                'success' => false,
                'message' => sprintf(__('Disconnection error: %s', 'wp-openwebui-connector'), $e->getMessage())
            );
        }
    }
    
    /**
     * Check if connected to OpenWebUI
     */
    public function is_connected() {
        $connection_status = get_option('wp_openwebui_connector_connection_status', 'disconnected');
        return $connection_status === 'connected' && $this->get_access_token() !== false;
    }
    
    /**
     * Get connection status
     */
    public function get_connection_status() {
        $connection_info = get_option('wp_openwebui_connector_connection_info', array());
        
        if (empty($connection_info)) {
            return array(
                'status' => 'disconnected',
                'message' => __('Not connected to OpenWebUI', 'wp-openwebui-connector')
            );
        }
        
        $is_connected = $this->is_connected();
        
        return array(
            'status' => $is_connected ? 'connected' : 'expired',
            'message' => $is_connected 
                ? __('Connected to OpenWebUI', 'wp-openwebui-connector')
                : __('Connection expired', 'wp-openwebui-connector'),
            'connected_at' => $connection_info['created_at'] ?? '',
            'expires_at' => $connection_info['expires_at'] ?? ''
        );
    }
}