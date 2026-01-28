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

# Execute PHP command in cli container with all arguments
exec ${DOCKER_COMPOSE_BIN_CMD} run --rm cli php "$@"
