#!/bin/bash
set -e
if [ "$DEBUG" ]; then set -x; fi

# Determine script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/ui.sh"
source "${SCRIPT_DIR}/lib/environment.sh"

# Check if running in interactive mode
is_interactive() {
  [ -t 0 ] && [ -t 1 ]
}

# List environments in non-interactive mode (JSON output)
list_environments_json() {
  # Check if jq is available
  if ! command -v jq >/dev/null 2>&1; then
    msg_error "jq is not installed. Cannot list environments."
    msg_info "Install jq: brew install jq"
    exit 1
  fi
  
  local registry=$(get_environment_registry)
  local env_count=$(echo "$registry" | jq '.environments | length')
  
  if [[ "$env_count" -eq 0 ]]; then
    echo "[]"
    return 0
  fi
  
  # Build JSON array with status
  local result="["
  local first=true
  
  while IFS='|' read -r name path last_used; do
    # Skip environments where path doesn't exist
    if [[ ! -d "$path" ]]; then
      continue
    fi
    if [[ "$first" == "true" ]]; then
      first=false
    else
      result+=","
    fi
    
    local status=$(get_environment_status "$name" "$path")
    result+="{\"name\":\"$name\",\"path\":\"$path\",\"status\":\"$status\",\"last_used\":\"$last_used\"}"
  done < <(echo "$registry" | jq -r '.environments | sort_by(.name) | .[] | "\(.name)|\(.path)|\(.last_used)"')
  
  result+="]"
  echo "$result" | jq '.'
}

# List environments in table format (non-interactive)
list_environments_table() {
  # Check if jq is available
  if ! command -v jq >/dev/null 2>&1; then
    msg_error "jq is not installed. Cannot list environments."
    msg_info "Install jq: brew install jq"
    exit 1
  fi
  
  local registry=$(get_environment_registry)
  local env_count=$(echo "$registry" | jq '.environments | length')
  
  if [[ "$env_count" -eq 0 ]]; then
    msg_info "No environments registered yet."
    return 0
  fi
  
  # Build arrays of environment data
  local env_names=()
  local env_paths=()
  local env_statuses=()
  
  # Collect environment data
  # Sort by name (alphabetically) before processing
  while IFS='|' read -r name path last_used; do
    # Skip environments where path doesn't exist
    if [[ ! -d "$path" ]]; then
      continue
    fi
    env_names+=("$name")
    env_paths+=("$path")
    local status=$(get_environment_status "$name" "$path")
    env_statuses+=("$status")
  done < <(echo "$registry" | jq -r '.environments | sort_by(.name) | .[] | "\(.name)|\(.path)|\(.last_used)"')
  
  # Display table
  printf "%-30s %-12s %s\n" "NAME" "STATUS" "PATH"
  printf "%-30s %-12s %s\n" "----" "------" "----"
  
  local i=0
  for name in "${env_names[@]}"; do
    local status="${env_statuses[$i]}"
    local path="${env_paths[$i]}"
    local marker=""
    
    if [[ "$name" == "${DC_ORO_NAME:-}" ]]; then
      marker=" (current)"
    fi
    
    printf "%-30s %-12s %s%s\n" "$name" "$status" "$path" "$marker"
    i=$((i + 1))
  done
}

# Main function
main() {
  local format="${1:-table}"
  local exit_code=0
  
  if is_interactive; then
    # Interactive mode - use existing function from environment.sh
    # This function handles selection and exports ORODC_SELECTED_PATH
    list_environments
    exit_code=$?
    
    # Exit code 2 means environment switch was requested
    # The path is already exported in ORODC_SELECTED_PATH by list_environments
    exit $exit_code
  else
    # Non-interactive mode
    set +e
    case "$format" in
      json)
        list_environments_json
        exit_code=$?
        ;;
      table|*)
        list_environments_table
        exit_code=$?
        ;;
    esac
    set -e
    exit $exit_code
  fi
}

main "$@"
