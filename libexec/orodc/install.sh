#!/bin/bash
set -e
if [ "$DEBUG" ]; then set -x; fi

# Determine script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/ui.sh"
source "${SCRIPT_DIR}/lib/environment.sh"

# Check that we're in a project
# Note: initialize_environment is called by router (bin/orodc) before routing to this script
check_in_project || exit 1

# Run post-install scripts via composer
run_post_install_scripts() {
  local composer_file="${DC_ORO_APPDIR}/composer.json"
  
  if [[ ! -f "$composer_file" ]]; then
    msg_warning "composer.json not found, skipping post-install scripts"
    return 0
  fi
  
  # Check if post-install-cmd exists in composer.json
  local has_post_install=false
  if command -v jq >/dev/null 2>&1; then
    if jq -e '.scripts."post-install-cmd"?' "$composer_file" >/dev/null 2>&1; then
      has_post_install=true
    fi
  else
    if grep -q '"post-install-cmd"' "$composer_file" 2>/dev/null; then
      has_post_install=true
    fi
  fi
  
  if [[ "$has_post_install" == "false" ]]; then
    msg_info "No post-install scripts found in composer.json"
    return 0
  fi
  
  # Run all post-install scripts via composer
  local script_cmd="${DOCKER_COMPOSE_BIN_CMD} run --rm -T cli bash -c \"composer run-script --no-interaction post-install-cmd\""
  
  if ! run_with_spinner "Executing post-install scripts" "$script_cmd"; then
    msg_error "Post-install scripts failed"
    return 1
  fi
  
  return 0
}

# Disable XDebug for installation
export XDEBUG_MODE=off

# Determine if installing with or without demo data
SAMPLE_DATA="y"  # Default: with demo data
INSTALL_MSG="Installing Application with sample data"

# Check first argument for "without demo" variant
if [[ "$1" == "without" ]] && [[ "$2" == "demo" ]]; then
  SAMPLE_DATA="n"
  INSTALL_MSG="Installing Application without demo data"
  shift 2
elif [[ "$*" =~ without.*demo ]]; then
  SAMPLE_DATA="n"
  INSTALL_MSG="Installing Application without demo data"
fi

# Get previous timing for statistics only
prev_install_timing=$(get_previous_timing "install")

# Record start time for full install
install_start_time=$(date +%s)

# Ensure database host is set to container name, not localhost
# This prevents "No such file or directory" error (2002) when MySQL tries to use Unix socket
if [[ "${DC_ORO_DATABASE_HOST:-database}" == "localhost" ]] || [[ "${DC_ORO_DATABASE_HOST:-database}" == "127.0.0.1" ]]; then
  export DC_ORO_DATABASE_HOST="database"
  msg_warning "DC_ORO_DATABASE_HOST was set to localhost/127.0.0.1, changed to 'database' for container networking"
fi

msg_info "Starting installation process..."

# Build project images first (if needed) to avoid showing build output during run commands
services_to_build="fpm cli ssh"

# Check if websocket service exists (Oro projects only) and add to build list
if ${DOCKER_COMPOSE_BIN_CMD} config --services 2>/dev/null | grep -q "^websocket$"; then
  services_to_build="${services_to_build} websocket"
fi

# Check if consumer service exists and add it to build list
if ${DOCKER_COMPOSE_BIN_CMD} config --services 2>/dev/null | grep -q "^consumer$"; then
  services_to_build="${services_to_build} consumer"
fi

build_cmd="${DOCKER_COMPOSE_BIN_CMD} build ${services_to_build}"
run_with_spinner "Building project images" "$build_cmd" || true
msg_info ""

