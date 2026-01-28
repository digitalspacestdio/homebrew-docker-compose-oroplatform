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

# Parse domain replacement flags first (before parse_compose_flags)
FROM_DOMAIN=""
TO_DOMAIN=""
REMAINING_ARGS=()

# Parse arguments for --from-domain and --to-domain
# Start from i=1 to skip script name (first argument when called via exec)
i=1
while [[ $i -le $# ]]; do
  arg="${!i}"
  next_i=$((i + 1))
  next_arg="${!next_i:-}"
  
  if [[ "$arg" == "--from-domain" ]] && [[ -n "$next_arg" ]]; then
    FROM_DOMAIN="$next_arg"
    i=$((i + 2))
  elif [[ "$arg" == "--to-domain" ]] && [[ -n "$next_arg" ]]; then
    TO_DOMAIN="$next_arg"
    i=$((i + 2))
  elif [[ "$arg" == --from-domain=* ]]; then
    FROM_DOMAIN="${arg#--from-domain=}"
    i=$((i + 1))
  elif [[ "$arg" == --to-domain=* ]]; then
    TO_DOMAIN="${arg#--to-domain=}"
    i=$((i + 1))
  else
    REMAINING_ARGS+=("$arg")
    i=$((i + 1))
  fi
done

# Parse remaining flags for left/right separation
parse_compose_flags "${REMAINING_ARGS[@]}"

# Validate domain format (alphanumeric, dots, hyphens, underscores only)
validate_domain() {
  local domain="$1"
  # Check if domain contains only allowed characters: letters, numbers, dots, hyphens, underscores
  # Also check it doesn't contain dangerous characters like quotes, semicolons, etc.
  if [[ ! "$domain" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    return 1
  fi
  # Check domain has at least one dot (for TLD) or is a valid local domain
  if [[ ! "$domain" =~ \. ]] && [[ ! "$domain" =~ \.local$ ]] && [[ ! "$domain" =~ ^localhost$ ]]; then
    return 1
  fi
  # Check domain doesn't start or end with dot or hyphen
  if [[ "$domain" =~ ^\. ]] || [[ "$domain" =~ \.$ ]] || [[ "$domain" =~ ^- ]] || [[ "$domain" =~ -$ ]]; then
    return 1
  fi
  return 0
}

# Prompt for domain replacement (only in interactive mode)
prompt_domain_replacement() {
  local is_interactive="${1:-true}"
  
  # Skip if domains already provided via flags
  if [[ -n "$FROM_DOMAIN" ]] && [[ -n "$TO_DOMAIN" ]]; then
    # Validate domains provided via flags
    if ! validate_domain "$FROM_DOMAIN"; then
      msg_error "Invalid source domain format: ${FROM_DOMAIN}"
      msg_info "Use only letters, numbers, dots, hyphens, and underscores."
      FROM_DOMAIN=""
      TO_DOMAIN=""
      return 1
    elif ! validate_domain "$TO_DOMAIN"; then
      msg_error "Invalid target domain format: ${TO_DOMAIN}"
      msg_info "Use only letters, numbers, dots, hyphens, and underscores."
      FROM_DOMAIN=""
      TO_DOMAIN=""
      return 1
    fi
    # Save domains for future use
    save_domain_replacement
    return 0
  fi
  
  # Only prompt in interactive mode
  if [[ "$is_interactive" != "true" ]]; then
    return 0
  fi
  
  # Load previously used domains
  load_domain_replacement
  
  # Interactive domain replacement if not specified via flags
  echo "" >&2
  if confirm_yes_no "Replace domain names in database dump?"; then
    # Get source domain with validation
    local previous_from="${FROM_DOMAIN:-}"
    while true; do
      if [[ -n "$previous_from" ]]; then
        echo -n "Enter source domain [${previous_from}]: " >&2
      else
        echo -n "Enter source domain (e.g., www.example.com): " >&2
      fi
      read -r FROM_DOMAIN
      # Use previous value if empty
      if [[ -z "$FROM_DOMAIN" ]] && [[ -n "$previous_from" ]]; then
        FROM_DOMAIN="$previous_from"
        msg_info "Using previous source domain: $FROM_DOMAIN" >&2
        break
      elif [[ -z "$FROM_DOMAIN" ]]; then
        msg_warning "No source domain specified, skipping domain replacement" >&2
        FROM_DOMAIN=""
        TO_DOMAIN=""
        break
      elif validate_domain "$FROM_DOMAIN"; then
        break
      else
        msg_error "Invalid domain format. Use only letters, numbers, dots, hyphens, and underscores." >&2
        msg_info "Example: www.example.com" >&2
      fi
    done
    
    # Get target domain with validation (if source domain was provided)
    if [[ -n "$FROM_DOMAIN" ]]; then
      local default_target_domain="${TO_DOMAIN:-${DC_ORO_NAME:-unnamed}.docker.local}"
      while true; do
        echo -n "Enter target domain [${default_target_domain}]: " >&2
        read -r TO_DOMAIN
        # Use default if empty
        if [[ -z "$TO_DOMAIN" ]]; then
          TO_DOMAIN="$default_target_domain"
          msg_info "Using default target domain: $TO_DOMAIN" >&2
          break
        elif validate_domain "$TO_DOMAIN"; then
          break
        else
          msg_error "Invalid domain format. Use only letters, numbers, dots, hyphens, and underscores." >&2
          msg_info "Example: ${default_target_domain}" >&2
        fi
      done
      
      # Save domains for future use
      save_domain_replacement
    fi
  else
    FROM_DOMAIN=""
    TO_DOMAIN=""
  fi
}

# Save domain replacement settings for future use
# Always saves to global config file (~/.orodc/{PROJECT_NAME}/.env.orodc)
# Never saves to project directory to avoid cluttering user's project
save_domain_replacement() {
  if [[ -n "$FROM_DOMAIN" ]] && [[ -n "$TO_DOMAIN" ]]; then
    # Determine project name for global config lookup
    local project_name=""
    if [[ -n "${DC_ORO_APPDIR:-}" ]]; then
      project_name=$(basename "$DC_ORO_APPDIR")
    else
      project_name=$(basename "$PWD")
    fi
    
    # Normalize project name
    if [[ "$project_name" == "$HOME" ]] || [[ -z "$project_name" ]] || [[ "$project_name" == "/" ]]; then
      project_name="default"
    fi
    
    # Always use global config file (never save to project directory)
    local global_config_file="${HOME}/.orodc/${project_name}/.env.orodc"
    
    # Create directory and file if needed
    mkdir -p "$(dirname "$global_config_file")"
    if [[ ! -f "$global_config_file" ]]; then
      touch "$global_config_file"
    fi
    
    # Update or add LAST_FROM_DOMAIN
    if grep -q "^LAST_FROM_DOMAIN=" "$global_config_file" 2>/dev/null; then
      if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "s|^LAST_FROM_DOMAIN=.*|LAST_FROM_DOMAIN=\"$FROM_DOMAIN\"|" "$global_config_file"
      else
        sed -i "s|^LAST_FROM_DOMAIN=.*|LAST_FROM_DOMAIN=\"$FROM_DOMAIN\"|" "$global_config_file"
      fi
    else
      echo "LAST_FROM_DOMAIN=\"$FROM_DOMAIN\"" >> "$global_config_file"
    fi
    
    # Update or add LAST_TO_DOMAIN
    if grep -q "^LAST_TO_DOMAIN=" "$global_config_file" 2>/dev/null; then
      if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "s|^LAST_TO_DOMAIN=.*|LAST_TO_DOMAIN=\"$TO_DOMAIN\"|" "$global_config_file"
      else
        sed -i "s|^LAST_TO_DOMAIN=.*|LAST_TO_DOMAIN=\"$TO_DOMAIN\"|" "$global_config_file"
      fi
    else
      echo "LAST_TO_DOMAIN=\"$TO_DOMAIN\"" >> "$global_config_file"
    fi
  fi
}

# Load previously used domain replacement settings
# Loads from global config file (~/.orodc/{PROJECT_NAME}/.env.orodc)
# Never reads from project directory to respect user's preference
load_domain_replacement() {
  # Determine project name for global config lookup
  local project_name=""
  if [[ -n "${DC_ORO_APPDIR:-}" ]]; then
    project_name=$(basename "$DC_ORO_APPDIR")
  else
    project_name=$(basename "$PWD")
  fi
  
  # Normalize project name
  if [[ "$project_name" == "$HOME" ]] || [[ -z "$project_name" ]] || [[ "$project_name" == "/" ]]; then
    project_name="default"
  fi
  
  local global_config_file="${HOME}/.orodc/${project_name}/.env.orodc"
  
  # Load from global file only (never from project directory)
  if [[ -f "$global_config_file" ]]; then
    if grep -q "^LAST_FROM_DOMAIN=" "$global_config_file" 2>/dev/null; then
      FROM_DOMAIN=$(grep "^LAST_FROM_DOMAIN=" "$global_config_file" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
    fi
    if grep -q "^LAST_TO_DOMAIN=" "$global_config_file" 2>/dev/null; then
      TO_DOMAIN=$(grep "^LAST_TO_DOMAIN=" "$global_config_file" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
    fi
  fi
}

# Build domain replacement sed command
build_domain_replace_sed() {
  DOMAIN_REPLACE_SED=""
  if [[ -n "$FROM_DOMAIN" ]] && [[ -n "$TO_DOMAIN" ]]; then
    # Escape special characters for sed (escape dot, slash, etc.)
    FROM_DOMAIN_ESC=$(printf '%s\n' "$FROM_DOMAIN" | sed 's/[[\.*^$()+?{|]/\\&/g')
    TO_DOMAIN_ESC=$(printf '%s\n' "$TO_DOMAIN" | sed 's/[[\.*^$()+?{|]/\\&/g')
    # Replace domain only in safe contexts:
    # 1. URLs: http://domain or https://domain
    # 2. String values in SQL: 'domain' or "domain" (inside quotes)
    # 3. Domain as standalone value (surrounded by spaces, quotes, or end of line)
    # Avoid replacing in: #!/bin/bash, comments starting with --, etc.
    # Remove lines starting with #!/ (shebang lines) - these are not valid SQL
    # Then skip lines starting with # or ! (comments), then apply domain replacement
    DOMAIN_REPLACE_SED="sed -E '/^[[:space:]]*#!/d' | sed -E '/^[[:space:]]*[#!]/! { s|https://${FROM_DOMAIN_ESC}|https://${TO_DOMAIN_ESC}|g; s|http://${FROM_DOMAIN_ESC}|http://${TO_DOMAIN_ESC}|g; s|${FROM_DOMAIN_ESC}|${TO_DOMAIN_ESC}|g; }' |"
    msg_info "Domain replacement: ${FROM_DOMAIN} -> ${TO_DOMAIN}"
  fi
}

# List available database dumps
list_database_dumps() {
  local project_dir="${DC_ORO_APPDIR:-$PWD}"
  local backup_dir="${project_dir}/var/backup"
  local var_dir="${project_dir}/var"

  local dumps=()

  # Check backup directory first
  if [[ -d "$backup_dir" ]]; then
    while IFS= read -r -d '' file; do
      dumps+=("$file")
    done < <(find "$backup_dir" -maxdepth 1 -type f \( -name "*.sql" -o -name "*.sql.gz" \) -print0 2>/dev/null | sort -z)
  fi

  # Fallback to var/ directory if backup is empty
  if [[ ${#dumps[@]} -eq 0 ]] && [[ -d "$var_dir" ]]; then
    while IFS= read -r -d '' file; do
      dumps+=("$file")
    done < <(find "$var_dir" -maxdepth 1 -type f \( -name "*.sql" -o -name "*.sql.gz" \) -print0 2>/dev/null | sort -z)
  fi

  if [[ ${#dumps[@]} -eq 0 ]]; then
    return 1
  fi

  printf '%s\n' "${dumps[@]}"
}

# Perform actual database import (shared logic for both interactive and non-interactive modes)
perform_database_import() {
  local selected_file="$1"
  
  # Check database schema is configured
  if [[ -z "${DC_ORO_DATABASE_SCHEMA:-}" ]]; then
    msg_error "Database schema not configured"
    msg_info "Please ensure DC_ORO_DATABASE_SCHEMA is set in .env.orodc"
    msg_info "Or run 'orodc init' to configure your project"
    exit 1
  fi

  db_name="${DC_ORO_DATABASE_DBNAME:-app_db}"
  
  # Require user to confirm dropping existing database before import
  echo "" >&2
  msg_danger "This will DELETE ALL DATA in database '${db_name}'!"
  if ! confirm_yes_no "Continue?"; then
    msg_info "Import cancelled" >&2
    exit 0
  fi
  
  # Prompt for domain replacement AFTER confirmation but BEFORE stopping containers
  prompt_domain_replacement "true"
  
  # Stop and remove database container using docker compose
  stop_rm_cmd="${DOCKER_COMPOSE_BIN_CMD} stop database >/dev/null 2>&1 && ${DOCKER_COMPOSE_BIN_CMD} rm -f database >/dev/null 2>&1 || true"
  run_with_spinner "Stopping and removing database container" "$stop_rm_cmd" || true

  # Remove database volumes
  if [[ "${DC_ORO_DATABASE_SCHEMA}" == "postgres" ]]; then
    volume_name="${DC_ORO_NAME:-}_postgresql-data"
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
    wait_server_cmd="${DOCKER_COMPOSE_BIN_CMD} run --rm database-cli bash -c \"until PGPASSWORD=\\\$DC_ORO_DATABASE_PASSWORD psql -h \\\$DC_ORO_DATABASE_HOST -p \\\$DC_ORO_DATABASE_PORT -U \\\$DC_ORO_DATABASE_USER -d postgres -c 'SELECT 1' >/dev/null 2>&1; do sleep 1; done\""
    run_with_spinner "Waiting for PostgreSQL server" "$wait_server_cmd" || exit $?
    wait_db_cmd="${DOCKER_COMPOSE_BIN_CMD} run --rm database-cli bash -c \"until PGPASSWORD=\\\$DC_ORO_DATABASE_PASSWORD psql -h \\\$DC_ORO_DATABASE_HOST -p \\\$DC_ORO_DATABASE_PORT -U \\\$DC_ORO_DATABASE_USER -d ${db_name} -c 'SELECT 1' >/dev/null 2>&1; do sleep 1; done\""
  elif [[ "${DC_ORO_DATABASE_SCHEMA}" == "mysql" ]]; then
    wait_server_cmd="${DOCKER_COMPOSE_BIN_CMD} run --rm database-cli bash -c \"until MYSQL_PWD=\\\$DC_ORO_DATABASE_PASSWORD mysqladmin -h \\\$DC_ORO_DATABASE_HOST -P \\\$DC_ORO_DATABASE_PORT -u \\\$DC_ORO_DATABASE_USER ping >/dev/null 2>&1; do sleep 1; done\""
    run_with_spinner "Waiting for MySQL server" "$wait_server_cmd" || exit $?
    wait_db_cmd="${DOCKER_COMPOSE_BIN_CMD} run --rm database-cli bash -c \"until MYSQL_PWD=\\\$DC_ORO_DATABASE_PASSWORD mysql -h \\\$DC_ORO_DATABASE_HOST -P \\\$DC_ORO_DATABASE_PORT -u \\\$DC_ORO_DATABASE_USER -e 'USE ${db_name}; SELECT 1' >/dev/null 2>&1; do sleep 1; done\""
  else
    msg_error "Unknown database schema: ${DC_ORO_DATABASE_SCHEMA}"
    exit 1
  fi
  
  run_with_spinner "Waiting for database '${db_name}'" "$wait_db_cmd" || exit $?
  
  msg_ok "Database container recreated successfully"
  echo "" >&2
  
  # Build domain replacement sed command
  build_domain_replace_sed
  
  # Use existing importdb logic
  DB_DUMP="$selected_file"
  DB_DUMP_BASENAME=$(echo "${DB_DUMP##*/}")

  if [[ $DC_ORO_DATABASE_SCHEMA == "pdo_pgsql" ]] || [[ $DC_ORO_DATABASE_SCHEMA == "postgres" ]];then
    DB_IMPORT_CMD="sed -E 's/[Oo][Ww][Nn][Ee][Rr]:[[:space:]]*[a-zA-Z0-9_]+/Owner: '\$DC_ORO_DATABASE_USER'/g' | sed -E 's/[Oo][Ww][Nn][Ee][Rr][[:space:]]+[Tt][Oo][[:space:]]+[a-zA-Z0-9_]+/OWNER TO '\$DC_ORO_DATABASE_USER'/g' | sed -E 's/[Ff][Oo][Rr][[:space:]]+[Rr][Oo][Ll][Ee][[:space:]]+[a-zA-Z0-9_]+/FOR ROLE '\$DC_ORO_DATABASE_USER'/g' | sed -E 's/[Tt][Oo][[:space:]]+[a-zA-Z0-9_]+;/TO '\$DC_ORO_DATABASE_USER';/g' | sed -E '/^[[:space:]]*[Rr][Ee][Vv][Oo][Kk][Ee][[:space:]]+[Aa][Ll][Ll]/d' | sed -e '/SET transaction_timeout = 0;/d' | sed -E '/[\\]restrict|[\\]unrestrict/d' | PGPASSWORD=\$DC_ORO_DATABASE_PASSWORD psql --set ON_ERROR_STOP=on -h \$DC_ORO_DATABASE_HOST -p \$DC_ORO_DATABASE_PORT -U \$DC_ORO_DATABASE_USER -d \$DC_ORO_DATABASE_DBNAME -1 >/dev/null"
  elif [[ "${DC_ORO_DATABASE_SCHEMA}" == "pdo_mysql" ]] || [[ "${DC_ORO_DATABASE_SCHEMA}" == "mysql" ]];then
    DB_IMPORT_CMD="sed -E 's/[Dd][Ee][Ff][Ii][Nn][Ee][Rr][ ]*=[ ]*[^*]*\*/DEFINER=CURRENT_USER \*/' | MYSQL_PWD=\$DC_ORO_DATABASE_PASSWORD mysql -h\$DC_ORO_DATABASE_HOST -P\$DC_ORO_DATABASE_PORT -u\$DC_ORO_DATABASE_USER \$DC_ORO_DATABASE_DBNAME"
  fi

  # Always remove shebang lines (#!/bin/bash, etc.) - they cause psql syntax errors
  # This must be done BEFORE any other processing
  SHEBANG_REMOVE_SED="sed -E '/^[[:space:]]*#!/d' |"
  
  # Check if pv (pipe viewer) is available for progress display (optional)
  # pv shows progress bar, transfer rate, and ETA during import
  # For .sql.gz files, we use compressed file size (pv will show progress of compressed data)
  # For .sql files, we use file size for accurate progress percentage
  # pv is optional - if not available in container, fall back to spinner
  PV_CMD=""
  PV_AVAILABLE=false
  if [[ "${DC_ORO_DATABASE_SCHEMA}" == "postgres" ]] || [[ "${DC_ORO_DATABASE_SCHEMA}" == "pdo_pgsql" ]] || [[ "${DC_ORO_DATABASE_SCHEMA}" == "mysql" ]] || [[ "${DC_ORO_DATABASE_SCHEMA}" == "pdo_mysql" ]]; then
    # Check if pv is available in database-cli container (optional - user may have custom container)
    # Test by running a simple pv --version command in the container
    # Use --no-deps to avoid starting dependencies, and -T to disable TTY for non-interactive check
    if ${DOCKER_COMPOSE_BIN_CMD} run --rm --no-deps -T database-cli bash -c "command -v pv >/dev/null 2>&1" >/dev/null 2>&1; then
      PV_AVAILABLE=true
      # Get file size from host (file is mounted in container at /${DB_DUMP_BASENAME})
      DB_DUMP_SIZE=$(stat -f%z "$DB_DUMP" 2>/dev/null || stat -c%s "$DB_DUMP" 2>/dev/null || echo "0")
      if [[ "$DB_DUMP_SIZE" -gt 0 ]]; then
        # Use file size for accurate progress percentage
        # For .sql.gz, this shows progress of compressed data being processed
        # For .sql, this shows accurate progress percentage
        PV_CMD="pv -s ${DB_DUMP_SIZE} -p -t -r -e -b |"
      else
        # Fallback if size cannot be determined
        PV_CMD="pv -p -t -r -e -b |"
      fi
    elif [[ -n "${DEBUG:-}" ]]; then
      # Show debug info if pv is not available
      msg_info "pv not available in database-cli container, using spinner instead" >&2
      if [[ "${DC_ORO_DATABASE_SCHEMA}" == "postgres" ]] || [[ "${DC_ORO_DATABASE_SCHEMA}" == "pdo_pgsql" ]]; then
        msg_info "To enable pv, rebuild PostgreSQL image: orodc docker-build pgsql" >&2
      else
        msg_info "To enable pv, rebuild MySQL image: orodc docker-build mysql" >&2
      fi
    fi
  fi
  
  if echo ${DB_DUMP_BASENAME} | grep -i 'sql\.gz$' > /dev/null; then
    DB_IMPORT_CMD="zcat ${DB_DUMP_BASENAME} | ${SHEBANG_REMOVE_SED} ${DOMAIN_REPLACE_SED} sed -E 's/^[[:space:]]*[Cc][Rr][Ee][Aa][Tt][Ee][[:space:]]+[Ff][Uu][Nn][Cc][Tt][Ii][Oo][Nn]/CREATE OR REPLACE FUNCTION/g' | ${PV_CMD} ${DB_IMPORT_CMD}"
  else
    DB_IMPORT_CMD="cat /${DB_DUMP_BASENAME} | ${SHEBANG_REMOVE_SED} ${DOMAIN_REPLACE_SED} sed -E 's/^[[:space:]]*[Cc][Rr][Ee][Aa][Tt][Ee][[:space:]]+[Ff][Uu][Nn][Cc][Tt][Ii][Oo][Nn]/CREATE OR REPLACE FUNCTION/g' | ${PV_CMD} ${DB_IMPORT_CMD}"
  fi

  # Show import details (context information)
  msg_info "From: $DB_DUMP"
  msg_info "File size: $(du -h "$DB_DUMP" | cut -f1)"
  msg_info "Database: $DC_ORO_DATABASE_HOST:$DC_ORO_DATABASE_PORT/$DC_ORO_DATABASE_DBNAME"

  # Use pv for progress display if available (optional)
  # pv writes progress to stderr, so we need to preserve stderr for progress display
  # Remove --quiet flag to allow pv output, but keep -i for interactive mode
  if [[ "$PV_AVAILABLE" == "true" ]] && [[ -n "$PV_CMD" ]]; then
    # pv will show progress on stderr, so we don't use spinner (it would interfere)
    import_cmd="${DOCKER_COMPOSE_BIN_CMD} ${left_flags[*]} ${left_options[*]} run -i --rm -v \"${DB_DUMP}:/${DB_DUMP_BASENAME}\" database-cli bash -c \"$DB_IMPORT_CMD\""
    echo "" >&2
    msg_info "Importing database (showing progress)..." >&2
    eval "$import_cmd" || return $?
  else
    # Fallback to spinner for MySQL, custom containers without pv, or if pv check failed
    import_cmd="${DOCKER_COMPOSE_BIN_CMD} ${left_flags[*]} ${left_options[*]} run --quiet -i --rm -v \"${DB_DUMP}:/${DB_DUMP_BASENAME}\" database-cli bash -c \"$DB_IMPORT_CMD\""
    run_with_spinner "Importing database" "$import_cmd" || return $?
  fi

  msg_ok "Database imported successfully"
}

# Import database from var/backup/ folder or file path (interactive mode)
import_database_interactive() {
  # Use project directory, fallback to current directory
  local project_dir="${DC_ORO_APPDIR:-$PWD}"
  local backup_dir="${project_dir}/var/backup"
  local var_dir="${project_dir}/var"
  local dumps=()
  local dump_files=()

  # Get dumps using list_database_dumps (checks var/backup/ first, then var/)
  while IFS= read -r file; do
    if [[ -n "$file" ]]; then
      dumps+=("$file")
      dump_files+=("$file")
    fi
  done < <(list_database_dumps 2>/dev/null || true)

  local selected_file=""

  if [[ ${#dumps[@]} -gt 0 ]]; then
    echo "" >&2
    msg_header "Available Database Dumps"
    echo "" >&2
    local i=1
    for dump in "${dumps[@]}"; do
      local basename_dump=$(basename "$dump")
      local size=$(du -h "$dump" 2>/dev/null | cut -f1)
      printf "  %2d) %s (%s)\n" "$i" "$basename_dump" "$size" >&2
      i=$((i + 1))
    done
    echo "" >&2
    echo -n "Select dump number or enter file path: " >&2
    read -r input

    if [[ "$input" =~ ^[0-9]+$ ]] && [[ $input -ge 1 ]] && [[ $input -le ${#dumps[@]} ]]; then
      selected_file="${dumps[$((input - 1))]}"
    elif [[ -n "$input" ]]; then
      # Try as file path
      if [[ -r "$input" ]]; then
        selected_file=$(realpath "$input")
      elif [[ -r "${project_dir}/${input}" ]]; then
        selected_file=$(realpath "${project_dir}/${input}")
      elif [[ -r "${backup_dir}/${input}" ]]; then
        selected_file=$(realpath "${backup_dir}/${input}")
      elif [[ -r "${var_dir}/${input}" ]]; then
        selected_file=$(realpath "${var_dir}/${input}")
      else
        msg_error "File not found or not readable: $input"
        return 1
      fi
    else
      msg_error "No selection made"
      return 1
    fi
  else
    echo -n "Enter database dump file path: " >&2
    read -r input

    if [[ -z "$input" ]]; then
      msg_error "No file provided"
      return 1
    fi

    if [[ -r "$input" ]]; then
      selected_file=$(realpath "$input")
    elif [[ -r "${backup_dir}/${input}" ]]; then
      selected_file=$(realpath "${backup_dir}/${input}")
    elif [[ -r "${var_dir}/${input}" ]]; then
      selected_file=$(realpath "${var_dir}/${input}")
    elif [[ -r "${project_dir}/${input}" ]]; then
      selected_file=$(realpath "${project_dir}/${input}")
    else
      msg_error "File not found or not readable: $input"
      return 1
    fi
  fi

  if [[ -z "$selected_file" ]] || [[ ! -r "$selected_file" ]]; then
    msg_error "Invalid file: $selected_file"
    return 1
  fi

  # Perform import using shared logic
  perform_database_import "$selected_file"
}

# Import database from specific file (non-interactive mode)
import_database_from_file() {
  local selected_file="$1"
  
  # Perform import using shared logic (domain replacement prompt is inside perform_database_import)
  perform_database_import "$selected_file"
}

# Import database with optional file argument
import_database() {
  local dump_file="${REMAINING_ARGS[0]:-}"
  
  # If file is provided as argument, use it directly
  if [[ -n "$dump_file" ]]; then
    # Resolve file path
    local project_dir="${DC_ORO_APPDIR:-$PWD}"
    local backup_dir="${project_dir}/var/backup"
    local var_dir="${project_dir}/var"
    local selected_file=""
    
    # Try to resolve file path
    if [[ -r "$dump_file" ]]; then
      selected_file=$(realpath "$dump_file")
    elif [[ -r "${project_dir}/${dump_file}" ]]; then
      selected_file=$(realpath "${project_dir}/${dump_file}")
    elif [[ -r "${backup_dir}/${dump_file}" ]]; then
      selected_file=$(realpath "${backup_dir}/${dump_file}")
    elif [[ -r "${var_dir}/${dump_file}" ]]; then
      selected_file=$(realpath "${var_dir}/${dump_file}")
    else
      msg_error "File not found or not readable: $dump_file"
      exit 1
    fi
    
    if [[ -z "$selected_file" ]] || [[ ! -r "$selected_file" ]]; then
      msg_error "Invalid file: $selected_file"
      exit 1
    fi
    
    # Use the file directly in import function (non-interactive mode)
    import_database_from_file "$selected_file"
  else
    # No file provided, use interactive mode
    import_database_interactive
  fi
}

# Run import
import_database
exit $?
