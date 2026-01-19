#!/bin/bash
set -e
if [ "$DEBUG" ]; then set -x; fi

# Determine script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/ui.sh"
source "${SCRIPT_DIR}/lib/environment.sh"
source "${SCRIPT_DIR}/lib/wizard.sh"

# Determine project directory (same logic as initialize_environment)
PROJECT_DIR=""
if [[ -z "${DC_ORO_APPDIR:-}" ]]; then
  PROJECT_DIR=$(find-up composer.json)
fi
if [[ -z "$PROJECT_DIR" ]]; then
  PROJECT_DIR=$(find-up .env.orodc)
fi
if [[ -z "$PROJECT_DIR" ]]; then
  PROJECT_DIR="$PWD"
fi

# Determine project name from project directory (same logic as initialize_environment)
PROJECT_NAME=$(basename "$PROJECT_DIR")
if [[ "$PROJECT_NAME" == "$HOME" ]] || [[ -z "$PROJECT_NAME" ]] || [[ "$PROJECT_NAME" == "/" ]]; then
  PROJECT_NAME="default"
fi

# Default: save to global config directory
GLOBAL_CONFIG_DIR="${HOME}/.orodc/${PROJECT_NAME}"
mkdir -p "$GLOBAL_CONFIG_DIR"
GLOBAL_ENV_FILE="${GLOBAL_CONFIG_DIR}/.env.orodc"

# Local project file (absolute path)
LOCAL_ENV_FILE="${PROJECT_DIR}/.env.orodc"

# Determine which config file to use for loading existing values
# Priority: local > global
# Also check for old format global config and migrate it
ENV_FILE=""
if [[ -f "$LOCAL_ENV_FILE" ]]; then
  ENV_FILE="$LOCAL_ENV_FILE"
  msg_info "Found local configuration: $LOCAL_ENV_FILE"
elif [[ -f "$GLOBAL_ENV_FILE" ]]; then
  ENV_FILE="$GLOBAL_ENV_FILE"
  msg_info "Found global configuration: $GLOBAL_ENV_FILE"
else
  # Check for old format global config (without subdirectory)
  OLD_GLOBAL_ENV_FILE="${HOME}/.orodc/${PROJECT_NAME}.env.orodc"
  if [[ -f "$OLD_GLOBAL_ENV_FILE" ]]; then
    # Migrate old format to new format
    mkdir -p "$(dirname "$GLOBAL_ENV_FILE")"
    mv "$OLD_GLOBAL_ENV_FILE" "$GLOBAL_ENV_FILE"
    msg_info "Migrated configuration from old format to: $GLOBAL_ENV_FILE"
    ENV_FILE="$GLOBAL_ENV_FILE"
  fi
fi

# Load existing configuration if available
EXISTING_PHP_VERSION=""
EXISTING_NODE_VERSION=""
EXISTING_COMPOSER_VERSION=""
EXISTING_PHP_IMAGE=""
EXISTING_DB_SCHEMA=""
EXISTING_DB_VERSION=""
EXISTING_DB_IMAGE=""
EXISTING_SEARCH_ENGINE=""
EXISTING_SEARCH_VERSION=""
EXISTING_SEARCH_IMAGE=""
EXISTING_CACHE_ENGINE=""
EXISTING_CACHE_VERSION=""
EXISTING_CACHE_IMAGE=""
EXISTING_RABBITMQ_VERSION=""
EXISTING_RABBITMQ_IMAGE=""

if [[ -f "$ENV_FILE" ]]; then
  msg_info "Found existing configuration, loading current values..."
  
  # Source the file to load variables
  while IFS='=' read -r key value; do
    # Skip comments and empty lines
    [[ "$key" =~ ^#.*$ ]] && continue
    [[ -z "$key" ]] && continue
    
    # Remove quotes if present
    value="${value%\"}"
    value="${value#\"}"
    value="${value%\'}"
    value="${value#\'}"
    
    case "$key" in
      DC_ORO_PHP_VERSION) EXISTING_PHP_VERSION="$value" ;;
      DC_ORO_NODE_VERSION) EXISTING_NODE_VERSION="$value" ;;
      DC_ORO_COMPOSER_VERSION) EXISTING_COMPOSER_VERSION="$value" ;;
      DC_ORO_PHP_IMAGE) EXISTING_PHP_IMAGE="$value" ;;
      DC_ORO_DATABASE_SCHEMA) EXISTING_DB_SCHEMA="$value" ;;
      DC_ORO_DATABASE_VERSION) EXISTING_DB_VERSION="$value" ;;
      DC_ORO_DATABASE_IMAGE) EXISTING_DB_IMAGE="$value" ;;
      DC_ORO_SEARCH_ENGINE) EXISTING_SEARCH_ENGINE="$value" ;;
      DC_ORO_SEARCH_VERSION) EXISTING_SEARCH_VERSION="$value" ;;
      DC_ORO_SEARCH_IMAGE) EXISTING_SEARCH_IMAGE="$value" ;;
      DC_ORO_CACHE_ENGINE) EXISTING_CACHE_ENGINE="$value" ;;
      DC_ORO_CACHE_VERSION) EXISTING_CACHE_VERSION="$value" ;;
      DC_ORO_CACHE_IMAGE) EXISTING_CACHE_IMAGE="$value" ;;
      DC_ORO_RABBITMQ_VERSION) EXISTING_RABBITMQ_VERSION="$value" ;;
      DC_ORO_RABBITMQ_IMAGE) EXISTING_RABBITMQ_IMAGE="$value" ;;
    esac
  done < "$ENV_FILE"
  
  echo ""
