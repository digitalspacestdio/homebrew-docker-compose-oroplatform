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
# Note: initialize_environment is called by router (bin/orodc) before routing to this script
check_in_project || exit 1

# Parse compose flags into left/right arrays
# This separates flags before/after the compose command
parse_compose_flags "$@"

# Get the compose command (first non-flag argument)
compose_cmd="${args[0]:-}"
docker_services="${args[*]:1}"

# Validate that a compose command was provided
if [[ -z "$compose_cmd" ]]; then
  msg_error "No Docker Compose command specified"
  echo ""
  msg_info "Usage: orodc compose <command> [options] [services]"
  echo ""
  msg_info "Common commands:"
  echo "   ps                    List containers"
  echo "   up -d                 Start services in background"
  echo "   down                  Stop and remove containers"
  echo "   logs -f               Follow logs"
  echo "   build                 Build or rebuild services"
  echo "   restart               Restart services"
  echo "   exec <service> <cmd>  Execute command in running container"
  echo ""
  msg_info "All Docker Compose V2 commands are supported:"
  echo "   build, config, cp, create, down, events, exec, export"
  echo "   images, kill, logs, ls, pause, port, ps, pull, push"
  echo "   restart, rm, run, scale, start, stats, stop, top"
  echo "   unpause, up, version, volumes, wait, watch"
  exit 1
fi

# Debug logging
debug_log "compose.sh: command='$compose_cmd' services='$docker_services'"
debug_log "compose.sh: left_flags=(${left_flags[*]})"
debug_log "compose.sh: left_options=(${left_options[*]})"
debug_log "compose.sh: right_flags=(${right_flags[*]})"
debug_log "compose.sh: right_options=(${right_options[*]})"

# Generate compose.yml config file if needed
# This creates the merged config from all compose files
generate_compose_config_if_needed "$compose_cmd"

# Special handling for 'up' command - two-phase build+start
if [[ "$compose_cmd" == "up" ]]; then
  handle_compose_up
  exit $?
fi

# For all other commands, execute directly
exec_compose_command "$compose_cmd" "$docker_services"
exit $?
