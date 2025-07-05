# WordPress Configuration Template for Tenant: ${tenant_id}

# PHP Configuration
php_admin_value[date.timezone] = ${timezone}
php_admin_value[memory_limit] = 256M
php_admin_value[max_execution_time] = 300
php_admin_value[upload_max_filesize] = 64M
php_admin_value[post_max_size] = 64M

# WordPress Debug Settings
%{ if debug_mode }
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', false);
define('SCRIPT_DEBUG', true);
%{ else }
define('WP_DEBUG', false);
define('WP_DEBUG_LOG', false);
define('WP_DEBUG_DISPLAY', false);
%{ endif }

# WordPress Auto-Update Settings
%{ if auto_updates }
define('WP_AUTO_UPDATE_CORE', true);
define('AUTOMATIC_UPDATER_DISABLED', false);
%{ else }
define('WP_AUTO_UPDATE_CORE', false);
define('AUTOMATIC_UPDATER_DISABLED', true);
%{ endif }

# WordPress Language
define('WPLANG', '${language}');

# Security Headers
header('X-Frame-Options: SAMEORIGIN');
header('X-Content-Type-Options: nosniff');
header('X-XSS-Protection: 1; mode=block');
header('Referrer-Policy: strict-origin-when-cross-origin');

# Content Security Policy
header("Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' https:; connect-src 'self' https:;");

# Cache Settings
define('WP_CACHE', true);
define('CACHE_EXPIRATION_TIME', 3600);

# Multisite Settings (disabled for tenant isolation)
define('WP_ALLOW_MULTISITE', false);

# File Permissions
define('FS_CHMOD_DIR', (0755 & ~ umask()));
define('FS_CHMOD_FILE', (0644 & ~ umask()));

# WordPress Salts and Keys
# Note: These should be generated uniquely per tenant
define('AUTH_KEY',         'tenant-${tenant_id}-auth-key');
define('SECURE_AUTH_KEY',  'tenant-${tenant_id}-secure-auth-key');
define('LOGGED_IN_KEY',    'tenant-${tenant_id}-logged-in-key');
define('NONCE_KEY',        'tenant-${tenant_id}-nonce-key');
define('AUTH_SALT',        'tenant-${tenant_id}-auth-salt');
define('SECURE_AUTH_SALT', 'tenant-${tenant_id}-secure-auth-salt');
define('LOGGED_IN_SALT',   'tenant-${tenant_id}-logged-in-salt');
define('NONCE_SALT',       'tenant-${tenant_id}-nonce-salt');

# Tenant-specific constants
define('TENANT_ID', '${tenant_id}');
define('TENANT_NAMESPACE', '${tenant_id}');

# Content Automation Settings
define('CONTENT_AUTOMATION_ENABLED', true);
define('PIPELINE_SERVICE_URL', 'http://wordpress-oauth-pipeline.admin-apps.svc.cluster.local:9099');

# OAuth2 Settings
define('OAUTH2_ENABLED', true);
define('OAUTH2_CLIENT_ID', 'wordpress-${tenant_id}');

# WordPress Table Prefix (tenant-specific)
$table_prefix = 'wp_${tenant_id}_';

# That's all, stop editing! Happy publishing.