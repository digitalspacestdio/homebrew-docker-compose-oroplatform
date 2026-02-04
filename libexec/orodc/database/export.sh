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

# Parse flags for left/right separation
parse_compose_flags "$@"

# Export database to var/backup/ folder
export_database_interactive() {
  # Use project directory, fallback to current directory
  local project_dir="${DC_ORO_APPDIR:-$PWD}"
  local backup_dir="${project_dir}/var/backup"
  mkdir -p "$backup_dir"

  local default_filename="database-$(date +'%Y%m%d%H%M%S').sql.gz"
  local filename=""

  # Check if filename provided as argument
  if [[ -n "${right_flags[0]:-}" ]]; then
    filename="${right_flags[0]}"
  # Interactive mode: stdin is a terminal
  elif [[ -t 0 ]]; then
    echo -n "Enter filename [default: $default_filename]: " >&2
    read -r filename
  fi

  # Use default if no filename provided
  if [[ -z "$filename" ]]; then
    filename="$default_filename"
  fi

  # Ensure .sql.gz extension
  if [[ ! "$filename" =~ \.(sql|sql\.gz)$ ]]; then
    filename="${filename}.sql.gz"
  fi

  local dump_path="${backup_dir}/${filename}"

  # Use existing exportdb logic
  DB_DUMP="$dump_path"
  DB_DUMP_BASENAME=$(echo "${DB_DUMP##*/}")
  touch "${DB_DUMP}"

  # Get database connection parameters
  # Use values from environment variables (set by parse_dsn_uri or .env files)
  # Fallback to defaults only if not set
  local db_host="${DC_ORO_DATABASE_HOST:-database}"
  local db_user="${DC_ORO_DATABASE_USER:-oro_db_user}"
  local db_password="${DC_ORO_DATABASE_PASSWORD:-oro_db_pass}"
  local db_name="${DC_ORO_DATABASE_DBNAME:-oro_db}"
  
  # Determine port based on schema (with fallback)
  local db_port="${DC_ORO_DATABASE_PORT:-}"
  if [[ -z "$db_port" ]]; then
    if [[ "${DC_ORO_DATABASE_SCHEMA}" == "mariadb" ]] || [[ "${DC_ORO_DATABASE_SCHEMA}" == "mysql" ]] || [[ "${DC_ORO_DATABASE_SCHEMA}" == "pdo_mysql" ]]; then
      db_port="3306"
    else
      db_port="5432"  # Default to PostgreSQL
    fi
  fi

  # Show export details (context information)
  msg_info "Database: ${db_host}:${db_port}/${db_name}"
  msg_info "Export to: $DB_DUMP"

  # Build export command with explicit values (like psql.sh and mysql.sh)
  # Use set -o pipefail to preserve exit code of pg_dump/mysqldump when piping to gzip
  if [[ $DC_ORO_DATABASE_SCHEMA == "pgsql" ]] || [[ $DC_ORO_DATABASE_SCHEMA == "postgres" ]] || [[ $DC_ORO_DATABASE_SCHEMA == "postgresql" ]] || [[ $DC_ORO_DATABASE_SCHEMA == "pdo_pgsql" ]]; then
    export_cmd="${DOCKER_COMPOSE_BIN_CMD} ${left_flags[*]} ${left_options[*]} run --quiet --rm -e PGPASSWORD=\"${db_password}\" -v \"${DB_DUMP}:/${DB_DUMP_BASENAME}\" database-cli bash -c \"set -o pipefail; pg_dump -Fp --clean --if-exists -h '${db_host}' -p '${db_port}' -U '${db_user}' -d '${db_name}' | gzip > /${DB_DUMP_BASENAME}\""
  elif [[ "${DC_ORO_DATABASE_SCHEMA}" == "mariadb" ]] || [[ "${DC_ORO_DATABASE_SCHEMA}" == "mysql" ]] || [[ "${DC_ORO_DATABASE_SCHEMA}" == "pdo_mysql" ]];then
    export_cmd="${DOCKER_COMPOSE_BIN_CMD} ${left_flags[*]} ${left_options[*]} run --quiet --rm -e MYSQL_PWD=\"${db_password}\" -v \"${DB_DUMP}:/${DB_DUMP_BASENAME}\" database-cli bash -c \"set -o pipefail; mysqldump --no-tablespaces --column-statistics=0 --set-gtid-purged=OFF --quick --max-allowed-packet=16M --disable-keys --hex-blob --no-autocommit --insert-ignore --skip-lock-tables --single-transaction -h'${db_host}' -P'${db_port}' -u'${db_user}' '${db_name}' | sed -E 's/[Dd][Ee][Ff][Ii][Nn][Ee][Rr][ ]*=[ ]*[^*]*\*/DEFINER=CURRENT_USER \*/' | gzip > /${DB_DUMP_BASENAME}\""
  else
    msg_error "Unknown database schema: ${DC_ORO_DATABASE_SCHEMA}"
    return 1
  fi
  
  if ! run_with_spinner "Exporting database" "$export_cmd"; then
    msg_error "Database export failed"
    return 1
  fi

  # Check if dump file was created and has reasonable size (at least 1KB)
  if [[ ! -f "$DB_DUMP" ]] || [[ $(stat -f%z "$DB_DUMP" 2>/dev/null || stat -c%s "$DB_DUMP" 2>/dev/null || echo 0) -lt 1024 ]]; then
    msg_error "Database export failed: dump file is missing or too small"
    return 1
  fi

  msg_ok "Database exported successfully"
  msg_info "File: $DB_DUMP"
  msg_info "Size: $(du -h "$DB_DUMP" | cut -f1)"
  echo "" >&2
  
  # If running from interactive menu, pause before returning
  if [[ -n "${DC_ORO_IS_INTERACTIVE_MENU:-}" ]]; then
    echo -n "Press Enter to continue..." >&2
    read -r
  fi
}

# Run export
export_database_interactive
exit $?
