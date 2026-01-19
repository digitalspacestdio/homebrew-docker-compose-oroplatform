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

# Note: Directory ownership is now handled in Dockerfile.project

# Check if command is provided
if [[ $# -eq 0 ]]; then
  msg_error "No command specified"
  echo "" >&2
  msg_info "Usage: orodc exec <command> [arguments...]"
  echo "" >&2
  msg_info "Examples:"
  echo "  orodc exec ls -la" >&2
  echo "  orodc exec composer --version" >&2
  echo "  orodc exec php -v" >&2
  echo "  orodc exec bash" >&2
  exit 1
fi

# Execute command in cli container with all arguments
# Automatically detect interactive mode: if stdin is a terminal, don't use -T (allow TTY)
# If stdin is not a terminal (piped/redirected), use -T to disable TTY
# -q suppresses STDOUT from docker compose, but command output still visible
if [[ -t 0 ]]; then
  # Interactive mode: stdin is a terminal - allow TTY allocation
  exec ${DOCKER_COMPOSE_BIN_CMD} run --rm -q cli "$@"
else
  # Non-interactive mode: stdin is piped/redirected - disable TTY
  exec ${DOCKER_COMPOSE_BIN_CMD} run --rm -T -q cli "$@"
fi
