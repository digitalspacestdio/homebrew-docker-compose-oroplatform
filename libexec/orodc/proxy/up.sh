#!/bin/bash
set -e
if [ "$DEBUG" ]; then set -x; fi

# Determine script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${SCRIPT_DIR}/../lib/ui.sh"

# Resolve Docker binary
DOCKER_BIN=$(resolve_bin "docker" "Docker is required. Install from https://docs.docker.com/get-docker/")
DOCKER_COMPOSE_BIN="$DOCKER_BIN compose"

# Get OroDC compose directory
BREW_PREFIX="$(brew --prefix 2>/dev/null || echo "/home/linuxbrew/.linuxbrew")"

if [[ -d "${BREW_PREFIX}/Homebrew/Library/Taps/digitalspacestdio/homebrew-docker-compose-oroplatform/compose" ]]; then
  DC_ORO_COMPOSE_DIR="${BREW_PREFIX}/Homebrew/Library/Taps/digitalspacestdio/homebrew-docker-compose-oroplatform/compose"
elif [[ -d "${BREW_PREFIX}/share/docker-compose-oroplatform/compose" ]]; then
  DC_ORO_COMPOSE_DIR="${BREW_PREFIX}/share/docker-compose-oroplatform/compose"
else
  msg_error "Could not find OroDC compose directory"
  exit 1
fi

PROXY_COMPOSE_FILE="${DC_ORO_COMPOSE_DIR}/docker-compose-proxy.yml"

if [[ ! -f "$PROXY_COMPOSE_FILE" ]]; then
  msg_error "Proxy compose file not found: $PROXY_COMPOSE_FILE"
  exit 1
fi

msg_info "Starting proxy services..."

# Create shared network if it doesn't exist
if ! ${DOCKER_BIN} network inspect dc_shared_net >/dev/null 2>&1; then
  msg_info "Creating dc_shared_net network..."
  ${DOCKER_BIN} network create dc_shared_net || {
    msg_error "Failed to create dc_shared_net network"
    exit 1
  }
fi

# Configure Traefik bind address if not set
if [[ -z "${TRAEFIK_BIND_ADDRESS:-}" ]]; then
  # Auto-detect environment and suggest default
  IS_WSL=false
  IS_LIMA=false
  DETECTED_ENV=""
  
  # Check WSL
  if grep -qi microsoft /proc/version 2>/dev/null || grep -qi wsl /proc/version 2>/dev/null; then
    IS_WSL=true
    DETECTED_ENV="Windows WSL2"
  fi
  
  # Check Lima VM
  if [[ -d "/lima" ]] || [[ -n "${LIMA_INSTANCE:-}" ]]; then
    IS_LIMA=true
    DETECTED_ENV="Lima VM"
  fi
  
  # Determine default based on environment
  if [[ "$IS_WSL" == "true" ]] || [[ "$IS_LIMA" == "true" ]]; then
    # WSL or Lima VM - need to bind to all interfaces for host access
    SUGGESTED_BIND="0.0.0.0"
    SUGGESTED_REASON="VM/WSL detected - bind to all interfaces for host access"
  else
    # Native Docker (macOS or Linux) or unknown - bind to localhost only
    SUGGESTED_BIND="127.0.0.1"
    SUGGESTED_REASON="Native Docker - bind to localhost only (secure)"
  fi
  
  # Check if running in non-interactive mode (CI/CD or piped)
  if [[ ! -t 0 ]]; then
    # Non-interactive: use suggested default
    export TRAEFIK_BIND_ADDRESS="$SUGGESTED_BIND"
    msg_info "Non-interactive mode: using default bind address: ${SUGGESTED_BIND}"
  else
    # Interactive mode: show prompts
    msg_info ""
    msg_info "Proxy Network Configuration"
    msg_info "============================"
    msg_info ""
    
    msg_info "Choose proxy bind address (affects HTTP, HTTPS, SOCKS5):"
    msg_info ""
    msg_info "  1) 127.0.0.1 (localhost only)"
    msg_info "     - Most secure: Only accessible from this machine"
    msg_info "     - Use for: Native Docker on macOS/Linux"
    msg_info ""
    msg_info "  2) 0.0.0.0 (all interfaces)"
    msg_info "     - Allows access from: VM host + network"
    msg_info "     - Use for: WSL2, Lima VM, remote access"
    msg_info ""
    
    if [[ -n "$DETECTED_ENV" ]]; then
      msg_info "Detected: ${DETECTED_ENV}"
      msg_info "Suggested: ${SUGGESTED_BIND} (${SUGGESTED_REASON})"
    else
      msg_info "Could not detect environment"
      msg_info "Suggested: ${SUGGESTED_BIND} (safe default)"
    fi
    
    msg_info ""
    
    # Interactive prompt with validation
    BIND_CHOICE=$(prompt_selector "Enter choice [1-2], IP address, or press Enter for suggested (${SUGGESTED_BIND}): " "$SUGGESTED_BIND" "1:127.0.0.1" "2:0.0.0.0")
    
    export TRAEFIK_BIND_ADDRESS="$BIND_CHOICE"
    
    case "$BIND_CHOICE" in
      "127.0.0.1")
        msg_ok "Using 127.0.0.1 (localhost only)"
        ;;
      "0.0.0.0")
        msg_ok "Using 0.0.0.0 (all interfaces)"
        msg_warning "Make sure your firewall is properly configured!"
        ;;
      "$SUGGESTED_BIND")
        msg_ok "Using suggested: ${SUGGESTED_BIND}"
        ;;
      *)
        msg_ok "Using custom bind address: ${BIND_CHOICE}"
        ;;
    esac
    
    msg_info ""
    msg_info "To skip this prompt next time, set:"
    msg_info "  export TRAEFIK_BIND_ADDRESS=${TRAEFIK_BIND_ADDRESS}"
    msg_info "Or add to .env.orodc:"
    msg_info "  echo 'TRAEFIK_BIND_ADDRESS=${TRAEFIK_BIND_ADDRESS}' >> .env.orodc"
    msg_info ""
  fi