fi

# Initialize wizard
wizard_init "OroDC Interactive Configuration"

# Page 1: PHP Configuration
init_page_php() {
  msg_header "1. PHP Configuration"
  echo "" >&2
  
  # Get or set values from wizard data
  local SELECTED_PHP=$(wizard_get "SELECTED_PHP" "${EXISTING_PHP_VERSION:-8.4}")
  local SELECTED_NODE=$(wizard_get "SELECTED_NODE" "${EXISTING_NODE_VERSION:-22}")
  local SELECTED_COMPOSER=$(wizard_get "SELECTED_COMPOSER" "${EXISTING_COMPOSER_VERSION:-2}")
  local SELECTED_PHP_IMAGE=$(wizard_get "SELECTED_PHP_IMAGE" "$EXISTING_PHP_IMAGE")
  
  # Determine if using custom image
  USE_CUSTOM_PHP=false
  if [[ -n "$SELECTED_PHP_IMAGE" ]] && [[ ! "$SELECTED_PHP_IMAGE" =~ ^ghcr\.io/digitalspacestdio/orodc-php-node-symfony: ]]; then
    USE_CUSTOM_PHP=true
  fi
  
  if prompt_yes_no "Use custom PHP image?" "$([ "$USE_CUSTOM_PHP" = true ] && echo yes || echo no)"; then
    >&2 echo -n "Enter custom PHP image$([ -n "$SELECTED_PHP_IMAGE" ] && echo " [current: $SELECTED_PHP_IMAGE]" || echo ""): "
    read SELECTED_PHP_IMAGE </dev/tty
    # If empty, keep existing
    if [[ -z "$SELECTED_PHP_IMAGE" ]] && [[ -n "$EXISTING_PHP_IMAGE" ]]; then
      SELECTED_PHP_IMAGE="$EXISTING_PHP_IMAGE"
    fi
    # Extract versions from custom image if possible (or use defaults/existing)
    SELECTED_PHP="${EXISTING_PHP_VERSION:-8.4}"
    SELECTED_NODE="${EXISTING_NODE_VERSION:-22}"
    SELECTED_COMPOSER="${EXISTING_COMPOSER_VERSION:-2}"
  else
    # Select PHP version (sorted newest to oldest)
    PHP_VERSIONS=("8.5" "8.4" "8.3" "8.2" "8.1" "7.4" "7.3")
    DEFAULT_PHP="${SELECTED_PHP:-${EXISTING_PHP_VERSION:-8.4}}"
    SELECTED_PHP=$(prompt_select "Select PHP version:" "$DEFAULT_PHP" "${PHP_VERSIONS[@]}")
    
    # Select Node.js version (based on PHP compatibility)
    read -ra COMPATIBLE_NODE_VERSIONS <<< "$(get_compatible_node_versions "$SELECTED_PHP")"
    
    # Determine default Node.js version based on PHP or existing config
    if [[ -n "$EXISTING_NODE_VERSION" ]] && [[ " ${COMPATIBLE_NODE_VERSIONS[*]} " =~ " ${EXISTING_NODE_VERSION} " ]]; then
      DEFAULT_NODE="$EXISTING_NODE_VERSION"
    else
      case "$SELECTED_PHP" in
        8.5) DEFAULT_NODE="24" ;;
        8.4) DEFAULT_NODE="22" ;;
        8.1|8.2|8.3) DEFAULT_NODE="20" ;;
        7.3|7.4) DEFAULT_NODE="16" ;;
        *) DEFAULT_NODE="22" ;;
      esac
      
      # Ensure default is in compatible versions list
      if [[ ! " ${COMPATIBLE_NODE_VERSIONS[*]} " =~ " ${DEFAULT_NODE} " ]]; then
        DEFAULT_NODE="${COMPATIBLE_NODE_VERSIONS[0]}"
      fi
    fi
    
    SELECTED_NODE=$(prompt_select "Select Node.js version (compatible with PHP $SELECTED_PHP):" "${SELECTED_NODE:-$DEFAULT_NODE}" "${COMPATIBLE_NODE_VERSIONS[@]}")
    
    # Select Composer version (only for PHP 7.3, others use Composer 2 automatically)
    if [[ "$SELECTED_PHP" == "7.3" ]]; then
      COMPOSER_VERSIONS=("1" "2")
      DEFAULT_COMPOSER="${SELECTED_COMPOSER:-${EXISTING_COMPOSER_VERSION:-1}}"
      SELECTED_COMPOSER=$(prompt_select "Select Composer version:" "$DEFAULT_COMPOSER" "${COMPOSER_VERSIONS[@]}")
    else
      # PHP 7.4+ always uses Composer 2
      SELECTED_COMPOSER="2"
    fi
    
    # Build default image name
    SELECTED_PHP_IMAGE="ghcr.io/digitalspacestdio/orodc-php-node-symfony:${SELECTED_PHP}-node${SELECTED_NODE}-composer${SELECTED_COMPOSER}-alpine"
  fi
  
  # Save to wizard data
  wizard_set "SELECTED_PHP" "$SELECTED_PHP"
  wizard_set "SELECTED_NODE" "$SELECTED_NODE"
  wizard_set "SELECTED_COMPOSER" "$SELECTED_COMPOSER"
  wizard_set "SELECTED_PHP_IMAGE" "$SELECTED_PHP_IMAGE"
  
  msg_info "PHP Image: $SELECTED_PHP_IMAGE" >&2
  echo "" >&2
  
  # Navigation prompt
  echo -n "Press Enter to continue to Database Configuration, or 'b' to go back: " >&2
  read -r nav_input </dev/tty
  if [[ "$nav_input" == "b" ]] || [[ "$nav_input" == "back" ]]; then
    return 1  # Go back
  fi
  return 0  # Continue to next page
}

