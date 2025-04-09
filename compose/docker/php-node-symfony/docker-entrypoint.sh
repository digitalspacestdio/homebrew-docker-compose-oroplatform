#!/bin/bash
set -e

# OWNER_UID=$(stat -c '%u' /var/www)
# OWNER_GID=$(stat -c '%g' /var/www)

# usermod -u $nginx_uid -o www-data && groupmod -g $nginx_gid -o www-data

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- php-fpm "$@"
fi

chmod 0777 ${APP_DIR:-/var/www}

exec docker-php-entrypoint "$@"