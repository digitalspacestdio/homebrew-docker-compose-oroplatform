#!/bin/bash
set -e
if [ "$DEBUG" ]; then set -x; fi

# Determine script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/ui.sh"
source "${SCRIPT_DIR}/lib/environment.sh"

# Check that we're in a project
# Note: initialize_environment is called by router (bin/orodc) before routing to this script
check_in_project || exit 1

# Check if SSH port is available
if [[ -z "${DC_ORO_PORT_SSH:-}" ]]; then
  msg_error "SSH port not configured. Please initialize the environment first."
  exit 1
fi

# Check if SSH container (SSH server) is running
# The container name pattern is: ${DC_ORO_NAME}_ssh_...
ssh_container_running=false
if command -v docker >/dev/null 2>&1; then
  docker_bin="${DOCKER_BIN:-$(command -v docker)}"
  # Check if any ssh container for this project is running
  ssh_containers=$("$docker_bin" ps --filter "name=${DC_ORO_NAME}_ssh" --format "{{.Names}}" 2>/dev/null || true)
  if [[ -n "$ssh_containers" ]]; then
    ssh_container_running=true
  fi
fi

# If container is not running, start it
if [[ "$ssh_container_running" == "false" ]]; then
  msg_info "SSH container is not running. Starting it..."
  
  # Check if compose.yml exists, generate if needed
  if [[ ! -f "${DC_ORO_CONFIG_DIR}/compose.yml" ]]; then
    msg_info "Generating docker-compose configuration..."
    set +e
    DC_ORO_NAME="$DC_ORO_NAME" bash -c "${DOCKER_COMPOSE_BIN_CMD} config" > "${DC_ORO_CONFIG_DIR}/compose.yml" 2>/dev/null
    compose_config_result=$?
    set -e
    
    if [[ $compose_config_result -ne 0 ]]; then
      msg_error "Failed to generate docker-compose configuration."
      msg_info "Please ensure the environment is properly initialized."
      exit 1
    fi
  fi
  
  # Start the cli container
  # Temporarily disable set -e to handle potential errors
  set +e
  
  # Source docker-utils to get generate_compose_config_if_needed
  source "${SCRIPT_DIR}/lib/docker-utils.sh"
  
  # Generate compose config if needed (using function from docker-utils.sh)
  # This ensures compose.yml exists before trying to start
  left_flags=()
  left_options=()
  generate_compose_config_if_needed "up"
  
  # Ensure ORO_SSH_PUBLIC_KEY is set if SSH key exists
  if [[ -z "${ORO_SSH_PUBLIC_KEY:-}" ]] && [[ -f "${DC_ORO_CONFIG_DIR}/ssh_id_ed25519.pub" ]]; then
    export ORO_SSH_PUBLIC_KEY=$(cat "${DC_ORO_CONFIG_DIR}/ssh_id_ed25519.pub")
  fi
  
  # Try to start ssh container directly with docker compose
  if [[ -n "${DEBUG:-}" ]]; then
    # In debug mode, show output
    DC_ORO_NAME="$DC_ORO_NAME" ORO_SSH_PUBLIC_KEY="${ORO_SSH_PUBLIC_KEY:-}" bash -c "${DOCKER_COMPOSE_BIN_CMD} up -d ssh"
    start_result=$?
  else
    # In normal mode, suppress output but capture errors
    error_output=$(DC_ORO_NAME="$DC_ORO_NAME" ORO_SSH_PUBLIC_KEY="${ORO_SSH_PUBLIC_KEY:-}" bash -c "${DOCKER_COMPOSE_BIN_CMD} up -d ssh" 2>&1)
    start_result=$?
    if [[ $start_result -ne 0 ]]; then
      # Show error output if failed
      echo "$error_output" >&2
    fi
  fi
  
  set -e
  
  if [[ $start_result -ne 0 ]]; then
    msg_error "Failed to start SSH container."
    if [[ -z "${DEBUG:-}" ]]; then
      msg_info "Run with DEBUG=1 to see detailed error messages: DEBUG=1 orodc ssh"
    fi
    msg_info "Try running manually: orodc compose up -d ssh"
    exit 1
  fi
  
  # Verify container actually started
  sleep 2
  ssh_containers_after=$("$docker_bin" ps --filter "name=${DC_ORO_NAME}_ssh" --format "{{.Names}}" 2>/dev/null || true)
  if [[ -z "$ssh_containers_after" ]]; then
    # Check if container exists but is stopped/exited
    ssh_containers_stopped=$("$docker_bin" ps -a --filter "name=${DC_ORO_NAME}_ssh" --format "{{.Names}}|{{.Status}}" 2>/dev/null || true)
    if [[ -n "$ssh_containers_stopped" ]]; then
      msg_error "Container started but immediately stopped."
      msg_info "Container status:"
      echo "$ssh_containers_stopped" | while IFS='|' read -r name status; do
        echo "  $name: $status" >&2
      done
      msg_info "Check logs with: docker logs ${DC_ORO_NAME}_ssh_*"
      exit 1
    else
      msg_error "Container failed to start. Check docker compose logs."
      exit 1
    fi
  fi
  
  # Wait for SSH service to be ready (check health or wait a bit)
  msg_info "Waiting for SSH service to be ready..."
  max_attempts=30
  attempt=0
  while [[ $attempt -lt $max_attempts ]]; do
    # Try to connect to SSH port (using bash built-in /dev/tcp)
    if bash -c "echo > /dev/tcp/127.0.0.1/${DC_ORO_PORT_SSH}" 2>/dev/null; then
      break
    fi
    
    # Also check container health status
    if [[ $((attempt % 5)) -eq 0 ]] && [[ $attempt -gt 0 ]]; then
      container_status=$("$docker_bin" ps --filter "name=${DC_ORO_NAME}_ssh" --format "{{.Status}}" 2>/dev/null | head -1 || true)
      if [[ -n "$container_status" ]]; then
        if [[ "$container_status" == *"Exited"* ]] || [[ "$container_status" == *"Dead"* ]]; then
          msg_error "Container stopped unexpectedly. Status: $container_status"
          msg_info "Check logs with: docker logs ${DC_ORO_NAME}_ssh_*"
          exit 1
        fi
      fi
    fi
    
    sleep 1
    attempt=$((attempt + 1))
    # Show progress every 5 seconds
    if [[ $((attempt % 5)) -eq 0 ]] && [[ $attempt -gt 0 ]]; then
      echo -n "." >&2
    fi
  done
  
  echo "" >&2
  
  if [[ $attempt -eq $max_attempts ]]; then
    msg_warning "SSH port is not responding after ${max_attempts} seconds."
    # Check final container status
    container_status=$("$docker_bin" ps --filter "name=${DC_ORO_NAME}_ssh" --format "{{.Names}}|{{.Status}}" 2>/dev/null | head -1 || true)
    if [[ -n "$container_status" ]]; then
      msg_info "Container status: $container_status"
    fi
    msg_info "You can check logs with: docker logs ${DC_ORO_NAME}_ssh_*"
    msg_info "Trying to connect anyway..."
  else
    msg_ok "SSH container is ready"
  fi
