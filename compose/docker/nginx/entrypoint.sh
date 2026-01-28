#!/bin/sh
set -e

# Select nginx config based on DC_ORO_NGINX_CONFIG env var
# Options: universal (default), legacy
NGINX_CONFIG="${DC_ORO_NGINX_CONFIG:-universal}"

if [ "$NGINX_CONFIG" = "legacy" ]; then
    echo "[nginx] Using legacy Oro-specific config"
    cp /etc/nginx/nginx-legacy.conf /etc/nginx/nginx.conf
else
    echo "[nginx] Using universal multi-framework config"
    cp /etc/nginx/nginx-universal.conf /etc/nginx/nginx.conf
fi

# Replace APP_DIR placeholder with actual path
APP_DIR="${APP_DIR:-/var/www}"
sed -i "s|/var/www|${APP_DIR}|g" /etc/nginx/nginx.conf

echo "[nginx] APP_DIR: ${APP_DIR}"
echo "[nginx] Document root auto-detection: public/ > web/ > pub/ > root"
echo "[nginx] Config: ${NGINX_CONFIG}"

exec /docker-entrypoint.sh "$@"
