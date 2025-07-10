# Stage 1: Build Stage
FROM php:8.2-cli AS build

# Install necessary tools for building plugins and mysql-client in one step, then clean up
RUN apt-get update && apt-get install -y --no-install-recommends \
  git curl unzip default-mysql-client libedit2 && \
  rm -rf /var/lib/apt/lists/*

# Ensure the /build/tools directory exists before downloading wp-cli
RUN mkdir -p /build/tools && \
  curl -L -o /build/tools/wp https://github.com/wp-cli/wp-cli/releases/download/v2.8.1/wp-cli-2.8.1.phar

# Define ARG variables for plugin download links
ARG WORDPRESS_MCP=https://github.com/Automattic/wordpress-mcp/releases/download/v0.2.2/wordpress-mcp.zip
ARG OPENID_CONNECT=https://github.com/oidc-wp/openid-connect-generic/archive/refs/tags/3.10.0.tar.gz
ARG SQLITE_INTEGRATION=https://downloads.wordpress.org/plugin/sqlite-database-integration.2.1.11.zip

# Download and prepare WordPress MCP plugin
RUN mkdir -p /build/wordpress-mcp && \
  curl -L -o /tmp/wordpress-mcp.zip $WORDPRESS_MCP && \
  unzip /tmp/wordpress-mcp.zip -d /tmp && \
  mv /tmp/wordpress-mcp/* /build/wordpress-mcp

# Download and prepare OpenID Connect Generic plugin
RUN curl -L -o /tmp/openid-connect-generic.tar.gz $OPENID_CONNECT && \
  mkdir -p /build/openid-connect-generic && \
  tar -xzf /tmp/openid-connect-generic.tar.gz --strip-components=1 -C /build/openid-connect-generic

# Download and prepare SQLite Database Integration plugin
RUN mkdir -p /build/sqlite-database-integration && \
  curl -L -o /tmp/sqlite-integration.zip $SQLITE_INTEGRATION && \
  unzip /tmp/sqlite-integration.zip -d /tmp && \
  mv /tmp/sqlite-database-integration/* /build/sqlite-database-integration

# Copy WordPress-OpenWebUI Connector plugin from local source
COPY plugins/wordpress-openwebui-connector /build/wordpress-openwebui-connector

# Stage 2: Runtime Stage
FROM wordpress:php8.2-apache

# Install network utilities for debugging
RUN apt-get update && apt-get install -y --no-install-recommends iputils-ping netcat-traditional libedit-dev libncurses5 libtinfo5 && \
  rm -rf /var/lib/apt/lists/*

# Copy prepared plugins from build stage
COPY --from=build /build/wordpress-mcp /usr/src/wordpress/wp-content/plugins/wordpress-mcp
COPY --from=build /build/openid-connect-generic /usr/src/wordpress/wp-content/plugins/openid-connect-generic
COPY --from=build /build/sqlite-database-integration /usr/src/wordpress/wp-content/plugins/sqlite-database-integration
COPY --from=build /build/wordpress-openwebui-connector /usr/src/wordpress/wp-content/plugins/wordpress-openwebui-connector

# Copy mysql-client binaries from build stage
COPY --from=build /usr/bin/mysql* /usr/bin/

# Copy wp-cli from build stage
COPY --from=build /build/tools/wp /usr/local/bin/wp


# Set permissions for wp-cli and plugins directory
RUN chmod +x /usr/local/bin/wp && \
  chown -R www-data:www-data /usr/src/wordpress/wp-content/plugins && \
  chmod -R 755 /usr/src/wordpress/wp-content/plugins

# Copy wp-sqlite-db drop-in for SQLite database support
COPY db.php /usr/src/wordpress/wp-content/db.php

# Copy custom entrypoint script
COPY wp-entrypoint.sh /usr/local/bin/wp-entrypoint.sh
RUN chmod +x /usr/local/bin/wp-entrypoint.sh

# Use custom entrypoint
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ENTRYPOINT ["/usr/local/bin/wp-entrypoint.sh"]
CMD ["apache2-foreground"]
