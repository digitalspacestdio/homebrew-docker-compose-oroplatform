#!/bin/bash
set -e
#set -x

cd /var/www

chown linuxbrew:linuxbrew /var/www 2> /dev/null || true
chown linuxbrew:linuxbrew /home/linuxbrew/.composer 2> /dev/null || true
chown linuxbrew:linuxbrew /home/linuxbrew/.npm 2> /dev/null || true

#if [[ -f /var/www/config/parameters.yml ]]; then
#  sed -i 's/database_driver:.*/database_driver: '${ORO_DB_DRIVER}'/g' /var/www/config/parameters.yml
#fi

echo "[$(date +'%F %T')] ==> Staring fpm"
HOME=/home/linuxbrew su -p linuxbrew -c "exec /home/linuxbrew/.linuxbrew/sbin/php-fpm --nodaemonize --fpm-config /home/linuxbrew/.linuxbrew/etc/php/current/php-fpm.conf"
