# WordPress Plugins

This directory contains WordPress plugins that are automatically installed and activated when the WordPress Docker container starts.

## Included Plugins

### wordpress-openwebui-connector/
**WordPress OpenWebUI Connector Plugin**

A secure OAuth2-based integration that allows OpenWebUI to interact with WordPress using Application Passwords.

**Features:**
- OAuth2 client implementation for connecting to OpenWebUI
- Secure Application Password registration workflow
- Admin interface for connection management
- Connection status monitoring and testing
- Automatic plugin activation on container startup

**Usage:**
1. The plugin is automatically installed and activated
2. Go to **Settings → OpenWebUI Connector** in WordPress admin
3. Configure OAuth2 settings (Client ID, Client Secret, OpenWebUI URL)
4. Connect to OpenWebUI via OAuth2 flow
5. Register WordPress Application Password for API access

**Security:**
- Application Passwords never exposed client-side
- OAuth2 authentication flow with Authentik
- Secure server-to-server communication
- HTTPS-only connections

For detailed setup instructions, see: `docs/5.WORDPRESS_OPENWEBUI_INTEGRATION_README.md`

## Plugin Development

When developing plugins for this WordPress setup:

1. **Add plugin directory** to `docker/wordpress/plugins/`
2. **Update Dockerfile** to copy the plugin:
   ```dockerfile
   COPY plugins/your-plugin-name /build/your-plugin-name
   COPY --from=build /build/your-plugin-name /usr/src/wordpress/wp-content/plugins/your-plugin-name
   ```
3. **Update wp-entrypoint.sh** to activate the plugin:
   ```bash
   if wp --allow-root --path="/var/www/html" plugin list --name=your-plugin-name --status=inactive 2>/dev/null | grep -q your-plugin-name; then
       wp --allow-root --path="/var/www/html" plugin activate your-plugin-name
       echo "your-plugin-name plugin activated!"
   fi
   ```
4. **Rebuild Docker image** to include the new plugin

This ensures plugins are automatically installed and activated in all WordPress instances deployed via this PaaS platform.