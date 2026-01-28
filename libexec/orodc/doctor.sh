#!/bin/bash
set -e
if [ "$DEBUG" ]; then set -x; fi

# Determine script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/ui.sh"
source "${SCRIPT_DIR}/lib/environment.sh"
source "${SCRIPT_DIR}/lib/docker-utils.sh"

# Check that we're in a project
check_in_project || exit 1

# Parse compose flags
parse_compose_flags "$@"

# Generate compose.yml config file if needed
generate_compose_config_if_needed "ps"

# Find doctor config directory
find_doctor_config_dir() {
  # Get Homebrew prefix dynamically
  local BREW_PREFIX="$(brew --prefix 2>/dev/null || echo "/home/linuxbrew/.linuxbrew")"
  
  # Try paths in order
  local doctor_dir=""
  if [[ -d "${BREW_PREFIX}/Homebrew/Library/Taps/digitalspacestdio/homebrew-docker-compose-oroplatform/compose/docker/doctor" ]]; then
    doctor_dir="${BREW_PREFIX}/Homebrew/Library/Taps/digitalspacestdio/homebrew-docker-compose-oroplatform/compose/docker/doctor"
  elif [[ -d "${BREW_PREFIX}/share/docker-compose-oroplatform/compose/docker/doctor" ]]; then
    doctor_dir="${BREW_PREFIX}/share/docker-compose-oroplatform/compose/docker/doctor"
  elif [[ -d "${SCRIPT_DIR}/../../compose/docker/doctor" ]]; then
    doctor_dir="${SCRIPT_DIR}/../../compose/docker/doctor"
  fi
  
  if [[ -z "$doctor_dir" ]]; then
    msg_warning "Doctor config directory not found, using default configs"
    echo ""
    return 1
  fi
  
  echo "$doctor_dir"
}

# Detect OroPlatform version from composer.json
detect_oro_version() {
  local composer_file="${DC_ORO_APPDIR}/composer.json"
  
  if [[ ! -f "$composer_file" ]]; then
    echo "legacy"
    return 0
  fi
  
  # Try to find oro/platform, oro/commerce, or oro/crm version
  local version=""
  
  # Check for oro/platform
  if command -v jq >/dev/null 2>&1; then
    version=$(jq -r '.require."oro/platform" // .require."oro/commerce" // .require."oro/crm" // empty' "$composer_file" 2>/dev/null || echo "")
  fi
  
  # Fallback to grep if jq not available
  if [[ -z "$version" ]]; then
    version=$(grep -E '"oro/(platform|commerce|crm)"' "$composer_file" 2>/dev/null | head -1 | sed -E 's/.*"oro\/(platform|commerce|crm)"\s*:\s*"([^"]+)".*/\2/' || echo "")
  fi
  
  # Extract major.minor version (e.g., 5.1.0 -> 5.1, 5.0.0-RC1 -> 5.0)
  if [[ -n "$version" ]]; then
    # Remove ^, ~, >=, etc.
    version=$(echo "$version" | sed 's/^[^0-9]*//' | sed 's/-.*$//')
    # Extract major.minor
    local major_minor=$(echo "$version" | grep -oE '^[0-9]+\.[0-9]+' | head -1 || echo "")
    
    if [[ -n "$major_minor" ]]; then
      # Compare version: if >= 6.1, use version-specific configs, otherwise use legacy
      local major=$(echo "$major_minor" | cut -d. -f1)
      local minor=$(echo "$major_minor" | cut -d. -f2)
      
      # Version >= 6.1 uses full checks
      if [[ "$major" -gt 6 ]] || [[ "$major" -eq 6 && "$minor" -ge 1 ]]; then
        echo "v${major_minor}"
        return 0
      else
        # Version < 6.1 uses legacy (port-only) checks
        echo "legacy"
        return 0
      fi
    fi
  fi
  
  # Default to legacy for unknown versions
  echo "legacy"
}

# Get list of services from compose.yml
get_services_list() {
  local compose_file="${DC_ORO_CONFIG_DIR}/compose.yml"
  if [[ ! -f "$compose_file" ]]; then
    msg_error "compose.yml not found"
    return 1
  fi
  
  # Try docker compose config --services first (most reliable)
  if command -v docker >/dev/null 2>&1; then
    local services=$(DC_ORO_NAME="$DC_ORO_NAME" bash -c "${DOCKER_COMPOSE_BIN_CMD} ${left_flags[*]} ${left_options[*]} config --services" 2>/dev/null || true)
    if [[ -n "$services" ]]; then
      echo "$services"
      return 0
    fi
  fi
  
  # Fallback to yq if docker compose fails
  if command -v yq >/dev/null 2>&1; then
    yq '.services | keys | .[]' "$compose_file" 2>/dev/null | grep -v -E "^(appcode|ssh-hostkeys|home-user|home-root|search-data|mail-certs)$" || true
  else
    msg_error "Neither docker compose nor yq available to parse services"
    return 1
  fi
}

# Check if Goss is installed in container
is_goss_installed() {
  local service="$1"
  local container_name="${DC_ORO_NAME}_${service}"
  
  # Check if container is running
  if ! docker ps --format "{{.Names}}" | grep -q "^${container_name}$"; then
    return 1
  fi
  
  # Check if goss command exists
  docker exec "${container_name}" sh -c "command -v goss >/dev/null 2>&1" 2>/dev/null
}

# Install Goss in container
install_goss() {
  local service="$1"
  local container_name="${DC_ORO_NAME}_${service}"
  
  msg_info "Installing Goss in ${service}..."
  
  # Try to detect OS and architecture, install accordingly
  local os_type=$(docker exec "${container_name}" sh -c "cat /etc/os-release 2>/dev/null | grep '^ID=' | cut -d= -f2 | tr -d '\"' || echo 'alpine'" 2>/dev/null || echo "alpine")
  local arch=$(docker exec "${container_name}" sh -c "uname -m 2>/dev/null || echo 'amd64'" 2>/dev/null || echo "amd64")
  
  # Map architecture to Goss binary name
  local goss_arch="amd64"
  case "$arch" in
    x86_64) goss_arch="amd64" ;;
    aarch64|arm64) goss_arch="arm64" ;;
    armv7l|armv6l) goss_arch="arm" ;;
    *) goss_arch="amd64" ;;
  esac
  
  case "$os_type" in
    alpine)
      # Install Goss for Alpine
      docker exec "${container_name}" sh -c "
        if ! command -v goss >/dev/null 2>&1; then
          apk add --no-cache curl ca-certificates >/dev/null 2>&1 || true
          curl -fsSL https://github.com/goss-org/goss/releases/latest/download/goss-linux-${goss_arch} -o /usr/local/bin/goss 2>/dev/null || true
          chmod +x /usr/local/bin/goss 2>/dev/null || true
        fi
      " 2>/dev/null || true
      ;;
    debian|ubuntu)
      # Install Goss for Debian/Ubuntu
      docker exec "${container_name}" sh -c "
        if ! command -v goss >/dev/null 2>&1; then
          apt-get update >/dev/null 2>&1 || true
          apt-get install -y curl ca-certificates >/dev/null 2>&1 || true
          curl -fsSL https://github.com/goss-org/goss/releases/latest/download/goss-linux-${goss_arch} -o /usr/local/bin/goss 2>/dev/null || true
          chmod +x /usr/local/bin/goss 2>/dev/null || true
        fi
      " 2>/dev/null || true
      ;;
    *)
      # Generic Linux installation
      docker exec "${container_name}" sh -c "
        if ! command -v goss >/dev/null 2>&1; then
          curl -fsSL https://github.com/goss-org/goss/releases/latest/download/goss-linux-${goss_arch} -o /usr/local/bin/goss 2>/dev/null || true
          chmod +x /usr/local/bin/goss 2>/dev/null || true
        fi
      " 2>/dev/null || true
      ;;
  esac
  
  # Verify installation
  if is_goss_installed "$service"; then
    msg_ok "Goss installed in ${service}"
    return 0
  else
    msg_warning "Failed to install Goss in ${service}"
    return 1
  fi
}

