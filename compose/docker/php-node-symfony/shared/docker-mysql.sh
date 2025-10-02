#!/bin/sh

exec sh -x -c "MYSQL_PWD=$DC_ORO_DB_PASSWORD $(whereis -b mysql | tr -s '[:blank:]' '\n' | grep -v 'mysql:\|/usr/local/bin/mysql' | head -1) -h$DC_ORO_DB_HOST -P$DC_ORO_DB_PORT -u$DC_ORO_DB_USER $DC_ORO_DB_DBNAME"