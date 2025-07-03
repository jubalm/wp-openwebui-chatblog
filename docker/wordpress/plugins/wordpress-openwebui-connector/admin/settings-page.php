<?php

if (!defined('ABSPATH')) {
    exit;
}

$oauth_client = new WP_OpenWebUI_OAuth_Client();
$connection_status = $oauth_client->get_connection_status();
$is_connected = $oauth_client->is_connected();

?>

<div class="wrap">
    <h1><?php echo esc_html(get_admin_page_title()); ?></h1>
    
    <?php if (isset($_GET['connected']) && $_GET['connected'] === '1'): ?>
        <div class="notice notice-success is-dismissible">
            <p><?php _e('Successfully connected to OpenWebUI!', 'wp-openwebui-connector'); ?></p>
        </div>
    <?php endif; ?>
    
    <div class="wp-openwebui-connector-admin">
        
        <!-- Connection Status -->
        <div class="postbox">
            <h3 class="hndle"><?php _e('Connection Status', 'wp-openwebui-connector'); ?></h3>
            <div class="inside">
                <div class="wp-openwebui-status-indicator">
                    <span class="status-dot <?php echo $is_connected ? 'connected' : 'disconnected'; ?>"></span>
                    <strong><?php echo esc_html($connection_status['message']); ?></strong>
                </div>
                
                <?php if ($is_connected): ?>
                    <div class="connection-details">
                        <p><strong><?php _e('Connected at:', 'wp-openwebui-connector'); ?></strong> 
                           <?php echo date_i18n(get_option('date_format') . ' ' . get_option('time_format'), $connection_status['connected_at']); ?>
                        </p>
                        
                        <div class="connection-actions">
                            <button type="button" class="button" id="test-connection">
                                <?php _e('Test Connection', 'wp-openwebui-connector'); ?>
                            </button>
                            <button type="button" class="button button-secondary" id="disconnect-openwebui">
                                <?php _e('Disconnect', 'wp-openwebui-connector'); ?>
                            </button>
                        </div>
                    </div>
                <?php else: ?>
                    <div class="connection-setup">
                        <p><?php _e('You need to connect to OpenWebUI to enable WordPress integration.', 'wp-openwebui-connector'); ?></p>
                        
                        <?php if (get_option('wp_openwebui_connector_openwebui_url') && get_option('wp_openwebui_connector_client_id')): ?>
                            <button type="button" class="button button-primary" id="connect-openwebui">
                                <?php _e('Connect to OpenWebUI', 'wp-openwebui-connector'); ?>
                            </button>
                        <?php else: ?>
                            <p class="description"><?php _e('Please configure your OpenWebUI settings below first.', 'wp-openwebui-connector'); ?></p>
                        <?php endif; ?>
                    </div>
                <?php endif; ?>
            </div>
        </div>
        
        <!-- Settings Form -->
        <div class="postbox">
            <h3 class="hndle"><?php _e('Configuration', 'wp-openwebui-connector'); ?></h3>
            <div class="inside">
                <form method="post" action="options.php">
                    <?php
                    settings_fields('wp_openwebui_connector_settings_group');
                    do_settings_sections('wp_openwebui_connector_settings');
                    submit_button();
                    ?>
                </form>
            </div>
        </div>
        
        <!-- Application Password Setup -->
        <?php if ($is_connected): ?>
        <div class="postbox">
            <h3 class="hndle"><?php _e('Application Password Setup', 'wp-openwebui-connector'); ?></h3>
            <div class="inside">
                <div class="application-password-setup">
                    <h4><?php _e('Step 1: Generate Application Password', 'wp-openwebui-connector'); ?></h4>
                    <p><?php _e('Follow these steps to create an Application Password for OpenWebUI:', 'wp-openwebui-connector'); ?></p>
                    <ol>
                        <li><?php _e('Go to your WordPress profile page', 'wp-openwebui-connector'); ?> 
                            <a href="<?php echo admin_url('profile.php#application-passwords-section'); ?>" target="_blank"><?php _e('(click here)', 'wp-openwebui-connector'); ?></a>
                        </li>
                        <li><?php _e('Scroll down to the "Application Passwords" section', 'wp-openwebui-connector'); ?></li>
                        <li><?php _e('Enter "OpenWebUI Connector" as the application name', 'wp-openwebui-connector'); ?></li>
                        <li><?php _e('Click "Add New Application Password"', 'wp-openwebui-connector'); ?></li>
                        <li><?php _e('Copy the generated password and paste it below', 'wp-openwebui-connector'); ?></li>
                    </ol>
                    
                    <h4><?php _e('Step 2: Register Application Password', 'wp-openwebui-connector'); ?></h4>
                    <div class="application-password-form">
                        <label for="application-password"><?php _e('Application Password:', 'wp-openwebui-connector'); ?></label>
                        <input type="password" id="application-password" class="regular-text" placeholder="<?php _e('Paste your application password here', 'wp-openwebui-connector'); ?>" />
                        <button type="button" class="button button-primary" id="register-application-password">
                            <?php _e('Register Password', 'wp-openwebui-connector'); ?>
                        </button>
                    </div>
                    
                    <p class="description">
                        <?php _e('This password will be securely transmitted to OpenWebUI and encrypted for storage. It will never be visible in your browser or stored in plain text.', 'wp-openwebui-connector'); ?>
                    </p>
                </div>
            </div>
        </div>
        <?php endif; ?>
        
        <!-- Instructions -->
        <div class="postbox">
            <h3 class="hndle"><?php _e('Setup Instructions', 'wp-openwebui-connector'); ?></h3>
            <div class="inside">
                <div class="setup-instructions">
                    <h4><?php _e('How to Set Up the WordPress-OpenWebUI Integration', 'wp-openwebui-connector'); ?></h4>
                    
                    <div class="instruction-steps">
                        <div class="step">
                            <h5><?php _e('1. Configure OpenWebUI Settings', 'wp-openwebui-connector'); ?></h5>
                            <p><?php _e('Enter your OpenWebUI URL and OAuth2 credentials in the Configuration section above.', 'wp-openwebui-connector'); ?></p>
                        </div>
                        
                        <div class="step">
                            <h5><?php _e('2. Connect to OpenWebUI', 'wp-openwebui-connector'); ?></h5>
                            <p><?php _e('Click "Connect to OpenWebUI" to authenticate with your OpenWebUI instance via OAuth2.', 'wp-openwebui-connector'); ?></p>
                        </div>
                        
                        <div class="step">
                            <h5><?php _e('3. Generate Application Password', 'wp-openwebui-connector'); ?></h5>
                            <p><?php _e('Create a WordPress Application Password that will be used by OpenWebUI to access your WordPress site.', 'wp-openwebui-connector'); ?></p>
                        </div>
                        
                        <div class="step">
                            <h5><?php _e('4. Register Application Password', 'wp-openwebui-connector'); ?></h5>
                            <p><?php _e('Securely transmit the Application Password to OpenWebUI for storage and future use.', 'wp-openwebui-connector'); ?></p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Debug Information -->
        <div class="postbox">
            <h3 class="hndle"><?php _e('Debug Information', 'wp-openwebui-connector'); ?></h3>
            <div class="inside">
                <textarea readonly class="widefat" rows="10" id="debug-info"><?php
                    echo "WordPress OpenWebUI Connector Debug Information\n";
                    echo "=============================================\n\n";
                    echo "Plugin Version: " . WP_OPENWEBUI_CONNECTOR_VERSION . "\n";
                    echo "WordPress Version: " . get_bloginfo('version') . "\n";
                    echo "PHP Version: " . PHP_VERSION . "\n";
                    echo "Site URL: " . home_url() . "\n";
                    echo "Admin URL: " . admin_url() . "\n";
                    echo "OpenWebUI URL: " . get_option('wp_openwebui_connector_openwebui_url', 'Not set') . "\n";
                    echo "Client ID: " . (get_option('wp_openwebui_connector_client_id') ? 'Set' : 'Not set') . "\n";
                    echo "Client Secret: " . (get_option('wp_openwebui_connector_client_secret') ? 'Set' : 'Not set') . "\n";
                    echo "Connection Status: " . $connection_status['status'] . "\n";
                    echo "Connection ID: " . get_option('wp_openwebui_connector_connection_id', 'Not set') . "\n";
                    echo "Redirect URI: " . admin_url('options-general.php?page=wp-openwebui-connector&wp_openwebui_oauth_callback=1') . "\n";
                ?></textarea>
                <p class="description"><?php _e('Copy this information when reporting issues or requesting support.', 'wp-openwebui-connector'); ?></p>
            </div>
        </div>
        
    </div>
