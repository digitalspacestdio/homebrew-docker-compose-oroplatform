#!/bin/bash
set -e
if [ "$DEBUG" ]; then set -x; fi

# Determine script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/ui.sh"
source "${SCRIPT_DIR}/lib/environment.sh"
source "${SCRIPT_DIR}/lib/docker-utils.sh"

# Initialize environment first (sets DC_ORO_NAME, DC_ORO_CONFIG_DIR, etc.)
initialize_environment

# Check that we're in a project
check_in_project || exit 1

# Parse compose flags
parse_compose_flags "$@"

# Get environment variables from container or config
get_container_env() {
  local var_name="$1"
  local container_service="${2:-cli}"
  
  # Check if docker-compose file exists
  if ! ${DOCKER_COMPOSE_BIN_CMD} ${left_flags[*]} ${left_options[*]} config >/dev/null 2>&1; then
    return 1
  fi
  
  # Try to get from running container first
  local value=""
  if ${DOCKER_COMPOSE_BIN_CMD} ${left_flags[*]} ${left_options[*]} ps --status running "$container_service" 2>/dev/null | grep -q "$container_service"; then
    # Container is running - use exec
    value=$(${DOCKER_COMPOSE_BIN_CMD} ${left_flags[*]} ${left_options[*]} exec -T "$container_service" env 2>/dev/null | grep "^${var_name}=" | cut -d'=' -f2- | sed 's/^"//;s/"$//' || echo "")
  else
    # Container is not running - get from environment variables already loaded
    # These are set by initialize_environment from .env files
    value="${!var_name:-}"
  fi
  
  echo "$value"
}

