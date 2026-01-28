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

# Stop proxy services
proxy_down_cmd="${DOCKER_COMPOSE_BIN} -p proxy -f \"$PROXY_COMPOSE_FILE\" down $*"

run_with_spinner "Stopping proxy services" "$proxy_down_cmd" || {
  msg_error "Failed to stop proxy services"
  exit 1
}
