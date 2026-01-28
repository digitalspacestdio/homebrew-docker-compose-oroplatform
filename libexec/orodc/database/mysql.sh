#!/bin/bash
set -e
if [ "$DEBUG" ]; then set -x; fi

# Determine script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${SCRIPT_DIR}/../lib/ui.sh"
source "${SCRIPT_DIR}/../lib/environment.sh"

# Check that we're in a project
check_in_project || exit 1

# Execute mysql in database-cli container with all arguments passed through
exec ${DOCKER_COMPOSE_BIN_CMD} run -i --rm \
  -e MYSQL_PWD="$DC_ORO_DATABASE_PASSWORD" \
  database-cli \
  mysql \
  -h"$DC_ORO_DATABASE_HOST" \
  -P"$DC_ORO_DATABASE_PORT" \
  -u"$DC_ORO_DATABASE_USER" \
  "$DC_ORO_DATABASE_DBNAME" \
  "$@"
