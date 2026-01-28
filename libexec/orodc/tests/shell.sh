#!/bin/bash
set -e
if [ "$DEBUG" ]; then set -x; fi

# Determine script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${SCRIPT_DIR}/../lib/ui.sh"
source "${SCRIPT_DIR}/../lib/environment.sh"

# Check that we're in a project
check_in_project || exit 1

# Build test-aware compose command including test services
TEST_COMPOSE_CMD="${DOCKER_COMPOSE_BIN_CMD}"
if [[ -f "${DC_ORO_CONFIG_DIR}/docker-compose-test.yml" ]]; then
  TEST_COMPOSE_CMD="${TEST_COMPOSE_CMD} -f ${DC_ORO_CONFIG_DIR}/docker-compose-test.yml"
fi

# Open shell in test-cli container
exec ${TEST_COMPOSE_CMD} run --rm test-cli bash "$@"
