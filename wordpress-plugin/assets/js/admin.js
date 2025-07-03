jQuery(document).ready(function($) {
    
    // Connect to OpenWebUI
    $('#connect-openwebui').on('click', function() {
        var $button = $(this);
        var originalText = $button.text();
        
        $button.text(wpOpenWebUIConnector.strings.connecting).prop('disabled', true);
        
        // Get OAuth authorization URL and redirect
        var authUrl = wpOpenWebUIConnector.authUrl || buildAuthUrl();
        window.location.href = authUrl;
    });
    
    // Disconnect from OpenWebUI
    $('#disconnect-openwebui').on('click', function() {
        if (!confirm('Are you sure you want to disconnect from OpenWebUI?')) {
            return;
        }
        
        var $button = $(this);
        var originalText = $button.text();
        
        $button.text(wpOpenWebUIConnector.strings.disconnecting).prop('disabled', true);
        
        $.ajax({
            url: wpOpenWebUIConnector.ajaxurl,
            type: 'POST',
            data: {
                action: 'wp_openwebui_disconnect',
                nonce: wpOpenWebUIConnector.nonce
            },
            success: function(response) {
                if (response.success) {
                    showNotice(response.data.message, 'success');
                    location.reload();
                } else {
                    showNotice(response.data.message || wpOpenWebUIConnector.strings.error, 'error');
                }
            },
            error: function() {
                showNotice(wpOpenWebUIConnector.strings.error, 'error');
            },
            complete: function() {
                $button.text(originalText).prop('disabled', false);
            }
        });
    });
    
    // Test connection
    $('#test-connection').on('click', function() {
        var $button = $(this);
        var originalText = $button.text();
        
        $button.text(wpOpenWebUIConnector.strings.testing).prop('disabled', true);
        
        $.ajax({
            url: wpOpenWebUIConnector.ajaxurl,
            type: 'POST',
            data: {
                action: 'wp_openwebui_test_connection',
                nonce: wpOpenWebUIConnector.nonce
            },
            success: function(response) {
                if (response.success) {
                    showNotice(wpOpenWebUIConnector.strings.test_success, 'success');
                } else {
                    showNotice(response.data.message || wpOpenWebUIConnector.strings.test_failed, 'error');
                }
            },
            error: function() {
                showNotice(wpOpenWebUIConnector.strings.test_failed, 'error');
            },
            complete: function() {
                $button.text(originalText).prop('disabled', false);
            }
        });
    });
    
    // Register application password
    $('#register-application-password').on('click', function() {
        var $button = $(this);
        var $input = $('#application-password');
        var password = $input.val().trim();
        
        if (!password) {
            showNotice('Please enter an application password', 'error');
            $input.focus();
            return;
        }
        
        if (!confirm('Are you sure you want to register this application password with OpenWebUI?')) {
            return;
        }
        
        var originalText = $button.text();
        $button.text('Registering...').prop('disabled', true);
        $input.prop('disabled', true);
        
        $.ajax({
            url: wpOpenWebUIConnector.ajaxurl,
            type: 'POST',
            data: {
                action: 'wp_openwebui_register_password',
                nonce: wpOpenWebUIConnector.nonce,
                application_password: password
            },
            success: function(response) {
                if (response.success) {
                    showNotice('Application password registered successfully!', 'success');
                    $input.val(''); // Clear the password field
                } else {
                    showNotice(response.data.message || 'Failed to register application password', 'error');
                }
            },
            error: function() {
                showNotice('Failed to register application password', 'error');
            },
            complete: function() {
                $button.text(originalText).prop('disabled', false);
                $input.prop('disabled', false);
            }
        });
    });
    
    // Show/hide application password
    $('#application-password').on('focus', function() {
        $(this).attr('type', 'text');
    }).on('blur', function() {
        if (!$(this).val()) {
            $(this).attr('type', 'password');
        }
    });
    
    // Auto-save settings when changed
    $('#openwebui_url, #client_id, #client_secret').on('change', function() {
        updateConnectButtonState();
    });
    
    function updateConnectButtonState() {
        var openwebuiUrl = $('#openwebui_url').val().trim();
        var clientId = $('#client_id').val().trim();
        var $connectButton = $('#connect-openwebui');
        
        if (openwebuiUrl && clientId) {
            $connectButton.prop('disabled', false);
        } else {
            $connectButton.prop('disabled', true);
        }
    }
    
    function buildAuthUrl() {
        var openwebuiUrl = $('#openwebui_url').val().trim();
        var clientId = $('#client_id').val().trim();
        
        if (!openwebuiUrl || !clientId) {
            showNotice('Please configure OpenWebUI URL and Client ID first', 'error');
            return '#';
        }
        
        var params = new URLSearchParams({
            response_type: 'code',
            client_id: clientId,
            redirect_uri: window.location.origin + window.location.pathname + '?page=wp-openwebui-connector&wp_openwebui_oauth_callback=1',
            scope: 'openid profile email',
            state: 'oauth_state_' + Date.now(),
            site_url: window.location.origin,
            site_name: document.title
        });
        
        return openwebuiUrl.replace(/\/$/, '') + '/api/wordpress/oauth/authorize?' + params.toString();
    }
    
    function showNotice(message, type) {
        // Remove existing notices
        $('.wp-openwebui-notice').remove();
        
        var noticeClass = type === 'success' ? 'notice-success' : 'notice-error';
        var notice = $('<div class="notice ' + noticeClass + ' is-dismissible wp-openwebui-notice"><p>' + message + '</p></div>');
        
        $('.wp-openwebui-connector-admin').prepend(notice);
        
        // Make notice dismissible
        notice.on('click', '.notice-dismiss', function() {
            notice.fadeOut();
        });
        
        // Auto-dismiss success notices after 5 seconds
        if (type === 'success') {
            setTimeout(function() {
                notice.fadeOut();
            }, 5000);
        }
        
        // Scroll to top to show notice
        $('html, body').animate({
            scrollTop: notice.offset().top - 50
        }, 500);
    }
    
    // Handle OAuth callback
    var urlParams = new URLSearchParams(window.location.search);
    if (urlParams.get('wp_openwebui_oauth_callback')) {
        if (urlParams.get('error')) {
            var error = urlParams.get('error');
            var errorDescription = urlParams.get('error_description') || '';
            showNotice('OAuth error: ' + error + ' - ' + errorDescription, 'error');
        } else if (urlParams.get('code')) {
            // Handle successful OAuth callback
            showNotice('Processing OAuth callback...', 'info');
            
            $.ajax({
                url: wpOpenWebUIConnector.ajaxurl,
                type: 'POST',
                data: {
                    action: 'wp_openwebui_oauth_callback',
                    nonce: wpOpenWebUIConnector.nonce,
                    code: urlParams.get('code'),
                    state: urlParams.get('state')
                },
                success: function(response) {
                    if (response.success) {
                        showNotice(response.data.message || wpOpenWebUIConnector.strings.connected, 'success');
                        if (response.data.redirect) {
                            setTimeout(function() {
                                window.location.href = response.data.redirect;
                            }, 2000);
                        } else {
                            location.reload();
                        }
                    } else {
                        showNotice(response.data.message || wpOpenWebUIConnector.strings.error, 'error');
                    }
                },
                error: function() {
                    showNotice(wpOpenWebUIConnector.strings.error, 'error');
                }
            });
        }
        
        // Clean up URL
        var cleanUrl = window.location.pathname + '?page=wp-openwebui-connector';
        window.history.replaceState({}, document.title, cleanUrl);
    }
    
    // Initialize button states
    updateConnectButtonState();
    
    // Copy debug info to clipboard
    $('#debug-info').on('click', function() {
        this.select();
        document.execCommand('copy');
        showNotice('Debug information copied to clipboard', 'success');
    });
    
});