# Determine if using custom image
USE_CUSTOM_PHP=false
if [[ -n "$EXISTING_PHP_IMAGE" ]] && [[ ! "$EXISTING_PHP_IMAGE" =~ ^ghcr\.io/digitalspacestdio/orodc-php-node-symfony: ]]; then
  USE_CUSTOM_PHP=true
fi

if prompt_yes_no "Use custom PHP image?" "$([ "$USE_CUSTOM_PHP" = true ] && echo yes || echo no)"; then
  >&2 echo -n "Enter custom PHP image$([ -n "$EXISTING_PHP_IMAGE" ] && echo " [current: $EXISTING_PHP_IMAGE]" || echo ""): "
  read SELECTED_PHP_IMAGE </dev/tty
  # If empty, keep existing
  if [[ -z "$SELECTED_PHP_IMAGE" ]] && [[ -n "$EXISTING_PHP_IMAGE" ]]; then
    SELECTED_PHP_IMAGE="$EXISTING_PHP_IMAGE"
  fi
  # Extract versions from custom image if possible (or use defaults/existing)
  SELECTED_PHP="${EXISTING_PHP_VERSION:-8.4}"
  SELECTED_NODE="${EXISTING_NODE_VERSION:-22}"
  SELECTED_COMPOSER="${EXISTING_COMPOSER_VERSION:-2}"