# Get Goss config file for a service
get_goss_config_file() {
  local service="$1"
  local version="$2"
  local doctor_dir="$3"
  
  # Special handling for database service - select config based on DB type
  if [[ "$service" == "database" ]]; then
    # Normalize database schema (same logic as docker-compose)
    local db_schema="${DC_ORO_DATABASE_SCHEMA:-}"
    if [[ "$db_schema" == "pgsql" ]] || [[ "$db_schema" == "postgresql" ]] || [[ "$db_schema" == "pdo_pgsql" ]] || [[ "$db_schema" == "postgres" ]]; then
      db_schema="postgresql"
    elif [[ "$db_schema" == "mariadb" ]] || [[ "$db_schema" == "pdo_mysql" ]] || [[ "$db_schema" == "mysql" ]]; then
      db_schema="mysql"
    fi
    
    # Try to find database-specific config
    if [[ "$version" == "legacy" ]]; then
      if [[ -n "$doctor_dir" ]] && [[ -n "$db_schema" ]] && [[ -f "${doctor_dir}/legacy/database-${db_schema}.yaml" ]]; then
        echo "${doctor_dir}/legacy/database-${db_schema}.yaml"
        return 0
      fi
    else
      # Try version-specific config first (for 6.1+)
      if [[ -n "$doctor_dir" ]] && [[ -n "$db_schema" ]] && [[ -f "${doctor_dir}/${version}/database-${db_schema}.yaml" ]]; then
        echo "${doctor_dir}/${version}/database-${db_schema}.yaml"
        return 0
      fi
      # Try default config (for 6.1+)
      if [[ -n "$doctor_dir" ]] && [[ -n "$db_schema" ]] && [[ -f "${doctor_dir}/default/database-${db_schema}.yaml" ]]; then
        echo "${doctor_dir}/default/database-${db_schema}.yaml"
        return 0
      fi
    fi
    # No database-specific config found, will generate dynamically
    echo ""
    return 0
  fi
  
  # For other services, use standard lookup
  # For legacy mode, don't look for version-specific configs
  if [[ "$version" == "legacy" ]]; then
    # Try legacy config first
    if [[ -n "$doctor_dir" ]] && [[ -f "${doctor_dir}/legacy/${service}.yaml" ]]; then
      echo "${doctor_dir}/legacy/${service}.yaml"
      return 0
    fi
    # Legacy mode: no config file found, will generate port-only config
    echo ""
    return 0
  fi
  
  # Try version-specific config first (for 6.1+)
  if [[ -n "$doctor_dir" ]] && [[ -f "${doctor_dir}/${version}/${service}.yaml" ]]; then
    echo "${doctor_dir}/${version}/${service}.yaml"
    return 0
  fi
  
  # Try default config (for 6.1+)
  if [[ -n "$doctor_dir" ]] && [[ -f "${doctor_dir}/default/${service}.yaml" ]]; then
    echo "${doctor_dir}/default/${service}.yaml"
    return 0
  fi
  
  # No config file found, will generate
  echo ""
}

# Generate legacy Goss config for a service (port-only checks for old versions)
generate_legacy_goss_config() {
  local service="$1"
  local config_file="${DC_ORO_CONFIG_DIR}/doctor/${service}.yaml"
  
  # Create doctor directory
  mkdir -p "${DC_ORO_CONFIG_DIR}/doctor"
  
  # Create basic config structure with port checks only
  cat > "$config_file" <<EOF
# Goss configuration for ${service} service
# Legacy mode: port-only checks for OroPlatform < 6.1

# Port checks
port:
EOF

  # Service-specific port checks
  case "$service" in
    fpm|cli)
      cat >> "$config_file" <<EOF
  tcp:9000:
    listening: true
    ip:
      - 127.0.0.1
EOF
      ;;
    
    database)
      if [[ "${DC_ORO_DATABASE_SCHEMA:-}" == "pdo_pgsql" ]] || [[ "${DC_ORO_DATABASE_SCHEMA:-}" == "postgres" ]] || [[ "${DC_ORO_DATABASE_SCHEMA:-}" == "postgresql" ]]; then
        cat >> "$config_file" <<EOF
  tcp:5432:
    listening: true
    ip:
      - 127.0.0.1
EOF
      elif [[ "${DC_ORO_DATABASE_SCHEMA:-}" == "pdo_mysql" ]] || [[ "${DC_ORO_DATABASE_SCHEMA:-}" == "mysql" ]]; then
        cat >> "$config_file" <<EOF
  tcp:3306:
    listening: true
    ip:
      - 127.0.0.1
EOF
      fi
      ;;
    
    nginx)
      cat >> "$config_file" <<EOF
  tcp:80:
    listening: true
EOF
      ;;
    
    redis)
      cat >> "$config_file" <<EOF
  tcp:6379:
    listening: true
    ip:
      - 127.0.0.1
EOF
      ;;
    
    search)
      cat >> "$config_file" <<EOF
  tcp:9200:
    listening: true
    ip:
      - 127.0.0.1
EOF
      ;;
    
    mq)
      cat >> "$config_file" <<EOF
  tcp:5672:
    listening: true
    ip:
      - 127.0.0.1
  tcp:15672:
    listening: true
    ip:
      - 127.0.0.1
EOF
      ;;
    
    mail)
      cat >> "$config_file" <<EOF
  tcp:1025:
    listening: true
    ip:
      - 127.0.0.1
  tcp:8025:
    listening: true
    ip:
      - 127.0.0.1
EOF
      ;;
    
    mongodb)
      cat >> "$config_file" <<EOF
  tcp:27017:
    listening: true
    ip:
      - 127.0.0.1
EOF
      ;;
    
    *)
      # Generic: no port checks for unknown services
      cat >> "$config_file" <<EOF
# No port checks configured for ${service}
EOF
      ;;
  esac
  
  echo "$config_file"
}

# Generate PHP script for service checks (Redis, Elasticsearch, etc.)
generate_service_check_php_script() {
  local script_file="${DC_ORO_CONFIG_DIR}/doctor/service-check.php"
  
  mkdir -p "${DC_ORO_CONFIG_DIR}/doctor"
  
  cat > "$script_file" <<'PHPSCRIPT'
<?php
// Service check script - supports multiple service types via command line argument
// Uses ORO_* environment variables

$check_type = $argv[1] ?? '';
$service_host = $argv[2] ?? '';
$service_port = $argv[3] ?? '';

if (empty($check_type) || empty($service_host) || empty($service_port)) {
    echo "Usage: php service-check.php <type> <host> <port>\n";
    exit(1);
}

$service_port = (int)$service_port;

try {
    switch ($check_type) {
        case 'redis':
            // Redis connection check using socket connection (works without Redis extension)
            $socket = @fsockopen($service_host, $service_port, $errno, $errstr, 2);
            if ($socket) {
                // Send PING command
                fwrite($socket, "PING\r\n");
                $response = fgets($socket);
                fclose($socket);
                if (strpos($response, '+PONG') !== false || strpos($response, 'PONG') !== false) {
                    echo "connected\n";
                    exit(0);
                }
            }
            // Fallback: try Redis extension if available
            if (class_exists('Redis')) {
                try {
                    $redis = new Redis();
                    if ($redis->connect($service_host, $service_port, 2)) {
                        $result = $redis->ping();
                        if ($result === '+PONG' || $result === true) {
                            echo "connected\n";
                            exit(0);
                        }
                    }
                } catch (Exception $e) {
                    // Extension failed, continue to failure
                }
            }
            echo "failed\n";
            exit(1);
            break;
            
        case 'elasticsearch':
            // Elasticsearch health check via HTTP
            $url = "http://{$service_host}:{$service_port}/_cluster/health";
            $ch = curl_init($url);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_TIMEOUT, 5);
            curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 5);
            $response = curl_exec($ch);
            $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);
            
            if ($http_code === 200 && $response) {
                $data = json_decode($response, true);
                if (isset($data['status'])) {
                    echo $data['status'] . "\n";
                    exit(0);
                }
            }
            echo "failed\n";
            exit(1);
            break;
            
        case 'rabbitmq':
            // RabbitMQ HTTP API check
            $url = "http://{$service_host}:{$service_port}/api/overview";
            $ch = curl_init($url);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_TIMEOUT, 5);
            curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 5);
            $response = curl_exec($ch);
            $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);
            
            // 200 = OK, 401 = OK but requires auth (service is running)
            if ($http_code === 200 || $http_code === 401) {
                echo "connected\n";
                exit(0);
            }
            echo "failed\n";
            exit(1);
            break;
            
        default:
            echo "Unknown service type: {$check_type}\n";
            exit(1);
    }
} catch (Exception $e) {
    echo "failed\n";
    exit(1);
}
PHPSCRIPT
  
  echo "$script_file"
}

