#!/bin/bash
set -e
if [ "$DEBUG" ]; then set -x; fi

# Determine script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/ui.sh"
source "${SCRIPT_DIR}/lib/environment.sh"

# Check that we're in a project
check_in_project || exit 1

# Remove existing compose.yml to force regeneration
if [[ -f "${DC_ORO_CONFIG_DIR}/compose.yml" ]]; then
  rm -f "${DC_ORO_CONFIG_DIR}/compose.yml"
fi

# Regenerate by calling compose config with spinner
config_refresh_cmd="${DOCKER_COMPOSE_BIN_CMD} config > /dev/null 2>&1"
run_with_spinner "Regenerating compose.yml configuration" "$config_refresh_cmd" || {
  msg_error "Failed to generate compose.yml"
  exit 1
}

msg_ok "Configuration refreshed successfully"
msg_info "New compose.yml generated at: ${DC_ORO_CONFIG_DIR}/compose.yml"