else
  msg_info "Using bind address: ${TRAEFIK_BIND_ADDRESS} (from environment)"
fi

# Configure SOCKS5 port if not set
if [[ -z "${DC_PROXY_SOCKS5_PORT:-}" ]]; then
  # Check if running in non-interactive mode (CI/CD or piped)
  if [[ ! -t 0 ]]; then
    # Non-interactive: use default port
    export DC_PROXY_SOCKS5_PORT="1080"
    msg_info "Non-interactive mode: using default SOCKS5 port: 1080"
  else
    # Interactive mode: show prompts
    msg_info ""
    msg_info "SOCKS5 Proxy Port Configuration"
    msg_info "================================"
    msg_info ""
    msg_info "Choose SOCKS5 proxy port:"
    msg_info "  - Default: 1080 (standard SOCKS5 port)"
    msg_info "  - Custom: any available port (e.g., 9999)"
    msg_info ""
    
    # Interactive prompt with validation
    PORT_CHOICE=$(prompt_port "Enter SOCKS5 port (press Enter for default: 1080): " "1080")
    
    export DC_PROXY_SOCKS5_PORT="$PORT_CHOICE"
    
    if [[ "$PORT_CHOICE" == "1080" ]]; then
      msg_ok "Using default port: 1080"
    else
      msg_ok "Using custom port: ${PORT_CHOICE}"
    fi
    
    msg_info ""
    msg_info "To skip this prompt next time, set:"
    msg_info "  export DC_PROXY_SOCKS5_PORT=${DC_PROXY_SOCKS5_PORT}"
    msg_info "Or add to .env.orodc:"
    msg_info "  echo 'DC_PROXY_SOCKS5_PORT=${DC_PROXY_SOCKS5_PORT}' >> .env.orodc"
    msg_info ""
  fi
else
  msg_info "Using SOCKS5 port: ${DC_PROXY_SOCKS5_PORT} (from environment)"
fi

# Set log level based on DEBUG environment variable
if [[ "${DEBUG:-}" == "1" ]]; then
  export TRAEFIK_LOG_LEVEL="DEBUG"
else
  export TRAEFIK_LOG_LEVEL="WARNING"
fi

# Pass all remaining arguments to docker compose up
proxy_cmd="${DOCKER_COMPOSE_BIN} -p proxy -f \"$PROXY_COMPOSE_FILE\" up $*"

# Use spinner for detached mode
if [[ "$*" == *"-d"* ]]; then
  run_with_spinner "Starting proxy services" "$proxy_cmd" || {
    msg_error "Failed to start proxy services"
    exit 1
  }
  
  msg_info ""
  msg_info "Bind address: ${TRAEFIK_BIND_ADDRESS:-127.0.0.1}"
  msg_info "Dashboard:    http://${TRAEFIK_BIND_ADDRESS:-127.0.0.1}:8880/traefik/dashboard/"
  msg_info "              http://traefik.docker.local (via SOCKS5)"
  msg_info "              http://proxy.docker.local (via SOCKS5)"
  msg_info "Proxy HTTP:   http://${TRAEFIK_BIND_ADDRESS:-127.0.0.1}:8880"
  msg_info "Proxy HTTPS:  https://${TRAEFIK_BIND_ADDRESS:-127.0.0.1}:8443"
  msg_info "SOCKS5:       ${TRAEFIK_BIND_ADDRESS:-127.0.0.1}:${DC_PROXY_SOCKS5_PORT:-1080}"
  msg_info ""
  msg_warning "To enable HTTPS for *.docker.local domains, install CA certificate:"
  msg_info ""
  msg_info "  orodc proxy install-certs"
  msg_info ""
else
  # Foreground mode - show full output
  # Show dashboard info before starting (containers will start and keep running)
  msg_info ""
  msg_info "Proxy will be available at:"
  msg_info "  Bind address: ${TRAEFIK_BIND_ADDRESS:-127.0.0.1}"
  msg_info "  Dashboard:    http://${TRAEFIK_BIND_ADDRESS:-127.0.0.1}:8880/traefik/dashboard/"
  msg_info "                http://traefik.docker.local (via SOCKS5)"
  msg_info "                http://proxy.docker.local (via SOCKS5)"
  msg_info "  Proxy HTTP:   http://${TRAEFIK_BIND_ADDRESS:-127.0.0.1}:8880"
  msg_info "  Proxy HTTPS:  https://${TRAEFIK_BIND_ADDRESS:-127.0.0.1}:8443"
  msg_info "  SOCKS5:       ${TRAEFIK_BIND_ADDRESS:-127.0.0.1}:${DC_PROXY_SOCKS5_PORT:-1080}"
  msg_info ""
  msg_info "Starting proxy services (press Ctrl+C to stop)..."
  msg_info ""
  
  ${DOCKER_COMPOSE_BIN} -p proxy -f "$PROXY_COMPOSE_FILE" up "$@" || {
    msg_error "Failed to start proxy services"
    exit 1
  }
fi
