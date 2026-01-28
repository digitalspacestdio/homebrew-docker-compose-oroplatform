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
  backend_cmd="${DOCKER_COMPOSE_BIN_CMD} run --rm cli php ./bin/console oro:search:reindex $*"
  run_with_spinner "Reindexing backend search (admin panel)" "$backend_cmd" || exit $?
  
  # Then reindex website search (storefront)
  website_cmd="${DOCKER_COMPOSE_BIN_CMD} run --rm cli php ./bin/console oro:website-search:reindex $*"
  run_with_spinner "Reindexing website search (storefront)" "$website_cmd" || exit $?
else
  # Execute specific search command in cli container with spinner
  shift
  search_console_cmd="${DOCKER_COMPOSE_BIN_CMD} run --rm cli php ./bin/console \"oro:search:${search_cmd}\" $*"
  run_with_spinner "Executing oro:search:${search_cmd}" "$search_console_cmd" || exit $?
fi