else
  # Select PHP version (sorted newest to oldest)
  PHP_VERSIONS=("8.5" "8.4" "8.3" "8.2" "8.1" "7.4" "7.3")
  DEFAULT_PHP="${EXISTING_PHP_VERSION:-8.4}"
  SELECTED_PHP=$(prompt_select "Select PHP version:" "$DEFAULT_PHP" "${PHP_VERSIONS[@]}")
  
  if [[ -n "${DEBUG:-}" ]]; then
    >&2 echo "DEBUG: Selected PHP: '$SELECTED_PHP'"
  fi
  
  # Select Node.js version (based on PHP compatibility)
  read -ra COMPATIBLE_NODE_VERSIONS <<< "$(get_compatible_node_versions "$SELECTED_PHP")"
  
  # Determine default Node.js version based on PHP or existing config
  if [[ -n "$EXISTING_NODE_VERSION" ]] && [[ " ${COMPATIBLE_NODE_VERSIONS[*]} " =~ " ${EXISTING_NODE_VERSION} " ]]; then
    DEFAULT_NODE="$EXISTING_NODE_VERSION"
  else
    case "$SELECTED_PHP" in
      8.5) DEFAULT_NODE="24" ;;
      8.4) DEFAULT_NODE="22" ;;
      8.1|8.2|8.3) DEFAULT_NODE="20" ;;
      7.3|7.4) DEFAULT_NODE="16" ;;
      *) DEFAULT_NODE="22" ;;
    esac
    
    # Ensure default is in compatible versions list
    if [[ ! " ${COMPATIBLE_NODE_VERSIONS[*]} " =~ " ${DEFAULT_NODE} " ]]; then
      DEFAULT_NODE="${COMPATIBLE_NODE_VERSIONS[0]}"
    fi
  fi
  
  SELECTED_NODE=$(prompt_select "Select Node.js version (compatible with PHP $SELECTED_PHP):" "$DEFAULT_NODE" "${COMPATIBLE_NODE_VERSIONS[@]}")
  
  if [[ -n "${DEBUG:-}" ]]; then
    >&2 echo "DEBUG: Selected Node.js: '$SELECTED_NODE'"
  fi
  
  # Select Composer version (only for PHP 7.3, others use Composer 2 automatically)
  if [[ "$SELECTED_PHP" == "7.3" ]]; then
    COMPOSER_VERSIONS=("1" "2")
    # Default Composer version for PHP 7.3
    if [[ -n "$EXISTING_COMPOSER_VERSION" ]]; then
      DEFAULT_COMPOSER="$EXISTING_COMPOSER_VERSION"
    else
      DEFAULT_COMPOSER="1"
    fi
    
    SELECTED_COMPOSER=$(prompt_select "Select Composer version:" "$DEFAULT_COMPOSER" "${COMPOSER_VERSIONS[@]}")
    
    if [[ -n "${DEBUG:-}" ]]; then
      >&2 echo "DEBUG: Selected Composer: '$SELECTED_COMPOSER'"
    fi
  else
    # PHP 7.4+ always uses Composer 2
    SELECTED_COMPOSER="2"
    if [[ -n "${DEBUG:-}" ]]; then
      >&2 echo "DEBUG: Using Composer 2 (automatic for PHP $SELECTED_PHP)"
    fi
  fi
  
  # Build default image name
  SELECTED_PHP_IMAGE="ghcr.io/digitalspacestdio/orodc-php-node-symfony:${SELECTED_PHP}-node${SELECTED_NODE}-composer${SELECTED_COMPOSER}-alpine"
fi

msg_info "PHP Image: $SELECTED_PHP_IMAGE"

# 2. Database Configuration
echo ""
msg_header "2. Database Configuration"

# Determine if using custom database image
USE_CUSTOM_DB=false
if [[ -n "$EXISTING_DB_IMAGE" ]] && [[ ! "$EXISTING_DB_IMAGE" =~ ^(ghcr\.io/digitalspacestdio/orodc-pgsql:|mysql:) ]]; then
  USE_CUSTOM_DB=true
fi

if prompt_yes_no "Use custom database image?" "$([ "$USE_CUSTOM_DB" = true ] && echo yes || echo no)"; then
  >&2 echo -n "Enter custom database image$([ -n "$EXISTING_DB_IMAGE" ] && echo " [current: $EXISTING_DB_IMAGE]" || echo ""): "
  read SELECTED_DB_IMAGE </dev/tty
  # If empty, keep existing
  if [[ -z "$SELECTED_DB_IMAGE" ]] && [[ -n "$EXISTING_DB_IMAGE" ]]; then
    SELECTED_DB_IMAGE="$EXISTING_DB_IMAGE"
  fi
  SELECTED_DB_SCHEMA="${EXISTING_DB_SCHEMA:-pgsql}"
  SELECTED_DB_VERSION="${EXISTING_DB_VERSION:-custom}"
