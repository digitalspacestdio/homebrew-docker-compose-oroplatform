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
if [[ "$cache_cmd" == "clear" ]]; then
  # Remove all cache directories through CLI container with spinner
  # Errors are treated as warnings - log is saved for user inspection
  cache_clear_cmd="${DOCKER_COMPOSE_BIN_CMD} run --rm cli bash -c \"rm -rf var/cache/* || true\""
  
  # Use run_with_spinner like in start containers
  # run_with_spinner will show spinner and handle logging automatically
  # We capture exit code but don't exit - errors are treated as warnings
  if ! run_with_spinner "Removing cache directories" "$cache_clear_cmd"; then
    # Command failed - show warning (run_with_spinner already showed error and log location)
    msg_warning "Some cache directories may not have been removed (see log above for details)"
  fi
fi

# Execute cache command in cli container with spinner
cache_console_cmd="${DOCKER_COMPOSE_BIN_CMD} run --rm cli php ./bin/console \"cache:${cache_cmd}\" \"${@:2}\""
run_with_spinner "Executing cache:${cache_cmd}" "$cache_console_cmd" || exit $?
