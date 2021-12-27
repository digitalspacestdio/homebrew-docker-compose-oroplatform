#!/bin/bash
set -e
#set -x

cd /var/www

mkdir -p node_modules
chown linuxbrew:linuxbrew node_modules 2> /dev/null || true

mkdir -p vendor
chown linuxbrew:linuxbrew vendor 2> /dev/null || true

mkdir -p /var/www/.composer
chown linuxbrew:linuxbrew /var/www/.composer 2> /dev/null || true

mkdir -p /var/www/.npm
chown linuxbrew:linuxbrew /var/www/.npm 2> /dev/null || true

mkdir -p /var/www/var/cache
chown linuxbrew:linuxbrew /var/www/var/cache 2> /dev/null || true

if [[ -f /var/www/config/parameters.yml ]]; then
  sed -i 's/database_driver:.*/database_driver: '${ORO_DB_DRIVER}'/g' /var/www/config/parameters.yml
fi

echo "[$(date +'%F %T')] ==> Staring fpm"
HOME=/var/www su -p linuxbrew -c "exec /home/linuxbrew/.linuxbrew/sbin/php-fpm --nodaemonize --fpm-config /home/linuxbrew/.linuxbrew/etc/php/current/php-fpm.conf"
