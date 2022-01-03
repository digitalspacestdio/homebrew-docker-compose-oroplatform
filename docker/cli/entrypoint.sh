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

for i in "$@"; do
    i="${i//\\/\\\\}"
    i="${i//$/\\$}"
    C="$C \"${i//\"/\\\"}\""
done

HOME=/home/linuxbrew su -p linuxbrew -- -c "exec $C"
