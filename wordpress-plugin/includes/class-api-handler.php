<?php

if (!defined('ABSPATH')) {
    exit;
}

class WP_OpenWebUI_API_Handler {
    
    private $oauth_client;
    
    public function __construct() {
        $this->oauth_client = new WP_OpenWebUI_OAuth_Client();
    }
    
    /**
     * Test connection to OpenWebUI
     */
    public function test_connection() {
        try {
            if (!$this->oauth_client->is_connected()) {
                return array(
                    'success' => false,
                    'message' => __('Not connected to OpenWebUI', 'wp-openwebui-connector')
                );
            }
            
            $access_token = $this->oauth_client->get_access_token();
            if (!$access_token) {
                return array(
                    'success' => false,
                    'message' => __('No valid access token', 'wp-openwebui-connector')
                );
            }
            
            $openwebui_url = get_option('wp_openwebui_connector_openwebui_url', '');
            $test_url = $openwebui_url . '/api/wordpress/test';
            
            $response = wp_remote_get($test_url, array(
                'headers' => array(
                    'Authorization' => 'Bearer ' . $access_token,
                    'Content-Type' => 'application/json'
                ),
                'timeout' => 30,
                'sslverify' => true
            ));
            
            if (is_wp_error($response)) {
                return array(
                    'success' => false,
                    'message' => sprintf(__('Connection test failed: %s', 'wp-openwebui-connector'), $response->get_error_message())
                );
            }
            
            $response_code = wp_remote_retrieve_response_code($response);
            $response_body = wp_remote_retrieve_body($response);
            
            if ($response_code === 200) {
                $data = json_decode($response_body, true);
                return array(
                    'success' => true,
                    'message' => __('Connection test successful', 'wp-openwebui-connector'),
                    'data' => $data
                );
            } else {
                return array(
                    'success' => false,
                    'message' => sprintf(__('Connection test failed with status %d: %s', 'wp-openwebui-connector'), $response_code, $response_body)
                );
            }
            
        } catch (Exception $e) {
            return array(
                'success' => false,
                'message' => sprintf(__('Connection test error: %s', 'wp-openwebui-connector'), $e->getMessage())
            );
        }
    }
    
    /**
     * Send application password to OpenWebUI
     */
    public function register_application_password($application_password) {
        try {
            if (!$this->oauth_client->is_connected()) {
                return array(
                    'success' => false,
                    'message' => __('Not connected to OpenWebUI', 'wp-openwebui-connector')
                );
            }
            
            $access_token = $this->oauth_client->get_access_token();
            if (!$access_token) {
                return array(
                    'success' => false,
                    'message' => __('No valid access token', 'wp-openwebui-connector')
                );
            }
            
            $openwebui_url = get_option('wp_openwebui_connector_openwebui_url', '');
            $register_url = $openwebui_url . '/api/wordpress/register-connection';
            
            $body = array(
                'site_url' => home_url(),
                'site_name' => get_bloginfo('name'),
                'application_password' => $application_password
            );
            
            $response = wp_remote_post($register_url, array(
                'headers' => array(
                    'Authorization' => 'Bearer ' . $access_token,
                    'Content-Type' => 'application/json'
                ),
                'body' => wp_json_encode($body),
                'timeout' => 30,
                'sslverify' => true
            ));
            
            if (is_wp_error($response)) {
                return array(
                    'success' => false,
                    'message' => sprintf(__('Registration failed: %s', 'wp-openwebui-connector'), $response->get_error_message())
                );
            }
            
            $response_code = wp_remote_retrieve_response_code($response);
            $response_body = wp_remote_retrieve_body($response);
            
            if ($response_code === 200) {
                $data = json_decode($response_body, true);
                
                // Store connection ID
                update_option('wp_openwebui_connector_connection_id', $data['connection_id']);
                
                return array(
                    'success' => true,
                    'message' => __('Application password registered successfully', 'wp-openwebui-connector'),
                    'data' => $data
                );
            } else {
                return array(
                    'success' => false,
                    'message' => sprintf(__('Registration failed with status %d: %s', 'wp-openwebui-connector'), $response_code, $response_body)
                );
            }
            
        } catch (Exception $e) {
            return array(
                'success' => false,
                'message' => sprintf(__('Registration error: %s', 'wp-openwebui-connector'), $e->getMessage())
            );
        }
    }
    
