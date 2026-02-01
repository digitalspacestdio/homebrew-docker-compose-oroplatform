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
# Build cli image first (if needed) to avoid "No services to build" warnings during run
# This ensures images are built/pulled before run command executes (same approach as in 'up' command)
if [[ -z "${DEBUG:-}" ]] && [[ -z "${VERBOSE:-}" ]]; then
  # Build cli image if needed (with spinner for long operations, silent if already built)
  # docker compose build will be fast if image is already up-to-date
  build_cmd="${DOCKER_COMPOSE_BIN_CMD} build --quiet cli"
  run_with_spinner "Building cli image" "$build_cmd" >/dev/null 2>&1 || true
fi

# Start containers silently (redirect output to /dev/null) to avoid "completed" message
# Only show output if there's an error
if ! ${DOCKER_COMPOSE_BIN_CMD} up -d --remove-orphans --quiet-pull --quiet-build >/dev/null 2>&1; then
  # If startup failed, show error but still try to run the command (containers might be partially started)
  msg_warning "Failed to start some containers, continuing anyway..."
fi

# Execute command in cli container (different from database-cli)
# Automatically detect interactive mode: if stdin is a terminal, don't use -T (allow TTY)
# If stdin is not a terminal (piped/redirected), use -T to disable TTY
# -q suppresses STDOUT from docker compose, but command output still visible
# --no-deps prevents re-starting dependencies (already started above)
# Filter out "No services to build" warnings (images are already built above, so these warnings are harmless)
if [[ -t 0 ]]; then
  # Interactive mode: stdin is a terminal - allow TTY allocation
  # -i keeps stdin open (for interactive input)
  # -t allocates a pseudo-TTY (required for interactive shells)
  exec ${DOCKER_COMPOSE_BIN_CMD} run --rm -q --no-deps -it cli "$@" 2> >(grep -v "No services to build" >&2)
else
  # Non-interactive mode: stdin is piped/redirected - disable TTY
  exec ${DOCKER_COMPOSE_BIN_CMD} run --rm -T -q --no-deps cli "$@" 2> >(grep -v "No services to build" >&2)
fi
