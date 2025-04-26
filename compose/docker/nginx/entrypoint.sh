#!/bin/sh
set -e

sed -i "s|/var/www|${APP_DIR:-'/var/www'}|g" /etc/nginx/nginx.conf

exec /docker-entrypoint.sh "$@"