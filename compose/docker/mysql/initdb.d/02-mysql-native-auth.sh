#!/bin/bash
# Switch app user to mysql_native_password for compatibility with MariaDB client
# (PHP container uses Alpine mysql-client = mariadb-client which lacks caching_sha2_password)
# Only for MySQL 8.x (5.7=default; 9.x=plugin removed)
set -e
version=$(mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -sN -e "SELECT @@version;" 2>/dev/null || echo "0")
major=${version%%.*}
if [[ "$major" -ge 8 && "$major" -lt 9 ]]; then
  mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e \
    "ALTER USER '${MYSQL_USER}'@'%' IDENTIFIED WITH mysql_native_password BY '${MYSQL_PASSWORD}'; FLUSH PRIVILEGES;"
fi