# Generate default Goss config for a service (full checks for 6.1+)
generate_default_goss_config() {
  local service="$1"
  local config_file="${DC_ORO_CONFIG_DIR}/doctor/${service}.yaml"
  
  # Create doctor directory
  mkdir -p "${DC_ORO_CONFIG_DIR}/doctor"
  
  # Start with command checks (no process/port checks for remote services)
  cat > "$config_file" <<EOF
# Goss configuration for ${service} service
# Auto-generated by orodc doctor (default config)
# Checks are performed from CLI container, testing remote service availability

# Command checks
command:
EOF

  # Service-specific checks
  case "$service" in
    fpm|cli)
      # PHP-FPM checks - these run in the container itself, so process checks are OK
      cat >> "$config_file" <<EOF
# Process checks (local to container)
process:
  php-fpm:
    running: true
  php:
    running: true

# Command checks
command:
  php-version:
    exec: "php -v"
    exit-status: 0
  php-extension-pdo:
    exec: "php -m | grep -i pdo"
    exit-status: 0
  php-extension-intl:
    exec: "php -m | grep -i intl"
    exit-status: 0
  php-extension-gd:
    exec: "php -m | grep -i gd"
    exit-status: 0
  php-extension-zip:
    exec: "php -m | grep -i zip"
    exit-status: 0
  php-extension-mbstring:
    exec: "php -m | grep -i mbstring"
    exit-status: 0
  php-extension-xml:
    exec: "php -m | grep -i xml"
    exit-status: 0
  php-extension-curl:
    exec: "php -m | grep -i curl"
    exit-status: 0
  php-extension-bcmath:
    exec: "php -m | grep -i bcmath"
    exit-status: 0
EOF
      # Check for database extension based on DC_ORO_DATABASE_SCHEMA
      if [[ "${DC_ORO_DATABASE_SCHEMA:-}" == "pdo_pgsql" ]] || [[ "${DC_ORO_DATABASE_SCHEMA:-}" == "postgres" ]] || [[ "${DC_ORO_DATABASE_SCHEMA:-}" == "postgresql" ]]; then
        cat >> "$config_file" <<EOF
  php-extension-pgsql:
    exec: "php -m | grep -i pgsql"
    exit-status: 0
EOF
      elif [[ "${DC_ORO_DATABASE_SCHEMA:-}" == "pdo_mysql" ]] || [[ "${DC_ORO_DATABASE_SCHEMA:-}" == "mysql" ]]; then
        cat >> "$config_file" <<EOF
  php-extension-mysqli:
    exec: "php -m | grep -i mysqli"
    exit-status: 0
EOF
      fi
      
      # Check for Redis extension if Redis is configured
      if [[ -n "${DC_ORO_REDIS_URI:-}" ]]; then
        cat >> "$config_file" <<EOF
  php-extension-redis:
    exec: "php -m | grep -i redis"
    exit-status: 0
EOF
      fi
      
      # Check for Composer
      cat >> "$config_file" <<EOF
  composer-version:
    exec: "composer -V 2>/dev/null || echo 'not found'"
    exit-status: 0
EOF
      ;;
    
    database)
      # Database checks are added via add_database_connection_checks function
      # Only add version check command if psql/mysql available (for info, not required)
      if [[ "${DC_ORO_DATABASE_SCHEMA:-}" == "pdo_pgsql" ]] || [[ "${DC_ORO_DATABASE_SCHEMA:-}" == "postgres" ]] || [[ "${DC_ORO_DATABASE_SCHEMA:-}" == "postgresql" ]]; then
        cat >> "$config_file" <<EOF
  postgresql-version:
    exec: "psql --version 2>/dev/null || echo 'not found'"
    exit-status: 0
EOF
      elif [[ "${DC_ORO_DATABASE_SCHEMA:-}" == "pdo_mysql" ]] || [[ "${DC_ORO_DATABASE_SCHEMA:-}" == "mysql" ]]; then
        cat >> "$config_file" <<EOF
  mysql-version:
    exec: "mysql --version 2>/dev/null || echo 'not found'"
    exit-status: 0
EOF
      fi
      ;;
    
    nginx)
      # Nginx port check from CLI container (network check)
      cat >> "$config_file" <<EOF
  nginx-port-check:
    exec: "nc -z -w1 nginx 80 2>&1 && echo 'Port 80 is accessible' || echo 'Port 80 is not accessible'"
    exit-status: 0
    stdout:
      - "Port 80 is accessible"
EOF
      ;;
    
    redis)
      # Redis checks from CLI container using PHP
      local redis_uri="${DC_ORO_REDIS_URI:-}"
      local redis_host="redis"
      local redis_port="6379"
      if [[ -n "$redis_uri" ]]; then
        local redis_host_port=$(parse_uri "$redis_uri" "6379")
        redis_host=$(echo "$redis_host_port" | cut -d: -f1)
        redis_port=$(echo "$redis_host_port" | cut -d: -f2)
      fi
      cat >> "$config_file" <<EOF
  redis-port-check:
    exec: "nc -z -w1 ${redis_host} ${redis_port} 2>&1 && echo 'Port ${redis_port} is accessible' || echo 'Port ${redis_port} is not accessible'"
    exit-status: 0
    stdout:
      - "Port ${redis_port} is accessible"
  redis-connection-check:
    exec: "php /tmp/service-check.php redis ${redis_host} ${redis_port}"
    exit-status: 0
    stdout:
      - "connected"
EOF
      ;;
    
    search)
      # Elasticsearch checks from CLI container using PHP
      local search_uri="${DC_ORO_SEARCH_URI:-elastic-search://search:9200}"
      local search_host_port=$(parse_uri "$search_uri" "9200")
      local search_host=$(echo "$search_host_port" | cut -d: -f1)
      local search_port=$(echo "$search_host_port" | cut -d: -f2)
      cat >> "$config_file" <<EOF
  elasticsearch-port-check:
    exec: "nc -z -w1 ${search_host} ${search_port} 2>&1 && echo 'Port ${search_port} is accessible' || echo 'Port ${search_port} is not accessible'"
    exit-status: 0
    stdout:
      - "Port ${search_port} is accessible"
  elasticsearch-health-check:
    exec: "php /tmp/service-check.php elasticsearch ${search_host} ${search_port}"
    exit-status: 0
    timeout: 5000

# HTTP checks (from CLI container to remote service)
http:
  http://${search_host}:${search_port}:
    status: 200
    timeout: 2000
EOF
      ;;
    
    mq)
      # RabbitMQ checks from CLI container using PHP
      local mq_uri="${DC_ORO_MQ_URI:-}"
      local mq_host="mq"
      local mq_port="5672"
      local mq_http_port="15672"
      if [[ -n "$mq_uri" ]] && [[ "$mq_uri" != "dbal:" ]]; then
        local mq_host_port=$(parse_uri "$mq_uri" "5672")
        mq_host=$(echo "$mq_host_port" | cut -d: -f1)
        mq_port=$(echo "$mq_host_port" | cut -d: -f2)
      fi
      cat >> "$config_file" <<EOF
  rabbitmq-port-check:
    exec: "nc -z -w1 ${mq_host} ${mq_port} 2>&1 && echo 'Port ${mq_port} is accessible' || echo 'Port ${mq_port} is not accessible'"
    exit-status: 0
    stdout:
      - "Port ${mq_port} is accessible"
  rabbitmq-http-check:
    exec: "nc -z -w1 ${mq_host} ${mq_http_port} 2>&1 && echo 'Port ${mq_http_port} is accessible' || echo 'Port ${mq_http_port} is not accessible'"
    exit-status: 0
    stdout:
      - "Port ${mq_http_port} is accessible"
  rabbitmq-api-check:
    exec: "php /tmp/service-check.php rabbitmq ${mq_host} ${mq_http_port}"
    exit-status: 0
    stdout:
      - "connected"
    timeout: 5000

# HTTP checks (from CLI container to remote service)
http:
  http://${mq_host}:${mq_http_port}:
    status: [200, 401]
    timeout: 2000
