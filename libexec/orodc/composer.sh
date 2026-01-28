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

# Run post-install scripts via composer
run_post_install_scripts() {
  local composer_file="${DC_ORO_APPDIR}/composer.json"
  
  if [[ ! -f "$composer_file" ]]; then
    msg_warning "composer.json not found, skipping post-install scripts"
    return 0
  fi
  
  # Check if post-install-cmd exists in composer.json
  local has_post_install=false
  if command -v jq >/dev/null 2>&1; then
    if jq -e '.scripts."post-install-cmd"?' "$composer_file" >/dev/null 2>&1; then
      has_post_install=true
    fi
  else
    if grep -q '"post-install-cmd"' "$composer_file" 2>/dev/null; then
      has_post_install=true
    fi
  fi
  
  if [[ "$has_post_install" == "false" ]]; then
    msg_info "No post-install scripts found in composer.json"
    return 0
  fi
  
  # Run all post-install scripts via composer
  local script_cmd="${DOCKER_COMPOSE_BIN_CMD} run --rm -T cli bash -c \"composer run-script --no-interaction post-install-cmd\""
  
  if ! run_with_spinner "Executing post-install scripts" "$script_cmd"; then
    msg_error "Post-install scripts failed"
    return 1
  fi
  
  return 0
}

# For composer install, create config/parameters.yml from dist file if not exists
# and run install in two phases: packages + post-install scripts
if [[ "${1}" == "install" ]]; then
  ${DOCKER_COMPOSE_BIN_CMD} run --rm cli bash -c "if [[ ! -f ${DC_ORO_APPDIR}/config/parameters.yml ]] && [[ -f ${DC_ORO_APPDIR}/config/parameters.yml.dist ]]; then cp ${DC_ORO_APPDIR}/config/parameters.yml.dist ${DC_ORO_APPDIR}/config/parameters.yml; fi" 2>/dev/null || true
  
  # Phase 1: Install packages without post-install scripts
  composer_install_cmd="${DOCKER_COMPOSE_BIN_CMD} run --rm -T cli bash -c \"composer install --no-scripts --no-interaction\""
  run_with_spinner "Installing composer packages" "$composer_install_cmd" || exit $?

  # Phase 2: Run post-install scripts
  run_post_install_scripts || exit $?
else
  # Execute other composer commands directly (usually fast)
  exec ${DOCKER_COMPOSE_BIN_CMD} run --rm cli composer "$@"
fi