</div>

<style>
.wp-openwebui-connector-admin .postbox {
    margin-bottom: 20px;
}

.wp-openwebui-status-indicator {
    display: flex;
    align-items: center;
    margin-bottom: 15px;
}

.status-dot {
    width: 12px;
    height: 12px;
    border-radius: 50%;
    margin-right: 10px;
    display: inline-block;
}

.status-dot.connected {
    background-color: #46b450;
}

.status-dot.disconnected {
    background-color: #dc3232;
}

.connection-details, .connection-setup {
    background: #f7f7f7;
    padding: 15px;
    border-radius: 4px;
    margin-top: 15px;
}

.connection-actions {
    margin-top: 15px;
}

.connection-actions .button {
    margin-right: 10px;
}

.application-password-setup h4 {
    margin-top: 0;
    margin-bottom: 10px;
}

.application-password-setup ol {
    margin-left: 20px;
}

.application-password-form {
    margin: 15px 0;
    padding: 15px;
    background: #f7f7f7;
    border-radius: 4px;
}

.application-password-form label {
    display: block;
    margin-bottom: 5px;
    font-weight: bold;
}

.application-password-form input {
    margin-bottom: 10px;
}

.instruction-steps .step {
    margin-bottom: 20px;
    padding: 15px;
    background: #f7f7f7;
    border-radius: 4px;
}

.instruction-steps .step h5 {
    margin-top: 0;
    margin-bottom: 10px;
    color: #0073aa;
}

#debug-info {
    font-family: monospace;
    font-size: 12px;
    line-height: 1.4;
}
</style>