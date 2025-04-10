#!/bin/bash
set -e

# OWNER_UID=$(stat -c '%u' /var/www)
# OWNER_GID=$(stat -c '%g' /var/www)

# usermod -u $nginx_uid -o www-data && groupmod -g $nginx_gid -o www-data

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- php-fpm "$@"
fi

if [[ -d "${APP_DIR:-/var/www}/.git" ]]; then
	git config --global --add safe.directory "${APP_DIR:-/var/www}/.git"
fi

exec docker-php-entrypoint "$@"