else
  # Select database type based on existing or default
  DB_TYPES=("PostgreSQL" "MySQL")
  if [[ "$EXISTING_DB_SCHEMA" == "mysql" ]]; then
    DEFAULT_DB_TYPE="MySQL"
  else
    DEFAULT_DB_TYPE="PostgreSQL"
  fi
  SELECTED_DB_TYPE=$(prompt_select "Select database type:" "$DEFAULT_DB_TYPE" "${DB_TYPES[@]}")
  
  if [[ -n "${DEBUG:-}" ]]; then
    >&2 echo "DEBUG: Selected DB type: '$SELECTED_DB_TYPE'"
  fi
  
  # Select version based on type (sorted newest to oldest)
  if [[ "$SELECTED_DB_TYPE" == "PostgreSQL" ]]; then
    PGSQL_VERSIONS=("17.4" "16.6" "15.1")
    # Only use existing version if it's valid for PostgreSQL and schema hasn't changed
    if [[ "$EXISTING_DB_SCHEMA" == "pgsql" ]] && [[ " ${PGSQL_VERSIONS[*]} " =~ " ${EXISTING_DB_VERSION} " ]]; then
      DEFAULT_PGSQL_VERSION="$EXISTING_DB_VERSION"
    else
      DEFAULT_PGSQL_VERSION="17.4"
    fi
    SELECTED_DB_VERSION=$(prompt_select "Select PostgreSQL version:" "$DEFAULT_PGSQL_VERSION" "${PGSQL_VERSIONS[@]}")
    SELECTED_DB_SCHEMA="pgsql"
    SELECTED_DB_IMAGE="ghcr.io/digitalspacestdio/orodc-pgsql:${SELECTED_DB_VERSION}"
  else
    MYSQL_VERSIONS=("9.0" "8.4" "8.0" "5.7")
    # Only use existing version if it's valid for MySQL and schema hasn't changed
    if [[ "$EXISTING_DB_SCHEMA" == "mysql" ]] && [[ " ${MYSQL_VERSIONS[*]} " =~ " ${EXISTING_DB_VERSION} " ]]; then
      DEFAULT_MYSQL_VERSION="$EXISTING_DB_VERSION"
    else
      DEFAULT_MYSQL_VERSION="8.4"
    fi
    SELECTED_DB_VERSION=$(prompt_select "Select MySQL version:" "$DEFAULT_MYSQL_VERSION" "${MYSQL_VERSIONS[@]}")
    SELECTED_DB_SCHEMA="mysql"
    SELECTED_DB_IMAGE="mysql:${SELECTED_DB_VERSION}"
  fi
fi

msg_info "Database Image: $SELECTED_DB_IMAGE"

# 3. Search Engine Configuration
echo ""
msg_header "3. Search Engine Configuration"

# Determine if using custom search image
USE_CUSTOM_SEARCH=false
if [[ -n "$EXISTING_SEARCH_IMAGE" ]] && [[ ! "$EXISTING_SEARCH_IMAGE" =~ ^(docker\.elastic\.co/elasticsearch/elasticsearch:|opensearchproject/opensearch:) ]]; then
  USE_CUSTOM_SEARCH=true
fi

if prompt_yes_no "Use custom search engine image?" "$([ "$USE_CUSTOM_SEARCH" = true ] && echo yes || echo no)"; then
  >&2 echo -n "Enter custom search image$([ -n "$EXISTING_SEARCH_IMAGE" ] && echo " [current: $EXISTING_SEARCH_IMAGE]" || echo ""): "
  read SELECTED_SEARCH_IMAGE </dev/tty
  # If empty, keep existing
  if [[ -z "$SELECTED_SEARCH_IMAGE" ]] && [[ -n "$EXISTING_SEARCH_IMAGE" ]]; then
    SELECTED_SEARCH_IMAGE="$EXISTING_SEARCH_IMAGE"
  fi
  SELECTED_SEARCH_TYPE="${EXISTING_SEARCH_ENGINE:-Custom}"
  SELECTED_SEARCH_VERSION="${EXISTING_SEARCH_VERSION:-custom}"
else
  # Select search engine type based on existing or default
  SEARCH_TYPES=("Elasticsearch" "OpenSearch")
  DEFAULT_SEARCH_TYPE="${EXISTING_SEARCH_ENGINE:-Elasticsearch}"
  SELECTED_SEARCH_TYPE=$(prompt_select "Select search engine:" "$DEFAULT_SEARCH_TYPE" "${SEARCH_TYPES[@]}")
  
  # Select version based on type (sorted newest to oldest)
  if [[ "$SELECTED_SEARCH_TYPE" == "Elasticsearch" ]]; then
    ELASTIC_VERSIONS=("8.15.0" "8.10.3" "7.17.0")
    # Only use existing version if it's valid for Elasticsearch and type hasn't changed
    if [[ "$EXISTING_SEARCH_ENGINE" == "Elasticsearch" ]] && [[ " ${ELASTIC_VERSIONS[*]} " =~ " ${EXISTING_SEARCH_VERSION} " ]]; then
      DEFAULT_ELASTIC_VERSION="$EXISTING_SEARCH_VERSION"
    else
      DEFAULT_ELASTIC_VERSION="8.15.0"
    fi
    SELECTED_SEARCH_VERSION=$(prompt_select "Select Elasticsearch version:" "$DEFAULT_ELASTIC_VERSION" "${ELASTIC_VERSIONS[@]}")
    SELECTED_SEARCH_IMAGE="docker.elastic.co/elasticsearch/elasticsearch:${SELECTED_SEARCH_VERSION}"
  else
    OPENSEARCH_VERSIONS=("3.3.0" "3.0.0" "2.15.0" "2.11.0" "1.3.0")
    # Only use existing version if it's valid for OpenSearch and type hasn't changed
    if [[ "$EXISTING_SEARCH_ENGINE" == "OpenSearch" ]] && [[ " ${OPENSEARCH_VERSIONS[*]} " =~ " ${EXISTING_SEARCH_VERSION} " ]]; then
      DEFAULT_OPENSEARCH_VERSION="$EXISTING_SEARCH_VERSION"
    else
      DEFAULT_OPENSEARCH_VERSION="3.3.0"
    fi
    SELECTED_SEARCH_VERSION=$(prompt_select "Select OpenSearch version:" "$DEFAULT_OPENSEARCH_VERSION" "${OPENSEARCH_VERSIONS[@]}")
    SELECTED_SEARCH_IMAGE="opensearchproject/opensearch:${SELECTED_SEARCH_VERSION}"
  fi