# Get all environment variables from container or config
get_all_container_env() {
  local container_service="${1:-cli}"
  
  # Check if docker-compose file exists
  if ! ${DOCKER_COMPOSE_BIN_CMD} ${left_flags[*]} ${left_options[*]} config >/dev/null 2>&1; then
    msg_error "Docker Compose configuration not found or invalid"
    msg_info "Please run 'orodc init' to initialize the project"
    return 1
  fi
  
  # Try to get from running container first
  if ${DOCKER_COMPOSE_BIN_CMD} ${left_flags[*]} ${left_options[*]} ps --status running "$container_service" 2>/dev/null | grep -q "$container_service"; then
    # Container is running - use exec (fast operation, no spinner needed)
    ${DOCKER_COMPOSE_BIN_CMD} ${left_flags[*]} ${left_options[*]} exec -T "$container_service" env 2>/dev/null || echo ""
  else
    # Container is not running - get from environment variables with defaults
    # Show ORO_ variables from current environment (loaded by initialize_environment)
    # Also add default values for common ORO_ variables if not set
    {
      # Get ORO_ variables from current environment
      env | grep "^ORO_" | sort
      
      # Add default values for common ORO_ variables if not already set
      # These defaults match docker-compose.yml defaults
      [[ -z "${ORO_DB_HOST:-}" ]] && echo "ORO_DB_HOST=${DC_ORO_DATABASE_HOST:-database}"
      [[ -z "${ORO_DB_PORT:-}" ]] && echo "ORO_DB_PORT=${DC_ORO_DATABASE_PORT:-5432}"
      [[ -z "${ORO_DB_NAME:-}" ]] && echo "ORO_DB_NAME=${DC_ORO_DATABASE_DBNAME:-app_db}"
      [[ -z "${ORO_DB_USER:-}" ]] && echo "ORO_DB_USER=${DC_ORO_DATABASE_USER:-app_db_user}"
      [[ -z "${ORO_DB_PASSWORD:-}" ]] && echo "ORO_DB_PASSWORD=${DC_ORO_DATABASE_PASSWORD:-app_db_pass}"
      [[ -z "${ORO_DB_URL:-}" ]] && {
        local db_schema="${DC_ORO_DATABASE_SCHEMA:-postgres}"
        [[ "$db_schema" == "mysql" ]] && db_schema="mysql" || db_schema="postgres"
        local db_user="${DC_ORO_DATABASE_USER:-app_db_user}"
        local db_pass="${DC_ORO_DATABASE_PASSWORD:-app_db_pass}"
        local db_host="${DC_ORO_DATABASE_HOST:-database}"
        local db_port="${DC_ORO_DATABASE_PORT:-$([ "$db_schema" == "mysql" ] && echo "3306" || echo "5432")}"
        local db_name="${DC_ORO_DATABASE_DBNAME:-app_db}"
        echo "ORO_DB_URL=${db_schema}://${db_user}:${db_pass}@${db_host}:${db_port}/${db_name}"
      }
      [[ -z "${ORO_DB_DSN:-}" ]] && {
        local db_schema="${DC_ORO_DATABASE_SCHEMA:-postgres}"
        [[ "$db_schema" == "mysql" ]] && db_schema="mysql" || db_schema="postgres"
        local db_user="${DC_ORO_DATABASE_USER:-app_db_user}"
        local db_pass="${DC_ORO_DATABASE_PASSWORD:-app_db_pass}"
        local db_host="${DC_ORO_DATABASE_HOST:-database}"
        local db_port="${DC_ORO_DATABASE_PORT:-$([ "$db_schema" == "mysql" ] && echo "3306" || echo "5432")}"
        local db_name="${DC_ORO_DATABASE_DBNAME:-app_db}"
        echo "ORO_DB_DSN=${db_schema}://${db_user}:${db_pass}@${db_host}:${db_port}/${db_name}"
      }
      [[ -z "${ORO_SEARCH_URL:-}" ]] && echo "ORO_SEARCH_URL=${DC_ORO_SEARCH_URI:-elastic-search://search:9200}"
      [[ -z "${ORO_SEARCH_DSN:-}" ]] && echo "ORO_SEARCH_DSN=${DC_ORO_SEARCH_URI:-elastic-search://search:9200}"
      [[ -z "${ORO_SEARCH_ENGINE_DSN:-}" ]] && echo "ORO_SEARCH_ENGINE_DSN=${DC_ORO_SEARCH_URI:-elastic-search://search:9200}?prefix=oro_search"
      [[ -z "${ORO_WEBSITE_SEARCH_ENGINE_DSN:-}" ]] && echo "ORO_WEBSITE_SEARCH_ENGINE_DSN=${DC_ORO_SEARCH_URI:-elastic-search://search:9200}?prefix=oro_website_search"
      [[ -z "${ORO_MQ_DSN:-}" ]] && echo "ORO_MQ_DSN=${DC_ORO_MQ_URI:-dbal:}"
      [[ -z "${ORO_REDIS_URL:-}" ]] && echo "ORO_REDIS_URL=${DC_ORO_REDIS_URI:-redis://redis:6379}"
      [[ -z "${ORO_SESSION_DSN:-}" ]] && echo "ORO_SESSION_DSN=${DC_ORO_REDIS_URI:-redis://redis:6379}/0"
      [[ -z "${ORO_REDIS_CACHE_DSN:-}" ]] && echo "ORO_REDIS_CACHE_DSN=${DC_ORO_REDIS_URI:-redis://redis:6379}/1"
      [[ -z "${ORO_REDIS_DOCTRINE_DSN:-}" ]] && echo "ORO_REDIS_DOCTRINE_DSN=${DC_ORO_REDIS_URI:-redis://redis:6379}/2"
      [[ -z "${ORO_REDIS_LAYOUT_DSN:-}" ]] && echo "ORO_REDIS_LAYOUT_DSN=${DC_ORO_REDIS_URI:-redis://redis:6379}/3"
      [[ -z "${ORO_MAILER_DRIVER:-}" ]] && echo "ORO_MAILER_DRIVER=${ORO_MAILER_DRIVER:-smtp}"
      [[ -z "${ORO_MAILER_HOST:-}" ]] && echo "ORO_MAILER_HOST=${ORO_MAILER_HOST:-mail}"
      [[ -z "${ORO_MAILER_PORT:-}" ]] && echo "ORO_MAILER_PORT=${ORO_MAILER_PORT:-1025}"
    } | sort -u
  fi
}

