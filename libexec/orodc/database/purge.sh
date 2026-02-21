#!/bin/bash
set -e
if [ "$DEBUG" ]; then set -x; fi

# Determine script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${SCRIPT_DIR}/../lib/ui.sh"
source "${SCRIPT_DIR}/../lib/environment.sh"

# Check that we're in a project
# Note: initialize_environment is called by router (bin/orodc) before routing to this script
check_in_project || exit 1

# Recreate database container with volumes removal
if [[ -z "${DC_ORO_DATABASE_SCHEMA:-}" ]]; then
  msg_error "Database schema not configured"
  echo "" >&2
  msg_info "To fix this issue, you can:" >&2
  echo "  1. Set DC_ORO_DATABASE_SCHEMA in .env.orodc (e.g., DC_ORO_DATABASE_SCHEMA=postgres or DC_ORO_DATABASE_SCHEMA=mysql)" >&2
  echo "  2. Set DC_ORO_DATABASE_PORT in .env.orodc (e.g., DC_ORO_DATABASE_PORT=5432 for PostgreSQL or 3306 for MySQL)" >&2
  echo "  3. Set ORO_DB_URL in .env-app or .env-app.local (e.g., postgres://user:pass@host:5432/db)" >&2
  echo "" >&2
  exit 1
fi

db_name="${DC_ORO_DATABASE_DBNAME:-oro_db}"

# Ensure database connection variables are exported with defaults.
# These may not be set in the host shell (only in Docker Compose interpolation),
# so export them to guarantee correct values when eval expands $VAR references.
export DC_ORO_DATABASE_HOST="${DC_ORO_DATABASE_HOST:-database}"
export DC_ORO_DATABASE_PORT="${DC_ORO_DATABASE_PORT:-$([ "${DC_ORO_DATABASE_SCHEMA}" = "mysql" ] && echo 3306 || echo 5432)}"
export DC_ORO_DATABASE_USER="${DC_ORO_DATABASE_USER:-oro_db_user}"
export DC_ORO_DATABASE_PASSWORD="${DC_ORO_DATABASE_PASSWORD:-oro_db_pass}"
export DC_ORO_DATABASE_DBNAME="${DC_ORO_DATABASE_DBNAME:-${db_name}}"

echo "" >&2
msg_danger "This will DELETE ALL DATA in database '${db_name}'!"
if ! confirm_yes_no "Continue?"; then
  msg_info "Operation cancelled"
  exit 0
fi

# Stop and remove database container with volumes using docker compose
stop_rm_cmd="${DOCKER_COMPOSE_BIN_CMD} stop database >/dev/null 2>&1 && ${DOCKER_COMPOSE_BIN_CMD} rm -f database >/dev/null 2>&1 || true"
run_with_spinner "Stopping and removing database container" "$stop_rm_cmd" || true

# Remove database volumes
# Docker Compose doesn't support removing specific volumes directly
# We need to use docker volume rm, but we'll use the volume name that docker compose creates
if [[ "${DC_ORO_DATABASE_SCHEMA}" == "postgres" ]]; then
  volume_name="${DC_ORO_NAME:-}_postgresql-data"
  # Remove volume - docker compose doesn't have volume rm command, so we use docker directly
  # but with the volume name that docker compose creates
  run_with_spinner "Removing database volumes" "docker volume rm \"${volume_name}\" 2>/dev/null || true" || true
elif [[ "${DC_ORO_DATABASE_SCHEMA}" == "mysql" ]]; then
  volume_name="${DC_ORO_NAME:-}_mysql-data"
  run_with_spinner "Removing database volumes" "docker volume rm \"${volume_name}\" 2>/dev/null || true" || true
fi

# Recreate database container
recreate_db_cmd="${DOCKER_COMPOSE_BIN_CMD} up -d database"
run_with_spinner "Recreating database container" "$recreate_db_cmd" || exit $?

# MySQL needs --profile run-only for database-cli
db_cli_cmd="${DOCKER_COMPOSE_BIN_CMD}"
if [[ "${DC_ORO_DATABASE_SCHEMA}" == "mysql" ]] && [[ "$DOCKER_COMPOSE_BIN_CMD" != *"run-only"* ]]; then
  db_cli_cmd="${DOCKER_COMPOSE_BIN_CMD} --profile run-only"
fi

# Wait for database to be ready and the specific database to exist (max 120s to avoid infinite hang)
if [[ "${DC_ORO_DATABASE_SCHEMA}" == "postgres" ]]; then
  wait_server_cmd="${db_cli_cmd} run --rm database-cli bash -c \"until PGPASSWORD=\\\$DC_ORO_DATABASE_PASSWORD psql -h \\\$DC_ORO_DATABASE_HOST -p \\\$DC_ORO_DATABASE_PORT -U \\\$DC_ORO_DATABASE_USER -d postgres -c 'SELECT 1' >/dev/null 2>&1; do sleep 1; done\""
  run_with_spinner "Waiting for PostgreSQL server" "$wait_server_cmd" || exit $?
  wait_db_cmd="${db_cli_cmd} run --rm database-cli bash -c \"until PGPASSWORD=\\\$DC_ORO_DATABASE_PASSWORD psql -h \\\$DC_ORO_DATABASE_HOST -p \\\$DC_ORO_DATABASE_PORT -U \\\$DC_ORO_DATABASE_USER -d ${db_name} -c 'SELECT 1' >/dev/null 2>&1; do sleep 1; done\""
elif [[ "${DC_ORO_DATABASE_SCHEMA}" == "mysql" ]]; then
  wait_server_cmd="${db_cli_cmd} run --rm database-cli bash -c \"for i in \\\$(seq 1 120); do MYSQL_PWD=\\\$DC_ORO_DATABASE_PASSWORD mysqladmin -h \\\$DC_ORO_DATABASE_HOST -P \\\$DC_ORO_DATABASE_PORT -u \\\$DC_ORO_DATABASE_USER ping 2>/dev/null && exit 0; sleep 1; done; echo 'Timeout: MySQL server not ready after 120s' >&2; exit 1\""
  run_with_spinner "Waiting for MySQL server" "$wait_server_cmd" || exit $?
  wait_db_cmd="${db_cli_cmd} run --rm database-cli bash -c \"for i in \\\$(seq 1 120); do MYSQL_PWD=\\\$DC_ORO_DATABASE_PASSWORD mysql -h \\\$DC_ORO_DATABASE_HOST -P \\\$DC_ORO_DATABASE_PORT -u \\\$DC_ORO_DATABASE_USER -e 'USE ${db_name}; SELECT 1' 2>/dev/null && exit 0; sleep 1; done; echo 'Timeout: database ${db_name} not ready after 120s. Last error:' >&2; MYSQL_PWD=\\\$DC_ORO_DATABASE_PASSWORD mysql -h \\\$DC_ORO_DATABASE_HOST -P \\\$DC_ORO_DATABASE_PORT -u \\\$DC_ORO_DATABASE_USER -e 'USE ${db_name}; SELECT 1' 2>&1; exit 1\""
else
  msg_error "Unknown database schema: ${DC_ORO_DATABASE_SCHEMA}"
  exit 1
fi

run_with_spinner "Waiting for database '${db_name}'" "$wait_db_cmd" || exit $?

msg_ok "Database container recreated successfully"
echo "" >&2

exit 0
