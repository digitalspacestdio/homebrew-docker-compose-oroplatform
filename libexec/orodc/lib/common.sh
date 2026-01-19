#!/bin/bash
# Common Functions Library
# Provides basic utilities: logging, timing, env vars, binary resolution

# Debug logging to file (always enabled for debugging menu issues)
DEBUG_LOG="/tmp/orodc-debug.log"
debug_log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$DEBUG_LOG"
}

# Clear log on new session (only once per process tree)
if [[ "${ORODC_LOG_CLEARED:-}" != "1" ]]; then
  echo "=== New orodc session $(date '+%Y-%m-%d %H:%M:%S') ===" > "$DEBUG_LOG"
  export ORODC_LOG_CLEARED=1
fi

# Setup logging only when OroDC is used as PHP binary
setup_php_logging() {
  mkdir -p /tmp/.orodc
  local log_file="/tmp/.orodc/$(basename $0).$(echo "$@" | md5sum - | awk '{ print $1 }').log"
  local err_file="/tmp/.orodc/$(basename $0).$(echo "$@" | md5sum - | awk '{ print $1 }').err"
  touch "$log_file" "$err_file"
  exec 1> >(tee "$log_file")
  exec 2> >(tee "$err_file")
}

# Command timing functions
get_timing_log_file() {
  local timing_dir="${HOME}/.orodc"
  mkdir -p "$timing_dir"
  echo "${timing_dir}/.timing-log"
}

get_previous_timing() {
  local command=$1
  local timing_file=$(get_timing_log_file)

  if [[ -f "$timing_file" ]]; then
    grep "^${command}:" "$timing_file" 2>/dev/null | tail -1 | cut -d: -f2
  fi
}

save_timing() {
  local command=$1
  local duration=$2
  local timing_file=$(get_timing_log_file)

  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "${command}:${duration}:${timestamp}" >> "$timing_file"
}

# Function to update or add environment variable in .env.orodc file
update_env_var() {
  local file="$1"
  local key="$2"
  local value="$3"

  if [[ -f "$file" ]]; then
    if grep -q "^${key}=" "$file"; then
      sed -i.tmp "s|^${key}=.*|${key}=${value}|" "$file"
      rm -f "${file}.tmp"
    else
      echo "${key}=${value}" >> "$file"
    fi
  else
    echo "${key}=${value}" >> "$file"
  fi
}

# Function to resolve binary location with error handling
# Usage: resolve_bin "binary_name" ["install_instructions"]
resolve_bin() {
  local bin_name="$1"
  local install_msg="${2:-}"
  local found_path=""

  # Try PATH first
  if command -v "$bin_name" >/dev/null 2>&1; then
    found_path=$(command -v "$bin_name")
    if [ "$DEBUG" ]; then echo "DEBUG: Found $bin_name in PATH: $found_path" >&2; fi
    echo "$found_path"
    return 0
  fi

  # Try common locations for specific binaries
  case "$bin_name" in
    "brew")
      local brew_paths=("/opt/homebrew/bin/brew" "/usr/local/bin/brew" "/home/linuxbrew/.linuxbrew/bin/brew")
      for brew_path in "${brew_paths[@]}"; do
        if [[ -x "$brew_path" ]]; then
          found_path="$brew_path"
          msg_warning "$bin_name found at $found_path but not in PATH"
          echo "   Add to PATH: export PATH=\"$(dirname "$found_path"):\$PATH\"" >&2
          echo "$found_path"
          return 0
        fi
      done
      ;;
    "docker")
      local docker_paths=("/usr/bin/docker" "/usr/local/bin/docker" "/snap/bin/docker")
      for docker_path in "${docker_paths[@]}"; do
        if [[ -x "$docker_path" ]]; then
          found_path="$docker_path"
          msg_warning "$bin_name found at $found_path but not in PATH"
          echo "$found_path"
          return 0
        fi
      done
      ;;
  esac

  # Not found - show error and exit
  msg_error "$bin_name not found in PATH or common locations"

  if [[ -n "$install_msg" ]]; then
    echo "   $install_msg"
  else
    # Default install instructions
    case "$bin_name" in
      "docker")
        echo "   Install: curl -fsSL https://get.docker.com | sh"
        echo "   Or visit: https://docs.docker.com/engine/install/"
        ;;
      "brew")
        echo "   Install: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        echo "   Then add to PATH: export PATH=\"/home/linuxbrew/.linuxbrew/bin:\$PATH\""
        ;;
      "rsync")
        echo "   Install: sudo apt-get install rsync  # Ubuntu/Debian"
        echo "   Or: brew install rsync"
        ;;
      "jq")
        echo "   Install: sudo apt-get install jq  # Ubuntu/Debian"
        echo "   Or: brew install jq"
        ;;
      *)
        echo "   Please install $bin_name and ensure it's in your PATH"
        ;;
    esac
  fi

  echo
  msg_error "OroDC cannot continue without $bin_name"
  exit 1
}

