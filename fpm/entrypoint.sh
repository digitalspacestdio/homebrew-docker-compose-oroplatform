#!/bin/bash
set -e
set -x

cd /var/www
mkdir -p /var/www/.composer
mkdir -p /var/www/.npm

#echo "[$(date +'%F %T')] ==> Clearing the cache"
#NO_DOCKER=true make cache
#

chown linuxbrew:linuxbrew node_modules
chown linuxbrew:linuxbrew vendor
chown linuxbrew:linuxbrew /var/www/.composer
chown linuxbrew:linuxbrew /var/www/.npm
chown linuxbrew:linuxbrew /var/www/var/cache

#echo "[$(date +'%F %T')] ==> Installing vendors"
su -p linuxbrew -c "cd $(pwd); HOME=/var/www composer install --optimize-autoloader --no-progress --dev --no-interaction"

#
#echo "[$(date +'%F %T')] ==> Verify Installation"
#bin/console pim:installer:check-requirements
#
#echo "[$(date +'%F %T')] ==> Clearing the cache"
#NO_DOCKER=true make cache
#
#echo "[$(date +'%F %T')] ==> Build frontend"
#NO_DOCKER=true make upgrade-front
#
#echo "[$(date +'%F %T')] ==> Apply migration"
#bin/console doctrine:migrations:migrate
#
#cd /var/www
su -p linuxbrew -c "cd $(pwd); exec /home/linuxbrew/.linuxbrew/sbin/php-fpm --nodaemonize --fpm-config /home/linuxbrew/.linuxbrew/etc/php/current/php-fpm.conf"
