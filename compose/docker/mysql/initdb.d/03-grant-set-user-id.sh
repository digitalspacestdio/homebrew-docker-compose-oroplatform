#!/bin/bash
# Grant SET_USER_ID privilege to app user for importing dumps with DEFINER clauses
# (triggers, views, stored procedures, events)
# MySQL 8.0+ uses SET_USER_ID; 5.7 uses SUPER
set -e
version=$(mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -sN -e "SELECT @@version;" 2>/dev/null || echo "0")
major=${version%%.*}
if [[ "$major" -ge 8 ]]; then
  mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e \
    "GRANT SET_USER_ID ON *.* TO '${MYSQL_USER}'@'%'; FLUSH PRIVILEGES;"
else
  mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e \
    "GRANT SUPER ON *.* TO '${MYSQL_USER}'@'%'; FLUSH PRIVILEGES;"
fi