fi

msg_info "Search Image: $SELECTED_SEARCH_IMAGE"

# 4. Cache Configuration
echo ""
msg_header "4. Cache Configuration"

# Determine if using custom cache image
USE_CUSTOM_CACHE=false
if [[ -n "$EXISTING_CACHE_IMAGE" ]] && [[ ! "$EXISTING_CACHE_IMAGE" =~ ^(redis:|eqalpha/keydb:|valkey/valkey:) ]]; then
  USE_CUSTOM_CACHE=true
fi

if prompt_yes_no "Use custom cache image?" "$([ "$USE_CUSTOM_CACHE" = true ] && echo yes || echo no)"; then
  >&2 echo -n "Enter custom cache image$([ -n "$EXISTING_CACHE_IMAGE" ] && echo " [current: $EXISTING_CACHE_IMAGE]" || echo ""): "
  read SELECTED_CACHE_IMAGE </dev/tty
  # If empty, keep existing
  if [[ -z "$SELECTED_CACHE_IMAGE" ]] && [[ -n "$EXISTING_CACHE_IMAGE" ]]; then
    SELECTED_CACHE_IMAGE="$EXISTING_CACHE_IMAGE"
  fi
  SELECTED_CACHE_TYPE="${EXISTING_CACHE_ENGINE:-Custom}"
  SELECTED_CACHE_VERSION="${EXISTING_CACHE_VERSION:-custom}"
else
  # Select cache engine type based on existing or default
  CACHE_TYPES=("Redis" "Valkey" "KeyDB")
  DEFAULT_CACHE_TYPE="${EXISTING_CACHE_ENGINE:-Redis}"
  SELECTED_CACHE_TYPE=$(prompt_select "Select cache engine:" "$DEFAULT_CACHE_TYPE" "${CACHE_TYPES[@]}")
  
  # Select version based on type (sorted newest to oldest)
  if [[ "$SELECTED_CACHE_TYPE" == "Redis" ]]; then
    REDIS_VERSIONS=("7.4" "7.2" "6.2")
    # Only use existing version if it's valid for Redis and type hasn't changed
    if [[ "$EXISTING_CACHE_ENGINE" == "Redis" ]] && [[ " ${REDIS_VERSIONS[*]} " =~ " ${EXISTING_CACHE_VERSION} " ]]; then
      DEFAULT_REDIS_VERSION="$EXISTING_CACHE_VERSION"
    else
      DEFAULT_REDIS_VERSION="7.4"
    fi
    SELECTED_CACHE_VERSION=$(prompt_select "Select Redis version:" "$DEFAULT_REDIS_VERSION" "${REDIS_VERSIONS[@]}")
    SELECTED_CACHE_IMAGE="redis:${SELECTED_CACHE_VERSION}-alpine"
  elif [[ "$SELECTED_CACHE_TYPE" == "Valkey" ]]; then
    VALKEY_VERSIONS=("9.0" "8.0" "7.2")
    # Only use existing version if it's valid for Valkey and type hasn't changed
    if [[ "$EXISTING_CACHE_ENGINE" == "Valkey" ]] && [[ " ${VALKEY_VERSIONS[*]} " =~ " ${EXISTING_CACHE_VERSION} " ]]; then
      DEFAULT_VALKEY_VERSION="$EXISTING_CACHE_VERSION"
    else
      DEFAULT_VALKEY_VERSION="9.0"
    fi
    SELECTED_CACHE_VERSION=$(prompt_select "Select Valkey version:" "$DEFAULT_VALKEY_VERSION" "${VALKEY_VERSIONS[@]}")
    SELECTED_CACHE_IMAGE="valkey/valkey:${SELECTED_CACHE_VERSION}"
  else
    KEYDB_VERSIONS=("6.3.4" "6.3.3")
    # Only use existing version if it's valid for KeyDB and type hasn't changed
    if [[ "$EXISTING_CACHE_ENGINE" == "KeyDB" ]] && [[ " ${KEYDB_VERSIONS[*]} " =~ " ${EXISTING_CACHE_VERSION} " ]]; then
      DEFAULT_KEYDB_VERSION="$EXISTING_CACHE_VERSION"
    else
      DEFAULT_KEYDB_VERSION="6.3.4"
    fi
    SELECTED_CACHE_VERSION=$(prompt_select "Select KeyDB version:" "$DEFAULT_KEYDB_VERSION" "${KEYDB_VERSIONS[@]}")
    SELECTED_CACHE_IMAGE="eqalpha/keydb:alpine_x86_64_v${SELECTED_CACHE_VERSION}"
  fi