    /**
     * Get WordPress posts for OpenWebUI
     */
    public function get_posts($args = array()) {
        $default_args = array(
            'post_type' => 'post',
            'post_status' => 'publish',
            'posts_per_page' => 10,
            'orderby' => 'date',
            'order' => 'DESC'
        );
        
        $args = wp_parse_args($args, $default_args);
        $posts = get_posts($args);
        
        $formatted_posts = array();
        foreach ($posts as $post) {
            $formatted_posts[] = array(
                'id' => $post->ID,
                'title' => $post->post_title,
                'content' => $post->post_content,
                'excerpt' => $post->post_excerpt,
                'status' => $post->post_status,
                'date' => $post->post_date,
                'modified' => $post->post_modified,
                'slug' => $post->post_name,
                'permalink' => get_permalink($post->ID),
                'author' => get_the_author_meta('display_name', $post->post_author),
                'categories' => wp_get_post_categories($post->ID, array('fields' => 'names')),
                'tags' => wp_get_post_tags($post->ID, array('fields' => 'names'))
            );
        }
        
        return $formatted_posts;
    }
    
    /**
     * Create or update WordPress post
     */
    public function create_or_update_post($post_data) {
        try {
            $post_args = array(
                'post_title' => sanitize_text_field($post_data['title'] ?? ''),
                'post_content' => wp_kses_post($post_data['content'] ?? ''),
                'post_excerpt' => sanitize_text_field($post_data['excerpt'] ?? ''),
                'post_status' => sanitize_text_field($post_data['status'] ?? 'draft'),
                'post_type' => sanitize_text_field($post_data['post_type'] ?? 'post'),
                'post_author' => get_current_user_id()
            );
            
            // If post ID is provided, update existing post
            if (isset($post_data['id']) && $post_data['id']) {
                $post_args['ID'] = intval($post_data['id']);
                $post_id = wp_update_post($post_args);
            } else {
                $post_id = wp_insert_post($post_args);
            }
            
            if (is_wp_error($post_id)) {
                return array(
                    'success' => false,
                    'message' => sprintf(__('Post creation/update failed: %s', 'wp-openwebui-connector'), $post_id->get_error_message())
                );
            }
            
            // Set categories
            if (isset($post_data['categories']) && is_array($post_data['categories'])) {
                wp_set_post_categories($post_id, $post_data['categories']);
            }
            
            // Set tags
            if (isset($post_data['tags']) && is_array($post_data['tags'])) {
                wp_set_post_tags($post_id, $post_data['tags']);
            }
            
            return array(
                'success' => true,
                'message' => __('Post created/updated successfully', 'wp-openwebui-connector'),
                'post_id' => $post_id,
                'permalink' => get_permalink($post_id)
            );
            
        } catch (Exception $e) {
            return array(
                'success' => false,
                'message' => sprintf(__('Post creation/update error: %s', 'wp-openwebui-connector'), $e->getMessage())
            );
        }
    }
    
    /**
     * Delete WordPress post
     */
    public function delete_post($post_id) {
        try {
            $post_id = intval($post_id);
            
            if (!$post_id) {
                return array(
                    'success' => false,
                    'message' => __('Invalid post ID', 'wp-openwebui-connector')
                );
            }
            
            $result = wp_delete_post($post_id, true);
            
            if ($result) {
                return array(
                    'success' => true,
                    'message' => __('Post deleted successfully', 'wp-openwebui-connector')
                );
            } else {
                return array(
                    'success' => false,
                    'message' => __('Failed to delete post', 'wp-openwebui-connector')
                );
            }
            
        } catch (Exception $e) {
            return array(
                'success' => false,
                'message' => sprintf(__('Post deletion error: %s', 'wp-openwebui-connector'), $e->getMessage())
            );
        }
    }
    
    /**
     * Get WordPress site information
     */
    public function get_site_info() {
        return array(
            'name' => get_bloginfo('name'),
            'description' => get_bloginfo('description'),
            'url' => home_url(),
            'admin_url' => admin_url(),
            'wp_version' => get_bloginfo('version'),
            'language' => get_bloginfo('language'),
            'charset' => get_bloginfo('charset'),
            'timezone' => get_option('timezone_string'),
            'date_format' => get_option('date_format'),
            'time_format' => get_option('time_format'),
            'users_can_register' => get_option('users_can_register'),
            'default_category' => get_option('default_category'),
            'posts_per_page' => get_option('posts_per_page')
        );
    }
}