# Get first non-flag argument from args array
get_first_non_flag_arg() {
  local args=("$@")
  for arg in "${args[@]}"; do
    if [[ "$arg" != -* ]]; then
      echo "$arg"
      return 0
    fi
  done
  echo ""
}

# Parse DSN URI and extract components
# Usage: parse_dsn_uri "dsn_uri" "component_prefix" "env_prefix"
# Example: parse_dsn_uri "postgres://user:pass@host:5432/db" "database" "DC_ORO"
# Sets: DC_ORO_DATABASE_SCHEMA, DC_ORO_DATABASE_HOST, DC_ORO_DATABASE_PORT, etc.
parse_dsn_uri() {
  local uri="$1"
  local name="$2"
  local prefix="$3"

  [[ -n "$uri" && -n "$name" ]] || return 0

  local host_alias
  host_alias=$(echo "$name" | tr '[:upper:]' '[:lower:]')

  local var_prefix=""
  if [[ -n "$prefix" ]]; then
    var_prefix="$(echo "$prefix" | tr '[:lower:]' '[:upper:]')_"
  fi
  var_prefix+=$(echo "$name" | tr '[:lower:]' '[:upper:]')_

  local schema rest
  if [[ "$uri" == *"://"* ]]; then
    schema="${uri%%://*}"
    rest="${uri#*://}"
  elif [[ "$uri" == *: ]]; then
    schema="${uri%:}"
    rest=""
  else
    schema="$uri"
    rest=""
  fi

  local query=""
  if [[ "$rest" == *\?* ]]; then
    query="${rest#*\?}"
    rest="${rest%%\?*}"
  fi

  local user="" password="" host="" port="" dbname=""

  # Special case: SQLite
  if [[ "$schema" == "sqlite" ]]; then
    if [[ "$uri" == "sqlite::memory:" ]]; then
      dbname=":memory:"
    else
      local sqlite_path="${uri#sqlite://}"
      dbname="${sqlite_path%%\?*}"
    fi

    eval "export ${var_prefix}SCHEMA=\"\$schema\""
    eval "export ${var_prefix}DBNAME=\"\$dbname\""
    eval "export ${var_prefix}QUERY=\"\$query\""
    eval "export ${var_prefix}URI=\"\$uri\""
    return
  fi

  # If rest includes @, extract user/password
  if [[ "$rest" == *@* ]]; then
    local userinfo="${rest%%@*}"
    rest="${rest#*@}"
    user="${userinfo%%:*}"
    password="${userinfo#*:}"
    [[ "$user" == "$password" ]] && password="app"
  fi

  # Extract host, port, dbname
  if [[ "$rest" == *:* ]]; then
    host="${rest%%:*}"
    port="${rest#*:}"
    if [[ "$port" == */* ]]; then
      dbname="${port#*/}"
      port="${port%%/*}"
    fi
  elif [[ "$rest" == */* ]]; then
    host="${rest%%/*}"
    dbname="${rest#*/}"
  elif [[ -n "$rest" ]]; then
    host="$rest"
  fi

  # Always use container host for services (like in monolithic version)
  host="$host_alias"

  # Normalize schema names for database
  if [[ "$name" == "database" ]]; then
    case "$schema" in
      postgres|postgresql|pgsql|pdo_pgsql)
        schema="postgres"
        ;;
      mysql|mariadb|pdo_mysql)
        schema="mysql"
        ;;
    esac
  fi

  # Reconstruct URI only if it's not a simple scheme:
  local clean_uri=""
  if [[ "$schema" == "sqlite" && "$dbname" == ":memory:" ]]; then
    clean_uri="sqlite::memory:"
  elif [[ "$schema" == "sqlite" ]]; then
    clean_uri="sqlite://$dbname"
  elif [[ "$schema" == "dbal" && -z "$rest" ]]; then
    clean_uri="${schema}:"
  else
    clean_uri="${schema}://"
    [[ -n "$user" ]] && clean_uri+="${user}"
    [[ -n "$password" ]] && clean_uri+=":${password}"
    [[ -n "$user" || -n "$password" ]] && clean_uri+="@"
    clean_uri+="${host}"
    [[ -n "$port" ]] && clean_uri+=":${port}"
    [[ -n "$dbname" ]] && clean_uri+="/${dbname}"
    [[ -n "$query" ]] && clean_uri+="?${query}"
  fi

  # Export everything
  eval "export ${var_prefix}SCHEMA=\"\$schema\""
  eval "export ${var_prefix}USER=\"\$user\""
  eval "export ${var_prefix}PASSWORD=\"\$password\""
  eval "export ${var_prefix}HOST=\"\$host\""
  eval "export ${var_prefix}PORT=\"\$port\""
  eval "export ${var_prefix}DBNAME=\"\$dbname\""
  eval "export ${var_prefix}QUERY=\"\$query\""
  eval "export ${var_prefix}URI=\"\$clean_uri\""
  
  debug_log "parse_dsn_uri: parsed $name URI, schema=$schema host=$host port=$port user=$user dbname=$dbname"
}

