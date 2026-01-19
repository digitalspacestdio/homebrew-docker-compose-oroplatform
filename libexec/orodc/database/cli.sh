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

# If no arguments provided, default to bash
if [[ $# -eq 0 ]]; then
  set -- "bash"
fi

# Ensure dependencies are started before running command
# This prevents "Creating..." and "Starting..." messages from appearing during run
# Use spinner to show progress while starting containers
if ! run_with_spinner "Starting containers" "${DOCKER_COMPOSE_BIN_CMD} up -d --remove-orphans --quiet-pull --quiet-build"; then
  # If startup failed, still try to run the command (containers might be partially started)
  true
fi

# Execute command in cli container (different from database-cli)
# Automatically detect interactive mode: if stdin is a terminal, don't use -T (allow TTY)
# If stdin is not a terminal (piped/redirected), use -T to disable TTY
# -q suppresses STDOUT from docker compose, but command output still visible
# --no-deps prevents re-starting dependencies (already started above)
if [[ -t 0 ]]; then
  # Interactive mode: stdin is a terminal - allow TTY allocation
  exec ${DOCKER_COMPOSE_BIN_CMD} run --rm -q --no-deps cli "$@"
else
  # Non-interactive mode: stdin is piped/redirected - disable TTY
  exec ${DOCKER_COMPOSE_BIN_CMD} run --rm -T -q --no-deps cli "$@"
fi