EOF
      ;;
    
    mail)
      # Mail checks from CLI container
      local mail_host="${ORO_MAILER_HOST:-mail}"
      local mail_port="${ORO_MAILER_PORT:-1025}"
      cat >> "$config_file" <<EOF
  mail-smtp-port-check:
    exec: "nc -z -w1 ${mail_host} ${mail_port} 2>&1 && echo 'Port ${mail_port} is accessible' || echo 'Port ${mail_port} is not accessible'"
    exit-status: 0
    stdout:
      - "Port ${mail_port} is accessible"
  mail-http-port-check:
    exec: "nc -z -w1 ${mail_host} 8025 2>&1 && echo 'Port 8025 is accessible' || echo 'Port 8025 is not accessible'"
    exit-status: 0
    stdout:
      - "Port 8025 is accessible"

# HTTP checks (from CLI container to remote service)
http:
  http://${mail_host}:8025:
    status: [200, 404]
    timeout: 2000
EOF
      ;;
    
    mongodb)
      # MongoDB port check from CLI container
      cat >> "$config_file" <<EOF
  mongodb-port-check:
    exec: "nc -z -w1 mongodb 27017 2>&1 && echo 'Port 27017 is accessible' || echo 'Port 27017 is not accessible'"
    exit-status: 0
    stdout:
      - "Port 27017 is accessible"
EOF
      ;;
    
    *)
      # Generic checks for unknown services
      cat >> "$config_file" <<EOF
# Generic checks for ${service}
# Add specific checks as needed
EOF
      ;;
  esac
  
  echo "$config_file"
}

# Add database connection checks to database config
add_database_connection_checks() {
  local config_file="$1"
  local version="$2"
  
  # Get database connection parameters
  local db_host="${DC_ORO_DATABASE_HOST:-database}"
  local db_port="${DC_ORO_DATABASE_PORT:-5432}"
  local default_db_schema="postgres"
  if [[ "$version" == "legacy" ]]; then
    default_db_schema="mysql"
    db_port="${DC_ORO_DATABASE_PORT:-3306}"
  fi
  local db_schema="${DC_ORO_DATABASE_SCHEMA:-${default_db_schema}}"
  local db_user="${DC_ORO_DATABASE_USER:-oro_db_user}"
  local db_password="${DC_ORO_DATABASE_PASSWORD:-oro_db_pass}"
  local db_name="${DC_ORO_DATABASE_DBNAME:-oro_db}"
  
  # Normalize database schema
  if [[ "$db_schema" == "pdo_pgsql" ]] || [[ "$db_schema" == "postgresql" ]] || [[ "$db_schema" == "pgsql" ]] || [[ "$db_schema" == "postgres" ]]; then
    db_schema="postgres"
    db_port="${DC_ORO_DATABASE_PORT:-5432}"
  elif [[ "$db_schema" == "pdo_mysql" ]] || [[ "$db_schema" == "mysql" ]] || [[ "$db_schema" == "mariadb" ]]; then
    db_schema="mysql"
    db_port="${DC_ORO_DATABASE_PORT:-3306}"
  fi
  
  # Generate PHP script for database check
  local db_check_script=$(generate_database_check_php_script "$version")
  
  # Add command checks section if not exists
  if ! grep -q "^command:" "$config_file"; then
    echo "" >> "$config_file"
    echo "# Command checks" >> "$config_file"
    echo "command:" >> "$config_file"
  fi
  
  # Add database connection checks - all through PHP
  # Note: Don't use pipes (|) or redirect stderr (2>&1) with goss - it causes issues with stdout matching
  # PHP scripts output to stdout only, errors are handled via exit codes
  cat >> "$config_file" <<EOF
  database-port-check:
    exec: "nc -z -w1 ${db_host} ${db_port} 2>&1 && echo 'Port ${db_port} is accessible' || echo 'Port ${db_port} is not accessible'"
    exit-status: 0
    stdout:
      - "Port ${db_port} is accessible"
  database-version-check:
    exec: "php /tmp/db-check.php version"
    exit-status: 0
    timeout: 5000
  database-connection-check:
    exec: "php /tmp/db-check.php connection"
    exit-status: 0
    stdout:
      - "connected"
  database-list-check:
    exec: "php /tmp/db-check.php list"
    exit-status: 0
    timeout: 5000
  database-exists-check:
    exec: "php /tmp/db-check.php exists"
    exit-status: 0
    stdout:
      - "Database ${db_name} exists"
    timeout: 5000
EOF
}

# Prepare Goss config for a service
prepare_goss_config() {
  local service="$1"
  local version="$2"
  local doctor_dir="$3"
  
  # Create doctor directory in config
  mkdir -p "${DC_ORO_CONFIG_DIR}/doctor"
  
  local target_config="${DC_ORO_CONFIG_DIR}/doctor/${service}.yaml"
  
  # Try to use static config first (works for all services including database)
  local source_config=$(get_goss_config_file "$service" "$version" "$doctor_dir")
  
  # Copy config from source if exists
  if [[ -n "$source_config" ]] && [[ -f "$source_config" ]]; then
    # For remote services (database, redis, search, mq, mail, nginx), remove process and port checks
    # These checks run from CLI container and should test remote services, not local processes
    if [[ "$service" == "database" ]] || [[ "$service" == "redis" ]] || [[ "$service" == "search" ]] || [[ "$service" == "mq" ]] || [[ "$service" == "mail" ]] || [[ "$service" == "nginx" ]]; then
      # Use awk to remove process and port sections while keeping everything else
      awk '
        /^process:/ { in_process=1; next }
        /^port:/ { in_port=1; next }
        /^[a-z]/ && !/^process/ && !/^port/ { in_process=0; in_port=0 }
        !in_process && !in_port { print }
      ' "$source_config" > "$target_config"
      # Ensure we have at least command section
      if ! grep -q "^command:" "$target_config"; then
        echo "" >> "$target_config"
        echo "# Command checks" >> "$target_config"
        echo "command:" >> "$target_config"
      fi
      debug_log "Using config from: $source_config (removed process/port checks for remote ${service})"
    else
      cp "$source_config" "$target_config"
      debug_log "Using config from: $source_config"
    fi
  else
    # Generate config dynamically based on version
    if [[ "$version" == "legacy" ]]; then
      # Legacy mode: port-only checks
      generate_legacy_goss_config "$service" >/dev/null 2>&1 || true
      debug_log "Generated legacy (port-only) config for: $service"
    else
      # Default mode: full checks for 6.1+
      generate_default_goss_config "$service" >/dev/null 2>&1 || true
      debug_log "Generated default (full) config for: $service"
    fi
  fi
  
  # Verify config file was created
  if [[ ! -f "$target_config" ]]; then
    debug_log "Failed to create config file for ${service}"
    echo ""
    return 1
  fi
  
  # Add database connection checks if this is database service (don't fail on error)
  if [[ "$service" == "database" ]]; then
    add_database_connection_checks "$target_config" "$version" 2>/dev/null || true
  fi
  
  # Add service checks for redis, search, mq if needed (don't fail on error)
  if [[ "$service" == "redis" ]] || [[ "$service" == "search" ]] || [[ "$service" == "mq" ]]; then
    # Service checks are already in config, but we need to ensure service-check.php is available
    debug_log "Service ${service} requires service-check.php script" 2>/dev/null || true
  fi
  
  echo "$target_config"
}

# Parse URI and extract host:port
parse_uri() {
  local uri="$1"
  local default_port="$2"
  
  if [[ -z "$uri" ]]; then
    echo ""
    return 0
  fi
  
  # Remove protocol prefix (redis://, elastic-search://, etc.)
  local host_port=$(echo "$uri" | sed -E 's|^[^:]+://||' | sed -E 's|/.*$||')
  
  # Extract host and port
  if [[ "$host_port" == *:* ]]; then
    echo "$host_port"
  else
    echo "${host_port}:${default_port}"
  fi
}