# Recreate database container with volumes removal (with user confirmation)
if [[ -n "${DC_ORO_DATABASE_SCHEMA:-}" ]]; then
  db_name="${DC_ORO_DATABASE_DBNAME:-oro_db}"
  echo "" >&2
  msg_danger "This will DELETE ALL DATA in database '${db_name}'!"
  msg_danger "OroPlatform requires an empty database for installation."
  if ! confirm_yes_no "Continue?"; then
    msg_error "Installation cancelled. Database must be empty to install OroPlatform."
    exit 1
  fi
    # Stop and remove database container using docker compose
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
    
    # Wait for database to be ready and the specific database to exist
    if [[ "${DC_ORO_DATABASE_SCHEMA}" == "postgres" ]]; then
      # Wait for PostgreSQL to be ready and the specific database to exist
      # First wait for PostgreSQL server to be ready
      wait_server_cmd="${DOCKER_COMPOSE_BIN_CMD} run --rm database-cli bash -c \"until PGPASSWORD=\\\$DC_ORO_DATABASE_PASSWORD psql -h \\\$DC_ORO_DATABASE_HOST -p \\\$DC_ORO_DATABASE_PORT -U \\\$DC_ORO_DATABASE_USER -d postgres -c 'SELECT 1' >/dev/null 2>&1; do sleep 1; done\""
      run_with_spinner "Waiting for PostgreSQL server" "$wait_server_cmd" || exit $?
      # Then wait for the specific database to exist (created by POSTGRES_DB or initdb.d)
      # Use the db_name variable directly to avoid shell escaping issues
      wait_db_cmd="${DOCKER_COMPOSE_BIN_CMD} run --rm database-cli bash -c \"until PGPASSWORD=\\\$DC_ORO_DATABASE_PASSWORD psql -h \\\$DC_ORO_DATABASE_HOST -p \\\$DC_ORO_DATABASE_PORT -U \\\$DC_ORO_DATABASE_USER -d ${db_name} -c 'SELECT 1' >/dev/null 2>&1; do sleep 1; done\""
    elif [[ "${DC_ORO_DATABASE_SCHEMA}" == "mysql" ]]; then
      # Wait for MySQL to be ready and the specific database to exist
      # First wait for MySQL server to be ready
      wait_server_cmd="${DOCKER_COMPOSE_BIN_CMD} run --rm database-cli bash -c \"until MYSQL_PWD=\\\$DC_ORO_DATABASE_PASSWORD mysqladmin -h \\\$DC_ORO_DATABASE_HOST -P \\\$DC_ORO_DATABASE_PORT -u \\\$DC_ORO_DATABASE_USER ping >/dev/null 2>&1; do sleep 1; done\""
      run_with_spinner "Waiting for MySQL server" "$wait_server_cmd" || exit $?
      # Then wait for the specific database to exist (created by MYSQL_DATABASE or initdb.d)
      # Use the db_name variable directly to avoid shell escaping issues
      wait_db_cmd="${DOCKER_COMPOSE_BIN_CMD} run --rm database-cli bash -c \"until MYSQL_PWD=\\\$DC_ORO_DATABASE_PASSWORD mysql -h \\\$DC_ORO_DATABASE_HOST -P \\\$DC_ORO_DATABASE_PORT -u \\\$DC_ORO_DATABASE_USER -e 'USE ${db_name}; SELECT 1' >/dev/null 2>&1; do sleep 1; done\""
    fi
    run_with_spinner "Waiting for database '${db_name}'" "$wait_db_cmd" || exit $?
    
    msg_ok "Database container recreated successfully"
  fi

# Clear cache
cache_cmd="${DOCKER_COMPOSE_BIN_CMD} run --rm cli bash -c \"[[ -d ${DC_ORO_APPDIR}/var/cache ]] && rm -rf ${DC_ORO_APPDIR}/var/cache/* || true\""
run_with_spinner "Clearing cache" "$cache_cmd" || exit $?

# Backup existing config/parameters.yml if exists, then create from dist file (for legacy versions)
params_cmd="${DOCKER_COMPOSE_BIN_CMD} run --rm cli bash -c \"
  if [[ -f ${DC_ORO_APPDIR}/config/parameters.yml ]]; then
    BACKUP_NAME=\\\"${DC_ORO_APPDIR}/config/parameters.yml.\$(date +%Y%m%d%H%M).backup\\\"
    mv ${DC_ORO_APPDIR}/config/parameters.yml \\\"\\\${BACKUP_NAME}\\\"
    echo \\\"Backed up existing parameters.yml to \\\${BACKUP_NAME}\\\"
  fi
  if [[ -f ${DC_ORO_APPDIR}/config/parameters.yml.dist ]]; then
    cp ${DC_ORO_APPDIR}/config/parameters.yml.dist ${DC_ORO_APPDIR}/config/parameters.yml
  fi
\""
run_with_spinner "Preparing config files" "$params_cmd" || exit $?

# Run composer install in two phases:
# Phase 1: Install packages without post-install scripts
composer_install_cmd="${DOCKER_COMPOSE_BIN_CMD} run --rm -T cli bash -c \"composer install --no-scripts --no-interaction\""
run_with_spinner "Installing composer packages" "$composer_install_cmd" || exit $?

# Phase 2: Run post-install scripts individually
run_post_install_scripts || exit $?

# Run oro:install with spinner (use -T to disable pseudo-TTY for non-interactive mode)
install_cmd="${DOCKER_COMPOSE_BIN_CMD} run --rm -T cli bash -c \"php bin/console --env=prod --timeout=1800 oro:install --language=en --formatting-code=en_US --organization-name='Acme Inc.' --user-name=admin --user-email=admin@example.com --user-firstname=John --user-lastname=Doe --user-password='\\\$ecretPassw0rd' --application-url='https://${DC_ORO_NAME:-unnamed}.docker.local/' --sample-data=${SAMPLE_DATA}\""
run_with_spinner "$INSTALL_MSG" "$install_cmd" || exit $?

# Calculate and save total install time
install_end_time=$(date +%s)
install_duration=$((install_end_time - install_start_time))
save_timing "install" "$install_duration"

echo "" >&2
msg_ok "Installation completed in ${install_duration}s"
echo "" >&2
msg_info "Default credentials:"
msg_info "  Username: admin"
msg_info "  Password: \$ecretPassw0rd"
echo "" >&2
msg_info "To start containers, run: orodc up -d"
echo "" >&2

exit 0