# Parse compose flags into left/right arrays
# This is a simplified version for compose module
# Usage: parse_compose_flags "$@"
# Sets global arrays: args, left_flags, left_options, right_flags, right_options
parse_compose_flags() {
  args=()
  left_flags=()
  left_options=()
  right_flags=()
  right_options=()

  local i=0
  local saw_first_arg=false
  local args_input=("$@")

  while [[ $i -lt ${#args_input[@]} ]]; do
    arg="${args_input[$i]}"
    next="${args_input[$((i + 1))]:-}"

    if [[ "$arg" == --*=* ]]; then
      # --key=value format
      if [[ "$saw_first_arg" == false ]]; then
        left_options+=("$arg")
      else
        right_options+=("$arg")
      fi
      i=$((i + 1))

    elif [[ "$arg" == --* && "$next" != -* && -n "$next" ]]; then
      # --key value format
      if [[ "$saw_first_arg" == false ]]; then
        left_options+=("$arg" "$next")
      else
        right_options+=("$arg" "$next")
      fi
      i=$((i + 2))

    elif [[ "$arg" == -* ]]; then
      # Single flag -f, -d, etc.
      if [[ "$saw_first_arg" == false ]]; then
        left_flags+=("$arg")
      else
        right_flags+=("$arg")
      fi
      i=$((i + 1))

    else
      # Positional argument (command or service name)
      args+=("$arg")
      saw_first_arg=true
      i=$((i + 1))
    fi
  done
}

# Function to get compatible Node.js versions based on PHP version (sorted newest to oldest)
# Usage: get_compatible_node_versions "php_version"
# Example: get_compatible_node_versions "8.4" returns "22 20 18"
get_compatible_node_versions() {
  local php_ver="$1"
  case "$php_ver" in
    7.3) echo "16" ;;
    7.4) echo "18 16" ;;
    8.1) echo "22 20 18 16" ;;
    8.2|8.3|8.4) echo "22 20 18" ;;
    8.5) echo "24 22" ;;
    *) echo "22 20 18" ;;
  esac
}

# Detect if current project is an Oro Platform application
# Returns 0 (true) if Oro project, 1 (false) otherwise
# Can be overridden with DC_ORO_IS_ORO_PROJECT env var
is_oro_project() {
  # Check for explicit override first
  if [[ -n "${DC_ORO_IS_ORO_PROJECT:-}" ]]; then
    case "${DC_ORO_IS_ORO_PROJECT,,}" in
      1|true|yes)
        return 0
        ;;
      0|false|no)
        return 1
        ;;
    esac
  fi
  
  # Auto-detect from composer.json
  local composer_file="${DC_ORO_APPDIR:-$PWD}/composer.json"
  if [[ ! -f "$composer_file" ]]; then
    return 1
  fi
  
  # Check for Oro ecosystem packages in require section
  # Uses jq if available for reliable JSON parsing
  if command -v jq >/dev/null 2>&1; then
    local oro_packages
    oro_packages=$(jq -r '.require // {} | keys[]' "$composer_file" 2>/dev/null | \
      grep -E '^(oro/platform|oro/commerce|oro/crm|oro/customer-portal|marello/marello)$' | head -1)
    if [[ -n "$oro_packages" ]]; then
      return 0
    fi
  else
    # Fallback: grep-based detection (less reliable but works without jq)
    if grep -qE '"(oro/platform|oro/commerce|oro/crm|oro/customer-portal|marello/marello)"' "$composer_file" 2>/dev/null; then
      return 0
    fi
  fi
  
  return 1
}
