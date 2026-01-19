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

# Execute platform update: clear cache and run oro:platform:update
platform_update_cmd="${DOCKER_COMPOSE_BIN_CMD} run --rm cli bash -c \"rm -rf var/cache/* || true; php bin/console oro:platform:update --force $*\""
run_with_spinner "Updating platform" "$platform_update_cmd" || exit $?