# Generate unified Goss config for all services from CLI container
generate_unified_goss_config() {
  local version="$1"
  local config_file="${DC_ORO_CONFIG_DIR}/doctor/all-services.yaml"
  
  mkdir -p "${DC_ORO_CONFIG_DIR}/doctor"
  
  # Use environment variables from host (they will be passed to container via docker compose run)
  local db_host="${DC_ORO_DATABASE_HOST:-database}"
  local db_port="${DC_ORO_DATABASE_PORT:-5432}"
  # For legacy versions (< 6.1), default to MySQL if not specified (old Oro and Marello use MySQL)
  # For newer versions (6.1+), default to PostgreSQL
  local default_db_schema="postgres"
  if [[ "$version" == "legacy" ]]; then
    default_db_schema="mysql"
    db_port="${DC_ORO_DATABASE_PORT:-3306}"
  fi
  local db_schema="${DC_ORO_DATABASE_SCHEMA:-${default_db_schema}}"
  local db_user="${DC_ORO_DATABASE_USER:-oro_db_user}"
  local db_password="${DC_ORO_DATABASE_PASSWORD:-oro_db_pass}"
  local db_name="${DC_ORO_DATABASE_DBNAME:-oro_db}"
  
  # Normalize database schema
  if [[ "$db_schema" == "pdo_pgsql" ]] || [[ "$db_schema" == "postgresql" ]] || [[ "$db_schema" == "pgsql" ]] || [[ "$db_schema" == "postgres" ]]; then
    db_schema="postgres"
    db_port="${DC_ORO_DATABASE_PORT:-5432}"
  elif [[ "$db_schema" == "pdo_mysql" ]] || [[ "$db_schema" == "mysql" ]] || [[ "$db_schema" == "mariadb" ]]; then
    db_schema="mysql"
    db_port="${DC_ORO_DATABASE_PORT:-3306}"
  fi
  
  local redis_uri="${DC_ORO_REDIS_URI:-}"
  local search_uri="${DC_ORO_SEARCH_URI:-elastic-search://search:9200}"
  local mq_uri="${DC_ORO_MQ_URI:-}"
  local mail_host="${ORO_MAILER_HOST:-mail}"
  local mail_port="${ORO_MAILER_PORT:-1025}"
  
  cat > "$config_file" <<EOF
# Goss configuration for all services
# Generated for OroPlatform version: ${version}
# Checks are performed from CLI container using ORODC environment variables

# Command checks for service availability
command:
EOF

  # Generate PHP script for database checks
  local db_check_script=$(generate_database_check_php_script "$version")
  
  # Database checks - separated into individual tests for better visibility
  if [[ "$db_schema" == "postgres" ]]; then
    cat >> "$config_file" <<EOF
# Database port availability check
database-port-check:
  exec: "nc -z -w1 ${db_host} ${db_port} 2>&1 && echo 'Port ${db_port} is accessible' || echo 'Port ${db_port} is not accessible'"
  exit-status: 0
  stdout:
    - "Port ${db_port} is accessible"

# Database version check
database-version-check:
  exec: "PGPASSWORD='${db_password}' psql -h ${db_host} -p ${db_port} -U ${db_user} -d postgres -tAc 'SELECT version();' 2>&1 | head -1 || echo 'Failed to get version'"
  exit-status: 0
  timeout: 5000

# Database connection test
database-connection-check:
  exec: "php /tmp/db-check.php 2>&1"
  exit-status: 0
  stdout:
    - "connected"

# Database list check
database-list-check:
  exec: "PGPASSWORD='${db_password}' psql -h ${db_host} -p ${db_port} -U ${db_user} -d postgres -tAc \"SELECT datname FROM pg_database WHERE datistemplate = false;\" 2>&1 | grep -v '^$' || echo 'Failed to list databases'"
  exit-status: 0
  timeout: 5000

# Target database exists check
database-exists-check:
  exec: "PGPASSWORD='${db_password}' psql -h ${db_host} -p ${db_port} -U ${db_user} -d postgres -tAc \"SELECT 1 FROM pg_database WHERE datname='${db_name}';\" 2>&1 | grep -q '1' && echo 'Database ${db_name} exists' || echo 'Database ${db_name} does not exist'"
  exit-status: 0
  stdout:
    - "Database ${db_name} exists"
  timeout: 5000
EOF
  else
    # MySQL/MariaDB checks - use environment variables for password security
    cat >> "$config_file" <<EOF
# Database port availability check
database-port-check:
  exec: "nc -z -w1 ${db_host} ${db_port} 2>&1 && echo 'Port ${db_port} is accessible' || echo 'Port ${db_port} is not accessible'"
  exit-status: 0
  stdout:
    - "Port ${db_port} is accessible"

# Database version check
database-version-check:
  exec: "MYSQL_PWD='${db_password}' mysql -h ${db_host} -P ${db_port} -u ${db_user} -e 'SELECT VERSION();' 2>&1 | tail -1 || echo 'Failed to get version'"
  exit-status: 0
  timeout: 5000

# Database connection test
database-connection-check:
  exec: "php /tmp/db-check.php 2>&1"
  exit-status: 0
  stdout:
    - "connected"

# Database list check
database-list-check:
  exec: "MYSQL_PWD='${db_password}' mysql -h ${db_host} -P ${db_port} -u ${db_user} -e 'SHOW DATABASES;' 2>&1 | grep -v '^Database' | grep -v '^$' || echo 'Failed to list databases'"
  exit-status: 0
  timeout: 5000

# Target database exists check
database-exists-check:
  exec: "MYSQL_PWD='${db_password}' mysql -h ${db_host} -P ${db_port} -u ${db_user} -e 'USE ${db_name};' 2>&1 && echo 'Database ${db_name} exists' || echo 'Database ${db_name} does not exist'"
  exit-status: 0
  stdout:
    - "Database ${db_name} exists"
  timeout: 5000
EOF
  fi

  # Redis port check
  if [[ -n "$redis_uri" ]]; then
    local redis_host_port=$(parse_uri "$redis_uri" "6379")
    local redis_host=$(echo "$redis_host_port" | cut -d: -f1)
    local redis_port=$(echo "$redis_host_port" | cut -d: -f2)
    cat >> "$config_file" <<EOF
redis-port-check:
  exec: "nc -z -w1 ${redis_host} ${redis_port} 2>&1 && echo 'succeeded' || echo 'failed'"
  exit-status: 0
  stdout:
    - "succeeded"
EOF
  fi

  # Redis connection check using OroPlatform variables
  # Parse ORO_REDIS_URL or ORO_SESSION_DSN and test connection
  if [[ -n "$redis_uri" ]]; then
    cat >> "$config_file" <<'EOF'
redis-connection-check:
  exec: 'sh -c "redis_url=\"${ORO_REDIS_URL:-}${ORO_SESSION_DSN:-}\"; if [ -z \"$redis_url\" ]; then echo skipped; exit 0; fi; redis_host=$(echo $redis_url | sed \"s|redis://||\" | sed \"s|.*@||\" | cut -d: -f1 | cut -d/ -f1); redis_port=$(echo $redis_url | sed \"s|redis://||\" | sed \"s|.*@||\" | cut -d: -f2 | cut -d/ -f1 | grep -oE \"[0-9]+\" || echo \"6379\"); redis_password=$(echo $redis_url | sed -n \"s|redis://[^:]*:\\([^@]*\\)@.*|\\1|p\" || echo \"\"); if [ -n \"$redis_password\" ] && [ \"$redis_password\" != \"$redis_url\" ]; then redis-cli -h ${redis_host:-redis} -p ${redis_port:-6379} -a \"$redis_password\" ping 2>&1 | grep -q PONG && echo connected || echo failed; else redis-cli -h ${redis_host:-redis} -p ${redis_port:-6379} ping 2>&1 | grep -q PONG && echo connected || echo failed; fi"'
  exit-status: 0
  stdout:
    - "connected"
    - "skipped"
EOF
  fi

  # Search (Elasticsearch) port check
  if [[ -n "$search_uri" ]]; then
    local search_host_port=$(parse_uri "$search_uri" "9200")
    local search_host=$(echo "$search_host_port" | cut -d: -f1)
    local search_port=$(echo "$search_host_port" | cut -d: -f2)
    cat >> "$config_file" <<EOF
search-port-check:
  exec: "nc -z -w1 ${search_host} ${search_port} 2>&1 && echo 'succeeded' || echo 'failed'"
  exit-status: 0
  stdout:
    - "succeeded"
EOF
  fi

  # Elasticsearch connection check using OroPlatform variables
  # Check that cluster status is green (all shards available)
  if [[ -n "$search_uri" ]]; then
    local search_host_port=$(parse_uri "$search_uri" "9200")
    local search_host=$(echo "$search_host_port" | cut -d: -f1)
    local search_port=$(echo "$search_host_port" | cut -d: -f2)
    cat >> "$config_file" <<EOF
search-connection-check:
  exec: 'sh -c "health=\$(curl -s -f \"http://${search_host}:${search_port}/_cluster/health\" 2>&1); if echo \"\$health\" | grep -q \"\\\"status\\\":\\\"green\\\"\"; then echo green; elif echo \"\$health\" | grep -q \"\\\"status\\\"\"; then echo not-green; else echo failed; fi"'
  exit-status: 0
  stdout:
    - "green"
EOF
  fi

  # Message Queue (RabbitMQ) check
  if [[ -n "$mq_uri" ]]; then
    local mq_host_port=$(parse_uri "$mq_uri" "5672")
    local mq_host=$(echo "$mq_host_port" | cut -d: -f1)
    local mq_port=$(echo "$mq_host_port" | cut -d: -f2)
    cat >> "$config_file" <<EOF
mq-port-check:
  exec: "nc -z -w1 ${mq_host} ${mq_port} 2>&1 && echo 'succeeded' || echo 'failed'"
  exit-status: 0
  stdout:
    - "succeeded"
EOF
  fi

  # Mail check
  cat >> "$config_file" <<EOF
mail-port-check:
  exec: "nc -z -w1 ${mail_host} ${mail_port} 2>&1 && echo 'succeeded' || echo 'failed'"
  exit-status: 0
  stdout:
    - "succeeded"
EOF

  # Nginx check
  cat >> "$config_file" <<EOF
nginx-port-check:
  exec: "nc -z -w1 nginx 80 2>&1 && echo 'succeeded' || echo 'failed'"
  exit-status: 0
  stdout:
    - "succeeded"
EOF

  # Mailpit Web UI check (accepts both 200 and 404 as valid responses)
  # Use command check since Goss http section doesn't support multiple status codes
  cat >> "$config_file" <<EOF
mail-http-status-check:
  exec: "curl -s -o /dev/null -w '%{http_code}' http://${mail_host}:8025 | grep -E '^(200|404)$' && echo 'ok' || echo 'failed'"
  exit-status: 0
  stdout:
    - "ok"
EOF

  # RabbitMQ Management UI check (accepts both 200 and 401 as valid responses)
  if [[ -n "$mq_uri" ]]; then
    local mq_host_port=$(parse_uri "$mq_uri" "5672")
    local mq_host=$(echo "$mq_host_port" | cut -d: -f1)
    cat >> "$config_file" <<EOF
mq-http-status-check:
  exec: "curl -s -o /dev/null -w '%{http_code}' http://${mq_host}:15672 | grep -E '^(200|401)$' && echo 'ok' || echo 'failed'"
  exit-status: 0
  stdout:
    - "ok"
EOF
  fi

  # HTTP checks for services that support it
  cat >> "$config_file" <<EOF

# HTTP checks
http:
EOF

  # Elasticsearch HTTP check
  if [[ -n "$search_uri" ]]; then
    local search_host_port=$(parse_uri "$search_uri" "9200")
    local search_host=$(echo "$search_host_port" | cut -d: -f1)
    local search_port=$(echo "$search_host_port" | cut -d: -f2)
    cat >> "$config_file" <<EOF
  http://${search_host}:${search_port}:
    status: 200
    timeout: 2000
EOF
  fi

  echo "$config_file"
}

