#!/bin/sh
set -e

# Replace APP_DIR placeholder
sed -i "s|/var/www|${APP_DIR:-'/var/www'}|g" /etc/nginx/nginx.conf

exec /docker-entrypoint.sh "$@"