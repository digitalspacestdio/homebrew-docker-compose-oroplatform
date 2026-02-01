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

# Default search subcommand is 'reindex'
search_cmd="${1:-reindex}"

# Handle special case for 'reindex' - reindex both backend and website search
if [[ "$search_cmd" == "reindex" ]]; then
  shift
  
  # First reindex backend search (admin panel)
  # Build bash -c command with properly escaped full command string
  # Use single quotes for outer shell to prevent variable expansion issues
  if [[ $# -gt 0 ]]; then
    # Build command string with all arguments properly escaped using printf %q
    local cmd_parts=("php" "./bin/console" "oro:search:reindex")
    for arg in "$@"; do
      cmd_parts+=("$(printf %q "$arg")")
    done
    # Join parts with spaces - printf %q already handles quoting
    local full_cmd
    printf -v full_cmd '%s ' "${cmd_parts[@]}"
    full_cmd="${full_cmd% }"  # Remove trailing space
    backend_cmd="${DOCKER_COMPOSE_BIN_CMD} run --rm cli bash -c '${full_cmd}'"
  else
    backend_cmd="${DOCKER_COMPOSE_BIN_CMD} run --rm cli bash -c 'php ./bin/console oro:search:reindex'"
  fi
  run_with_spinner "Reindexing backend search (admin panel)" "$backend_cmd" || exit $?
  
  # Then reindex website search (storefront)
  if [[ $# -gt 0 ]]; then
    # Build command string with all arguments properly escaped
    local cmd_parts=("php" "./bin/console" "oro:website-search:reindex")
    for arg in "$@"; do
      cmd_parts+=("$(printf %q "$arg")")
    done
    local full_cmd
    printf -v full_cmd '%s ' "${cmd_parts[@]}"
    full_cmd="${full_cmd% }"  # Remove trailing space
    website_cmd="${DOCKER_COMPOSE_BIN_CMD} run --rm cli bash -c '${full_cmd}'"
  else
    website_cmd="${DOCKER_COMPOSE_BIN_CMD} run --rm cli bash -c 'php ./bin/console oro:website-search:reindex'"
  fi
  run_with_spinner "Reindexing website search (storefront)" "$website_cmd" || exit $?
else
  # Execute specific search command in cli container with spinner
  shift
  if [[ $# -gt 0 ]]; then
    # Build command string with all arguments properly escaped
    local cmd_parts=("php" "./bin/console" "oro:search:${search_cmd}")
    for arg in "$@"; do
      cmd_parts+=("$(printf %q "$arg")")
    done
    local full_cmd
    printf -v full_cmd '%s ' "${cmd_parts[@]}"
    full_cmd="${full_cmd% }"  # Remove trailing space
    search_console_cmd="${DOCKER_COMPOSE_BIN_CMD} run --rm cli bash -c '${full_cmd}'"
  else
    search_console_cmd="${DOCKER_COMPOSE_BIN_CMD} run --rm cli bash -c 'php ./bin/console oro:search:${search_cmd}'"
  fi
  run_with_spinner "Executing oro:search:${search_cmd}" "$search_console_cmd" || exit $?
fi
