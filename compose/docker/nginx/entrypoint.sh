#!/bin/sh
set -e

# Replace APP_DIR placeholder
sed -i "s|/var/www|${APP_DIR:-'/var/www'}|g" /etc/nginx/nginx.conf

# Configure multisite functionality based on DC_NGINX_MULTISITE_PATH_ENABLE
if [ "${DC_NGINX_MULTISITE_PATH_ENABLE:-0}" = "1" ]; then
    echo "Enabling nginx multisite path functionality"
    # Multisite is enabled by default in nginx.conf, no changes needed
else
    echo "Disabling nginx multisite path functionality"
    # Disable multisite redirect and path extraction
    sed -i '/# Redirect single-segment URLs without trailing slash to with trailing slash/,/}/d' /etc/nginx/nginx.conf
    sed -i '/# Extract WEBSITE_CODE and WEBSITE_PATH from URL path/,/set \$website_path "\/";/c\
            # Multisite disabled - use default values\
            set $website_code "";\
            set $website_path "/";' /etc/nginx/nginx.conf
    sed -i '/# Extract first URL segment as WEBSITE_CODE/,/}/d' /etc/nginx/nginx.conf
fi

exec /docker-entrypoint.sh "$@"