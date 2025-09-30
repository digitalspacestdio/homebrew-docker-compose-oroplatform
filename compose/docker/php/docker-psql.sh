#!/bin/sh

exec sh -x -c "PGPASSWORD=$DC_ORO_DB_PASSWORD $(whereis -b psql | tr -s '[:blank:]' '\n' | grep -v 'psql:\|/usr/local/bin/psql' | head -1) -h $DC_ORO_DB_HOST -p $DC_ORO_DB_PORT -U $DC_ORO_DB_USER -d $DC_ORO_DB_DBNAME"