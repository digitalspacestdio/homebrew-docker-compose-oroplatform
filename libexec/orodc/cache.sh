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

# Default cache subcommand is 'clear'
cache_cmd="${1:-clear}"

# Always remove cache directories through CLI container before executing cache command
# docker compose run automatically starts containers if needed
# -q flag suppresses docker compose output (Creating..., Starting...) but keeps command output
if [[ "$cache_cmd" == "clear" ]]; then
  # Remove all cache directories through CLI container
  # Errors are treated as warnings
  cache_clear_cmd="${DOCKER_COMPOSE_BIN_CMD} run --rm -q cli bash -c \"rm -rf var/cache/* || true\""
  
  if ! eval "$cache_clear_cmd"; then
    # Command failed - show warning
    msg_warning "Some cache directories may not have been removed"
  fi
fi

# Execute cache command in cli container
# docker compose run automatically starts containers if needed
# -q flag suppresses docker compose output (Creating..., Starting...) but keeps command output
cache_console_cmd="${DOCKER_COMPOSE_BIN_CMD} run --rm -q cli php ./bin/console \"cache:${cache_cmd}\" \"${@:2}\""
eval "$cache_console_cmd" || exit $?