fi

msg_info "Cache Image: $SELECTED_CACHE_IMAGE"

# 5. RabbitMQ Configuration
echo ""
msg_header "5. RabbitMQ Configuration"

# Determine if using custom RabbitMQ image
USE_CUSTOM_RABBITMQ=false
if [[ -n "$EXISTING_RABBITMQ_IMAGE" ]] && [[ ! "$EXISTING_RABBITMQ_IMAGE" =~ ^rabbitmq: ]]; then
  USE_CUSTOM_RABBITMQ=true
fi

if prompt_yes_no "Use custom RabbitMQ image?" "$([ "$USE_CUSTOM_RABBITMQ" = true ] && echo yes || echo no)"; then
  >&2 echo -n "Enter custom RabbitMQ image$([ -n "$EXISTING_RABBITMQ_IMAGE" ] && echo " [current: $EXISTING_RABBITMQ_IMAGE]" || echo ""): "
  read SELECTED_RABBITMQ_IMAGE </dev/tty
  # If empty, keep existing
  if [[ -z "$SELECTED_RABBITMQ_IMAGE" ]] && [[ -n "$EXISTING_RABBITMQ_IMAGE" ]]; then
    SELECTED_RABBITMQ_IMAGE="$EXISTING_RABBITMQ_IMAGE"
  fi
  SELECTED_RABBITMQ_VERSION="${EXISTING_RABBITMQ_VERSION:-custom}"
else
  # Select RabbitMQ version based on existing or default
  RABBITMQ_VERSIONS=("3.13" "3.12" "3.11")
  DEFAULT_RABBITMQ_VERSION="${EXISTING_RABBITMQ_VERSION:-3.13}"
  SELECTED_RABBITMQ_VERSION=$(prompt_select "Select RabbitMQ version:" "$DEFAULT_RABBITMQ_VERSION" "${RABBITMQ_VERSIONS[@]}")
  SELECTED_RABBITMQ_IMAGE="rabbitmq:${SELECTED_RABBITMQ_VERSION}-management-alpine"
fi

msg_info "RabbitMQ Image: $SELECTED_RABBITMQ_IMAGE"

# Summary
echo ""
msg_header "Configuration Summary"
echo "PHP Version: $SELECTED_PHP"
echo "Node.js Version: $SELECTED_NODE"
echo "Composer Version: $SELECTED_COMPOSER"
echo "PHP Image: $SELECTED_PHP_IMAGE"
echo "Database: $SELECTED_DB_TYPE $SELECTED_DB_VERSION"
echo "Database Image: $SELECTED_DB_IMAGE"
echo "Search Engine: $SELECTED_SEARCH_TYPE $SELECTED_SEARCH_VERSION"
echo "Search Image: $SELECTED_SEARCH_IMAGE"
echo "Cache: $SELECTED_CACHE_TYPE $SELECTED_CACHE_VERSION"
echo "Cache Image: $SELECTED_CACHE_IMAGE"
echo "RabbitMQ: $SELECTED_RABBITMQ_VERSION"
echo "RabbitMQ Image: $SELECTED_RABBITMQ_IMAGE"
echo ""

# Ask where to save configuration
# Show relative path for local file if we're in project directory
LOCAL_ENV_DISPLAY=".env.orodc"
if [[ "$PROJECT_DIR" != "$PWD" ]]; then
  LOCAL_ENV_DISPLAY="$LOCAL_ENV_FILE"
fi

# First ask: save to project directory (default: no)
SAVE_TO_PROJECT=false
TARGET_ENV_FILE=""
if prompt_yes_no "Save configuration to project directory ($LOCAL_ENV_DISPLAY)?" "no"; then
  SAVE_TO_PROJECT=true
  TARGET_ENV_FILE="$LOCAL_ENV_FILE"