# Generate PHP script for database checks
generate_database_check_php_script() {
  local version="$1"
  local script_file="${DC_ORO_CONFIG_DIR}/doctor/database-check.php"
  
  mkdir -p "${DC_ORO_CONFIG_DIR}/doctor"
  
  cat > "$script_file" <<'PHPSCRIPT'
<?php
// Database check script - supports multiple check types via command line argument
// Uses ORO_DB_* environment variables

$check_type = $argv[1] ?? 'connection';

$db_host = getenv('ORO_DB_HOST') ?: getenv('DC_ORO_DATABASE_HOST') ?: 'database';
$db_port = getenv('ORO_DB_PORT') ?: getenv('DC_ORO_DATABASE_PORT') ?: '5432';
$db_user = getenv('ORO_DB_USER') ?: getenv('DC_ORO_DATABASE_USER') ?: 'app';
$db_password = getenv('ORO_DB_PASSWORD') ?: getenv('DC_ORO_DATABASE_PASSWORD') ?: 'app';
$db_name = getenv('ORO_DB_NAME') ?: getenv('DC_ORO_DATABASE_DBNAME') ?: 'app';
$db_schema = getenv('ORO_DB_DRIVER') ?: getenv('DC_ORO_DATABASE_SCHEMA') ?: 'pdo_pgsql';

// Normalize database schema
if (in_array($db_schema, ['pgsql', 'postgresql', 'pdo_pgsql', 'postgres'])) {
    $db_schema = 'pdo_pgsql';
    $db_port = getenv('ORO_DB_PORT') ?: getenv('DC_ORO_DATABASE_PORT') ?: '5432';
    $system_db = 'postgres';
} elseif (in_array($db_schema, ['mariadb', 'pdo_mysql', 'mysql'])) {
    $db_schema = 'pdo_mysql';
    $db_port = getenv('ORO_DB_PORT') ?: getenv('DC_ORO_DATABASE_PORT') ?: '3306';
    $system_db = 'mysql';
} else {
    $db_schema = 'pdo_pgsql';
    $system_db = 'postgres';
}

try {
    // Connect to system database for version/list/exists checks
    if ($check_type !== 'connection') {
        if ($db_schema === 'pdo_pgsql') {
            $dsn = "pgsql:host={$db_host};port={$db_port};dbname={$system_db}";
        } else {
            $dsn = "mysql:host={$db_host};port={$db_port};dbname={$system_db}";
        }
    } else {
        // Connect to target database for connection check
        if ($db_schema === 'pdo_pgsql') {
            $dsn = "pgsql:host={$db_host};port={$db_port};dbname={$db_name}";
        } else {
            $dsn = "mysql:host={$db_host};port={$db_port};dbname={$db_name}";
        }
    }
    
    $pdo = new PDO($dsn, $db_user, $db_password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_TIMEOUT => 5
    ]);
    
    switch ($check_type) {
        case 'connection':
            // Test connection with a simple query
            $stmt = $pdo->query('SELECT 1');
            $result = $stmt->fetch();
            if ($result) {
                echo "connected\n";
                exit(0);
            } else {
                echo "failed\n";
                exit(1);
            }
            break;
            
        case 'version':
            // Get database version
            if ($db_schema === 'pdo_pgsql') {
                $stmt = $pdo->query('SELECT version()');
            } else {
                $stmt = $pdo->query('SELECT VERSION()');
            }
            $result = $stmt->fetchColumn();
            echo trim($result) . "\n";
            exit(0);
            break;
            
        case 'list':
            // List databases
            if ($db_schema === 'pdo_pgsql') {
                $stmt = $pdo->query("SELECT datname FROM pg_database WHERE datistemplate = false ORDER BY datname");
            } else {
                $stmt = $pdo->query('SHOW DATABASES');
            }
            $databases = [];
            while ($row = $stmt->fetch(PDO::FETCH_NUM)) {
                $db = trim($row[0]);
                if (!empty($db) && $db !== 'Database') {
                    $databases[] = $db;
                }
            }
            echo implode("\n", array_slice($databases, 0, 10)) . "\n";
            exit(0);
            break;
            
        case 'exists':
            // Check if target database exists
            if ($db_schema === 'pdo_pgsql') {
                $stmt = $pdo->prepare("SELECT 1 FROM pg_database WHERE datname = ?");
                $stmt->execute([$db_name]);
            } else {
                $stmt = $pdo->prepare("SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = ?");
                $stmt->execute([$db_name]);
            }
            $result = $stmt->fetch();
            if ($result) {
                echo "Database {$db_name} exists\n";
                exit(0);
            } else {
                echo "Database {$db_name} does not exist\n";
                exit(1);
            }
            break;
            
        default:
            echo "Unknown check type: {$check_type}\n";
            exit(1);
    }
} catch (PDOException $e) {
    echo "failed\n";
    exit(1);
}
PHPSCRIPT
  
  echo "$script_file"
}

# Run database connection check using PHP script in CLI container
run_database_check_from_cli() {
  local version="$1"
  
  # Generate PHP check script
  local script_file=$(generate_database_check_php_script "$version")
  
  if [[ ! -f "$script_file" ]]; then
    msg_error "Failed to generate database check script"
    return 1
  fi
  
  # Run PHP script from CLI container using docker compose run
  echo ""
  msg_header "Running database connection check from CLI container..."
  echo ""
  
  # Use docker compose run to start CLI container and run PHP script
  # -T disables TTY allocation
  # --rm removes container after execution
  # -q suppresses Docker Compose output
  # -v mounts script file directly into container
  local output
  output=$(${DOCKER_COMPOSE_BIN_CMD} ${left_flags[*]} ${left_options[*]} run --rm -T -q -v "${script_file}:/tmp/db-check.php:ro" cli php /tmp/db-check.php 2>&1)
  local exit_code=$?
  
  if [[ "$exit_code" -eq 0 ]] && echo "$output" | grep -q "connected"; then
    echo "$output"
    return 0
  else
    echo "$output"
    msg_error "Database connection check failed"
    return 1
  fi
}

