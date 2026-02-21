#!/bin/sh

exec sh -x -c "MYSQL_PWD=$DC_ORO_DATABASE_PASSWORD $(whereis -b mysql | tr -s '[:blank:]' '\n' | grep -v 'mysql:\|/usr/local/bin/mysql' | head -1) -h$DC_ORO_DATABASE_HOST -P$DC_ORO_DATABASE_PORT -u$DC_ORO_DATABASE_USER $DC_ORO_DATABASE_DBNAME"