# Cache container environment variables
CONTAINER_ENV_CACHE=""
load_container_env_cache() {
  if [[ -z "$CONTAINER_ENV_CACHE" ]]; then
    CONTAINER_ENV_CACHE=$(get_all_container_env "cli")
  fi
}

# Get variable from cache
get_cached_env() {
  local var_name="$1"
  load_container_env_cache
  echo "$CONTAINER_ENV_CACHE" | grep "^${var_name}=" | cut -d'=' -f2- | sed 's/^"//;s/"$//' || echo ""
}

# Print section header
print_section() {
  echo ""
  msg_highlight "$1"
  echo ""
}

# Print key-value pair
print_var() {
  local key="$1"
  local value="${2:-}"
  if [[ -n "$value" ]]; then
    printf "  %-35s %s\n" "$key:" "$value"
  else
    printf "  %-35s %s\n" "$key:" "(not set)"
  fi
}


# Main function
main() {
  local format="${1:-human}"
  
  case "$format" in
    human|"")
      # Human-readable format - get variables from container
      # Load container environment cache once
      load_container_env_cache
      
      # Get all ORO_ variables from container
      local oro_vars=$(echo "$CONTAINER_ENV_CACHE" | grep "^ORO_" | sort)
      
      if [[ -z "$oro_vars" ]]; then
        msg_warning "No ORO_ variables found in container"
        exit 0
      fi
      
      print_section "Oro Environment Variables (from container)"
      echo ""
      
      # Print all ORO_ variables
      while IFS='=' read -r var_name var_value; do
        # Skip empty lines
        [[ -z "$var_name" ]] && continue
        
        print_var "$var_name" "$var_value"
      done <<< "$oro_vars"
      ;;
      
    export|bash)
      # Export format (for bash sourcing) - get variables from container
      load_container_env_cache
      
      echo "# ORO_ environment variables from container (cli service)"
      echo "# Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
      echo ""
      
      # Get all ORO_ variables from container
      local oro_vars=$(echo "$CONTAINER_ENV_CACHE" | grep "^ORO_" | sort)
      
      if [[ -z "$oro_vars" ]]; then
        echo "# No ORO_ variables found in container"
        exit 0
      fi
      
      # Export all ORO_ variables
      while IFS='=' read -r var_name var_value; do
        # Skip empty lines
        [[ -z "$var_name" ]] && continue
        
        # Escape quotes in value
        var_value=$(echo "$var_value" | sed 's/"/\\"/g')
        echo "export ${var_name}=\"${var_value}\""
      done <<< "$oro_vars"
      ;;
      
    json)
      # JSON format - get variables from container
      load_container_env_cache
      
      # Get all ORO_ variables from container
      local oro_vars=$(echo "$CONTAINER_ENV_CACHE" | grep "^ORO_" | sort)
      
      if [[ -z "$oro_vars" ]]; then
        echo "{}"
        exit 0
      fi
      
      echo "{"
      
      local first=true
      while IFS='=' read -r var_name var_value; do
        # Skip empty lines
        [[ -z "$var_name" ]] && continue
        
        # Add comma if not first item
        if [[ "$first" == "true" ]]; then
          first=false
        else
          echo ","
        fi
        
        # Escape quotes and backslashes for JSON
        var_value=$(echo "$var_value" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
        # Convert variable name to lowercase with underscores (JSON key format)
        local json_key=$(echo "$var_name" | tr '[:upper:]' '[:lower:]')
        printf "  \"%s\": \"%s\"" "$json_key" "$var_value"
      done <<< "$oro_vars"
      
      echo ""
      echo "}"
      ;;
      
    *)
      msg_error "Unknown format: $format"
      echo ""
      msg_info "Available formats: human (default), export, bash, json"
      exit 1
      ;;
  esac
}

main "$@"