fi

# Default SSH user (can be overridden via DC_ORO_SSH_USER)
# Use DC_ORO_USER_NAME if available (set during environment initialization)
SSH_USER="${DC_ORO_SSH_USER:-${DC_ORO_USER_NAME:-developer}}"
SSH_HOST="${DC_ORO_SSH_BIND_HOST:-127.0.0.1}"

# Use the SSH key from DC_ORO_CONFIG_DIR (same as old implementation)
SSH_KEY="${DC_ORO_CONFIG_DIR}/ssh_id_ed25519"

# Create SSH key if it doesn't exist (same as old implementation)
if [[ ! -f "$SSH_KEY" ]]; then
  msg_info "Creating SSH key..."
  ssh-keygen -t ed25519 -f "${SSH_KEY}" -N "" -q
  chmod 0600 "${SSH_KEY}"
  msg_ok "SSH key created: ${SSH_KEY}"
  
  # Export public key for container (needed for authorized_keys)
  if [[ -f "${SSH_KEY}.pub" ]]; then
    export ORO_SSH_PUBLIC_KEY=$(cat "${SSH_KEY}.pub")
    
    # If SSH container is running, restart it to apply the new key
    # Use 'up -d' instead of 'restart' to re-read environment variables
    if [[ "$ssh_container_running" == "true" ]]; then
      msg_info "Restarting SSH container to apply new key..."
      set +e
      DC_ORO_NAME="$DC_ORO_NAME" ORO_SSH_PUBLIC_KEY="$ORO_SSH_PUBLIC_KEY" bash -c "${DOCKER_COMPOSE_BIN_CMD} up -d ssh" >/dev/null 2>&1
      restart_result=$?
      set -e
      
      if [[ $restart_result -eq 0 ]]; then
        msg_ok "SSH container restarted with new key"
        # Wait a moment for container to be ready
        sleep 2
      else
        msg_warning "Failed to restart SSH container. Please restart manually: orodc compose up -d ssh"
      fi
    fi
  fi
fi

# Ensure SSH key exists
if [[ ! -f "$SSH_KEY" ]]; then
  msg_error "Failed to create SSH key: $SSH_KEY"
  exit 1
fi

# Connect via SSH to the container
# Use same options as old implementation:
# - IdentitiesOnly=yes: Use only the specified key (don't try other keys)
# - ForwardAgent=no: Don't forward SSH agent
# - SendEnv=COMPOSER_AUTH: Send COMPOSER_AUTH environment variable
exec ssh \
  -o SendEnv=COMPOSER_AUTH \
  -o UserKnownHostsFile=/dev/null \
  -o StrictHostKeyChecking=no \
  -o 'ForwardAgent no' \
  -o IdentitiesOnly=yes \
  -i "${SSH_KEY}" \
  -p "${DC_ORO_PORT_SSH}" \
  ${ORO_DC_SSH_ARGS:-} \
  "${SSH_USER}@${SSH_HOST}" \
  "$@"