# Get container information for a service
get_container_info() {
  local service="$1"
  local container_name="${DC_ORO_NAME}_${service}"
  
  # Try to get container info from docker compose ps (JSON format)
  local container_info
  container_info=$(${DOCKER_COMPOSE_BIN_CMD} ${left_flags[*]} ${left_options[*]} ps --format json "$service" 2>/dev/null | head -1 || echo "")
  
  if [[ -n "$container_info" ]] && command -v jq >/dev/null 2>&1; then
    # Parse JSON output
    local name=$(echo "$container_info" | jq -r '.Name // ""' 2>/dev/null || echo "")
    local image=$(echo "$container_info" | jq -r '.Image // ""' 2>/dev/null || echo "")
    local state=$(echo "$container_info" | jq -r '.State // ""' 2>/dev/null || echo "")
    
    if [[ -n "$name" ]] && [[ "$name" != "null" ]]; then
      # Normalize state
      if [[ -z "$state" ]] || [[ "$state" == "null" ]]; then
        state="unknown"
      fi
      echo "${name}|${image}|${state}"
      return 0
    fi
  fi
  
  # Fallback to docker compose ps (table format)
  local compose_info
  compose_info=$(${DOCKER_COMPOSE_BIN_CMD} ${left_flags[*]} ${left_options[*]} ps "$service" 2>/dev/null | tail -n +3 | head -1 || echo "")
  
  if [[ -n "$compose_info" ]]; then
    # Parse table format: NAME IMAGE COMMAND SERVICE CREATED STATUS PORTS
    local name=$(echo "$compose_info" | awk '{print $1}')
    local image=$(echo "$compose_info" | awk '{print $2}')
    local state=$(echo "$compose_info" | awk '{for(i=6;i<=NF;i++) printf "%s ", $i; print ""}' | xargs)
    
    if [[ -n "$name" ]] && [[ "$name" != "NAME" ]]; then
      echo "${name}|${image}|${state}"
      return 0
    fi
  fi
  
  # Fallback to docker ps
  local docker_info
  docker_info=$(docker ps -a --filter "name=${container_name}" --format "{{.Names}}|{{.Image}}|{{.Status}}" 2>/dev/null | head -1 || echo "")
  
  if [[ -n "$docker_info" ]]; then
    echo "$docker_info"
    return 0
  fi
  
  # No container found - try to get image from compose.yml
  local compose_file="${DC_ORO_CONFIG_DIR}/compose.yml"
  local image_from_compose=""
  if [[ -f "$compose_file" ]] && command -v yq >/dev/null 2>&1; then
    image_from_compose=$(yq ".services.${service}.image // .services.${service}.\"build\".args.BASE_IMAGE // \"unknown\"" "$compose_file" 2>/dev/null || echo "unknown")
  fi
  
  echo "${container_name}|${image_from_compose}|not found"
  return 1
}

# Get container healthcheck status
get_container_health_status() {
  local container_name="$1"
  
  # Try to get healthcheck status from docker inspect
  local health_status
  health_status=$(docker inspect "$container_name" --format '{{.State.Health.Status}}' 2>/dev/null || echo "")
  
  # Return health status: "healthy", "unhealthy", "starting", or empty string (no healthcheck)
  echo "${health_status}"
}

# Run Goss checks for a single service from CLI container
# Returns: 0 on success, 1 on failure
# Outputs: writes test output to log file, returns log file path via global variable
# NOTE: This function assumes set +e is already set by caller
run_goss_check_for_service() {
  local service="$1"
  local version="$2"
  local doctor_dir="$3"
  local silent="${4:-false}"
  local log_file="${5:-}"
  
  # Prepare config for this service (don't fail if config preparation fails)
  local config_file=""
  config_file=$(prepare_goss_config "$service" "$version" "$doctor_dir" 2>/dev/null || echo "")
  
  if [[ ! -f "$config_file" ]] || [[ -z "$config_file" ]]; then
    debug_log "No config file for service: $service (skipping)"
    return 0
  fi
  
  # Generate PHP scripts for checks (don't fail if generation fails)
  local db_check_script=""
  local service_check_script=""
  db_check_script=$(generate_database_check_php_script "$version" 2>/dev/null || echo "")
  service_check_script=$(generate_service_check_php_script 2>/dev/null || echo "")
  
  # Show which service we're testing (unless silent)
  if [[ "$silent" != "true" ]]; then
    echo ""
    msg_header "Testing service: ${service}"
    echo ""
  fi
  
  # Mount config file
  local mount_args=("-v" "${config_file}:/tmp/goss.yaml:ro")
  
  # Mount PHP scripts if needed
  if [[ "$service" == "database" ]] && [[ -n "$db_check_script" ]] && [[ -f "$db_check_script" ]]; then
    mount_args+=("-v" "${db_check_script}:/tmp/db-check.php:ro")
  fi
  
  # Mount service check script for redis, search, mq
  if [[ "$service" == "redis" ]] || [[ "$service" == "search" ]] || [[ "$service" == "mq" ]]; then
    if [[ -n "$service_check_script" ]] && [[ -f "$service_check_script" ]]; then
      mount_args+=("-v" "${service_check_script}:/tmp/service-check.php:ro")
    fi
  fi
  
  # Create log file if not provided
  if [[ -z "$log_file" ]]; then
    log_file=$(mktemp "/tmp/orodc-doctor-${service}-XXXXXX.log" 2>/dev/null || echo "/tmp/orodc-doctor-${service}.log")
  fi
  
  # Run Goss validate from CLI container
  # -T disables TTY allocation
  # --rm removes container after execution
  # -q suppresses Docker Compose output
  # Use format=documentation for detailed output
  local exit_code=0
  
  # Always redirect output to log file
  # CRITICAL: Don't fail on error - just capture exit code
  # Use explicit command execution with error handling (don't use if/else to prevent interruption)
  # CRITICAL: Redirect stdin from /dev/null to prevent consuming lines from parent while-read loop
  ${DOCKER_COMPOSE_BIN_CMD} ${left_flags[*]} ${left_options[*]} run --rm -T -q "${mount_args[@]}" cli goss -g /tmp/goss.yaml validate --format documentation < /dev/null > "$log_file" 2>&1 || true
  exit_code=$?
  
  # If exit code is 0 but there are failures in log, set exit code to 1
  if [[ $exit_code -eq 0 ]] && grep -q "Failures:" "$log_file" 2>/dev/null; then
    exit_code=1
  fi
  
  # Store log file path in global variable for caller
  export ORODC_DOCTOR_LOG_FILE="$log_file"
  
  # Return appropriate exit code
  if [[ $exit_code -eq 0 ]]; then
    return 0
  else
    return 1
  fi
}

# Print results in column format
print_results_table() {
  local results_array=("$@")
  
  printf "\033[0m"
  
  # Print each service result in column format
  for result_line in "${results_array[@]}"; do
    IFS='|' read -r service container image status test_result log_file <<< "$result_line"
    
    # Normalize status display
    local status_display="$status"
    if [[ "$status" == *"Up"* ]] || [[ "$status" == *"running"* ]]; then
      status_display="running"
    elif [[ "$status" == *"Exited"* ]] || [[ "$status" == *"stopped"* ]]; then
      status_display="stopped"
    elif [[ "$status" == *"not found"* ]]; then
      status_display="not found"
    fi
    
    # Colorize status
    local status_color=""
    if [[ "$status_display" == "running" ]]; then
      status_color="\033[32m"
    elif [[ "$status_display" == "stopped" ]] || [[ "$status_display" == "not found" ]]; then
      status_color="\033[31m"
    else
      status_color="\033[33m"
    fi
    
    # Colorize test result
    local result_color=""
    local result_text=""
    if [[ "$test_result" == "PASS" ]]; then
      result_color="\033[32m"
      result_text="PASS"
    elif [[ "$test_result" == "FAIL" ]]; then
      result_color="\033[31m"
      result_text="FAIL"
    elif [[ "$test_result" == "SKIP" ]]; then
      result_color="\033[33m"
      result_text="SKIP"
    else
      result_color="\033[90m"
      result_text="$test_result"
    fi
    
    # Print in column format (use %b for escape sequences)
    printf "Service:   %s\n" "$service"
    printf "Container: %s\n" "$container"
    printf "Image:     %s\n" "$image"
    printf "Status:    %b%s\033[0m\n" "$status_color" "$status_display"
    printf "Test:      %b%s\033[0m\n" "$result_color" "$result_text"
    
    # Show log file path if test failed and log file exists
    if [[ "$test_result" == "FAIL" ]] && [[ -n "$log_file" ]] && [[ -f "$log_file" ]]; then
      printf "Log:       %s\n" "$log_file"
    fi
    
    echo ""
  done
  
  printf "\033[0m"
}