else
  # User declined project directory, save to global config automatically
  TARGET_ENV_FILE="$GLOBAL_ENV_FILE"
  msg_info "Configuration will be saved to: $TARGET_ENV_FILE"
fi

# Save configuration to selected file
if [[ -n "$TARGET_ENV_FILE" ]]; then
  # Always ensure directory exists before saving
  mkdir -p "$(dirname "$TARGET_ENV_FILE")"
  
  # Create backup if file exists
  if [[ -f "$TARGET_ENV_FILE" ]]; then
    cp "$TARGET_ENV_FILE" "${TARGET_ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    msg_info "Backup created: ${TARGET_ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
  else
    # Create new file with header
    cat > "$TARGET_ENV_FILE" << EOF
# OroDC Configuration
# Generated by 'orodc init' on $(date)
# Project: $PROJECT_NAME

EOF
  fi
  
  # Update configuration variables (preserves other variables)
  msg_info "Updating configuration..."
  
  # Update header comment if this is a new init
  if ! grep -q "# Last updated:" "$TARGET_ENV_FILE" 2>/dev/null; then
    if [[ "$(uname)" == "Darwin" ]]; then
      sed -i '' "1i\\
# Last updated: $(date)\\
" "$TARGET_ENV_FILE"
    else
      sed -i "1i# Last updated: $(date)" "$TARGET_ENV_FILE"
    fi
  else
    if [[ "$(uname)" == "Darwin" ]]; then
      sed -i '' "s|^# Last updated:.*|# Last updated: $(date)|" "$TARGET_ENV_FILE"
    else
      sed -i "s|^# Last updated:.*|# Last updated: $(date)|" "$TARGET_ENV_FILE"
    fi
  fi
  
  # PHP Configuration
  update_env_var "$TARGET_ENV_FILE" "DC_ORO_PHP_VERSION" "$SELECTED_PHP"
  update_env_var "$TARGET_ENV_FILE" "DC_ORO_NODE_VERSION" "$SELECTED_NODE"
  update_env_var "$TARGET_ENV_FILE" "DC_ORO_COMPOSER_VERSION" "$SELECTED_COMPOSER"
  update_env_var "$TARGET_ENV_FILE" "DC_ORO_PHP_IMAGE" "$SELECTED_PHP_IMAGE"
  
  # Database Configuration
  update_env_var "$TARGET_ENV_FILE" "DC_ORO_DATABASE_SCHEMA" "$SELECTED_DB_SCHEMA"
  update_env_var "$TARGET_ENV_FILE" "DC_ORO_DATABASE_VERSION" "$SELECTED_DB_VERSION"
  update_env_var "$TARGET_ENV_FILE" "DC_ORO_DATABASE_IMAGE" "$SELECTED_DB_IMAGE"
  
  # Search Engine Configuration
  update_env_var "$TARGET_ENV_FILE" "DC_ORO_SEARCH_ENGINE" "$SELECTED_SEARCH_TYPE"
  update_env_var "$TARGET_ENV_FILE" "DC_ORO_SEARCH_VERSION" "$SELECTED_SEARCH_VERSION"
  update_env_var "$TARGET_ENV_FILE" "DC_ORO_SEARCH_IMAGE" "$SELECTED_SEARCH_IMAGE"
  
  # Cache Configuration
  update_env_var "$TARGET_ENV_FILE" "DC_ORO_CACHE_ENGINE" "$SELECTED_CACHE_TYPE"
  update_env_var "$TARGET_ENV_FILE" "DC_ORO_CACHE_VERSION" "$SELECTED_CACHE_VERSION"
  update_env_var "$TARGET_ENV_FILE" "DC_ORO_CACHE_IMAGE" "$SELECTED_CACHE_IMAGE"
  
  # RabbitMQ Configuration
  update_env_var "$TARGET_ENV_FILE" "DC_ORO_RABBITMQ_VERSION" "$SELECTED_RABBITMQ_VERSION"
  update_env_var "$TARGET_ENV_FILE" "DC_ORO_RABBITMQ_IMAGE" "$SELECTED_RABBITMQ_IMAGE"
  
  msg_ok "Configuration saved to $TARGET_ENV_FILE"
  msg_info "All other variables in the file were preserved"
  if [[ "$SAVE_TO_PROJECT" == "true" ]]; then
    msg_info "Local configuration will take priority over global configuration"
  else
    msg_info "Global configuration will be used (local .env.orodc takes priority if exists)"
  fi
  msg_info "You can now run 'orodc install' to set up your environment"
else
  msg_info "Configuration not saved"
fi