# Run Goss checks from CLI container using docker compose run
run_goss_checks_from_cli() {
  local version="$1"
  local services="$2"
  local doctor_dir="$3"
  local show_table="${4:-true}"
  
  local overall_failed=0
  local results=()
  local service_count=0
  local current_service=0
  
  # Count services
  while IFS= read -r service; do
    if [[ -n "$service" ]]; then
      ((service_count++)) || true
    fi
  done <<< "$services"
  
  # Temporarily disable set -e to prevent script exit on individual test failures
  # CRITICAL: Keep set +e for entire loop to ensure all services are tested
  set +e
  
  # Collect container info and run tests
  while IFS= read -r service || [[ -n "$service" ]]; do
    # Skip empty services
    if [[ -z "$service" ]]; then
      continue
    fi
    
    # Increment counter (don't fail on error)
    ((current_service++)) || true
    
    # DEBUG: Show which service we're processing
    echo "[DEBUG] Processing service $current_service/$service_count: '$service'" >> /tmp/orodc-doctor-trace.log
    
    # Show progress if table mode
    if [[ "$show_table" == "true" ]]; then
      printf "\r\033[K[%d/%d] Checking %s..." "$current_service" "$service_count" "$service" >&2 || true
    fi
    
    # Get container information (don't fail if this fails)
    local container_info=""
    local container_name="${DC_ORO_NAME}_${service}"
    local image="unknown"
    local status="not found"
    
    container_info=$(get_container_info "$service" 2>/dev/null || echo "")
    if [[ -n "$container_info" ]]; then
      IFS='|' read -r container_name image status <<< "$container_info" || true
      # Ensure we have values even if parsing failed
      container_name="${container_name:-${DC_ORO_NAME}_${service}}"
      image="${image:-unknown}"
      status="${status:-not found}"
    fi
    
    # Check healthcheck status if container exists
    local health_status=""
    if [[ "$status" != "not found" ]] && [[ -n "$container_name" ]]; then
      health_status=$(get_container_health_status "$container_name" 2>/dev/null || echo "")
    fi
    
    # Run test (silent mode when showing table)
    local test_result="SKIP"
    local log_file=""
    
    # Normalize status for checking (don't fail on error)
    local normalized_status=""
    normalized_status=$(echo "$status" | tr '[:upper:]' '[:lower:]' 2>/dev/null || echo "$status")
    
    # Check if container exists and is running
    if [[ "$normalized_status" == *"not found"* ]] || [[ -z "$status" ]] || [[ "$status" == "unknown" ]]; then
      test_result="SKIP"
    elif [[ "$normalized_status" == *"restarting"* ]]; then
      # Container is restarting - this is a problem state, mark as FAIL
      test_result="FAIL"
      overall_failed=1
    elif [[ -n "$health_status" ]] && [[ "$health_status" != "healthy" ]]; then
      # Container has healthcheck but is not healthy (unhealthy or starting) - mark as FAIL
      # If healthcheck exists, container must be healthy for tests to pass
      test_result="FAIL"
      overall_failed=1
    elif [[ "$normalized_status" == *"exited"* ]] || [[ "$normalized_status" == *"stopped"* ]]; then
      # Container exists but is stopped - skip test
      test_result="SKIP"
    elif [[ "$normalized_status" == *"up"* ]] || [[ "$normalized_status" == *"running"* ]]; then
      # Container is running - run the test (don't fail if test fails)
      # Create log file for this test
      log_file=$(mktemp "/tmp/orodc-doctor-${service}-XXXXXX.log" 2>/dev/null || echo "/tmp/orodc-doctor-${service}.log")
      
      # Run test and capture exit code (don't fail on error)
      # CRITICAL: Use explicit error handling to prevent loop interruption
      test_result="SKIP"
      local test_exit_code=0
      # CRITICAL: Don't let function failure interrupt loop - always continue
      run_goss_check_for_service "$service" "$version" "$doctor_dir" "$show_table" "$log_file" 2>/dev/null || test_exit_code=$? || true
      if [[ $test_exit_code -eq 0 ]]; then
        test_result="PASS"
      else
        test_result="FAIL"
        overall_failed=1
      fi
    else
      # Unknown status - try to run test anyway (don't fail if test fails)
      # Create log file for this test
      log_file=$(mktemp "/tmp/orodc-doctor-${service}-XXXXXX.log" 2>/dev/null || echo "/tmp/orodc-doctor-${service}.log")
      
      # Run test and capture exit code (don't fail on error)
      # CRITICAL: Use explicit error handling to prevent loop interruption
      test_result="SKIP"
      local test_exit_code=0
      # CRITICAL: Don't let function failure interrupt loop - always continue
      run_goss_check_for_service "$service" "$version" "$doctor_dir" "$show_table" "$log_file" 2>/dev/null || test_exit_code=$? || true
      if [[ $test_exit_code -eq 0 ]]; then
        test_result="PASS"
      else
        test_result="FAIL"
        overall_failed=1
      fi
    fi
    
    # Store result with log file path (always store, even if there were errors)
    # CRITICAL: Always continue loop - don't let any error interrupt
    # Format: service|container|image|status|test_result|log_file
    results+=("${service}|${container_name}|${image}|${status}|${test_result}|${log_file}") || true
    # Ensure we continue to next iteration even if something failed
    true
  done <<< "$services"
  
  # Clear progress line if table mode
  if [[ "$show_table" == "true" ]]; then
    printf "\r\033[K" >&2 || true
  fi
  
  # Print results table if requested (don't fail on error)
  if [[ "$show_table" == "true" ]]; then
    echo ""
    msg_header "Test Results Summary"
    echo ""
    if [[ ${#results[@]} -gt 0 ]]; then
      print_results_table "${results[@]}" || true
    else
      msg_warning "No test results collected"
    fi
    echo ""
  fi
  
  # Don't re-enable set -e here - let caller handle it
  # This ensures we don't interrupt execution if there were test failures
  
  if [[ "$overall_failed" -eq 0 ]]; then
    return 0
  else
    return 1
  fi
}

# Main execution
main() {
  msg_header "Running doctor checks for ${DC_ORO_NAME}"
  echo ""
  
  # Detect OroPlatform version (silently, only use for config selection)
  local oro_version=$(detect_oro_version)
  
  # Find doctor config directory (silently)
  local doctor_dir=$(find_doctor_config_dir)
  
  # Get list of services
  local services=$(get_services_list)
  
  if [[ -z "$services" ]]; then
    msg_error "No services found in compose.yml"
    exit 1
  fi
  
  # Filter out volumes (they don't have containers)
  local container_services=$(echo "$services" | grep -v -E "^(appcode|ssh-hostkeys|home-user|home-root|search-data|mail-certs)$" || echo "$services")
  
  if [[ -z "$container_services" ]]; then
    msg_warning "No container services found"
    exit 0
  fi
  
  # Temporarily disable set -e to prevent script exit on test failures
  # CRITICAL: Keep set +e until all processing is complete
  set +e
  
  # Run all checks from CLI container (including database checks)
  # Each service is tested separately with its own config file
  # Table will be shown automatically
  # CRITICAL: Don't let function failure interrupt - capture exit code explicitly
  local cli_check_failed=0
  run_goss_checks_from_cli "$oro_version" "$container_services" "$doctor_dir" "true" || cli_check_failed=$? || true
  
  # Report results (before re-enabling set -e)
  if [[ "$cli_check_failed" -eq 0 ]]; then
    msg_ok "All service checks passed!"
    # Re-enable set -e only before exit
    set -e
    exit 0
  else
    msg_error "Some service checks failed"
    # Re-enable set -e only before exit
    set -e
    exit 1
  fi
}

main "$@"
