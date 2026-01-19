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

msg_warning "This will remove all containers, volumes, networks, and images for this project"
if ! confirm_yes_no "Are you sure you want to purge everything?"; then
  msg_info "Purge cancelled"
  exit 0
fi

# Stop and remove containers with spinner, also remove locally built images
purge_cmd="${DOCKER_COMPOSE_BIN_CMD} down -v --remove-orphans --rmi local"
run_with_spinner "Stopping and removing containers" "$purge_cmd" || exit $?

# Remove any remaining containers, volumes, and networks with project prefix
# (docker compose down may miss some resources created manually or orphaned)
if [[ -n "${DC_ORO_NAME:-}" ]]; then
  project_prefix="${DC_ORO_NAME}_"
  
  # Find and remove containers with project prefix
  remaining_containers=$(docker ps -aq --filter "name=${project_prefix}" --format "{{.ID}}" 2>/dev/null | grep "^" || true)
  if [[ -n "$remaining_containers" ]]; then
    echo "$remaining_containers" | while read -r container_id; do
      [[ -n "$container_id" ]] && docker rm -f "$container_id" 2>/dev/null || true
    done
  fi
  
  # Remove all volumes with project prefix (docker compose down -v may miss some)
  remaining_volumes=$(docker volume ls --filter "name=${project_prefix}" --format "{{.Name}}" 2>/dev/null | grep "^" || true)
  if [[ -n "$remaining_volumes" ]]; then
    echo "$remaining_volumes" | while read -r volume_name; do
      [[ -n "$volume_name" ]] && docker volume rm "$volume_name" 2>/dev/null || true
    done
  fi
  
  # Remove all networks with project prefix
  remaining_networks=$(docker network ls --filter "name=${project_prefix}" --format "{{.Name}}" 2>/dev/null | grep "^" || true)
  if [[ -n "$remaining_networks" ]]; then
    echo "$remaining_networks" | while read -r network_name; do
      # Filter out default networks (bridge, host, none) and shared networks
      if [[ -n "$network_name" ]] && [[ "$network_name" != "bridge" ]] && [[ "$network_name" != "host" ]] && [[ "$network_name" != "none" ]] && [[ "$network_name" != "dc_shared_net" ]]; then
        docker network rm "$network_name" 2>/dev/null || true
      fi
    done
  fi
  
  # Remove project-specific images (built images with project name prefix)
  # Docker Compose creates images with format: projectname_service (lowercase, with underscores)
  # Convert project name to lowercase for matching (Docker Compose uses lowercase)
  project_name_lower=$(echo "${DC_ORO_NAME:-}" | tr '[:upper:]' '[:lower:]' | tr '-' '_')
  
  # Find images by project name pattern (Docker Compose format: projectname_service)
  # Also check for images matching container name patterns
  project_images=$(docker images --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | \
    grep -E "^(${project_name_lower}|${DC_ORO_NAME:-})[_-](fpm|cli|websocket|ssh)" || true)
  
  if [[ -n "$project_images" ]]; then
    echo "$project_images" | while read -r image_name; do
      if [[ -n "$image_name" ]]; then
        docker rmi -f "$image_name" 2>/dev/null || true
      fi
    done
  fi
  
  # Also check for images with project name as prefix (handles various naming conventions)
  all_project_images=$(docker images --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | \
    grep -E "^(${project_name_lower}|${DC_ORO_NAME:-})" || true)
  
  if [[ -n "$all_project_images" ]]; then
    echo "$all_project_images" | while read -r image_name; do
      # Skip base images and external images (ghcr.io, docker.elastic.co, etc.)
      if [[ -n "$image_name" ]] && \
         [[ ! "$image_name" =~ ^(ghcr\.io|docker\.elastic\.co|opensearchproject|valkey|redis|mysql|rabbitmq|percona|xhgui|oroinc|busybox) ]]; then
        docker rmi -f "$image_name" 2>/dev/null || true
      fi
    done
  fi
fi

# Remove entire configuration directory (includes compose.yml and all other files)
# Try multiple possible locations to ensure we delete the correct directory
config_dirs_to_remove=()
config_dir_abs=""

# Primary location from DC_ORO_CONFIG_DIR
if [[ -n "${DC_ORO_CONFIG_DIR:-}" ]] && [[ -d "${DC_ORO_CONFIG_DIR}" ]]; then
  config_dir_abs=$(realpath "${DC_ORO_CONFIG_DIR}" 2>/dev/null || echo "${DC_ORO_CONFIG_DIR}")
  config_dirs_to_remove+=("${config_dir_abs}")
fi

# Alternative locations (in case DC_ORO_CONFIG_DIR was not set correctly)
if [[ -n "${DC_ORO_NAME:-}" ]]; then
  alt_dir1="${HOME}/.docker-compose-oroplatform/${DC_ORO_NAME}"
  alt_dir2="${HOME}/.orodc/${DC_ORO_NAME}"
  
  if [[ -d "${alt_dir1}" ]]; then
    alt_dir1_abs=$(realpath "${alt_dir1}" 2>/dev/null || echo "${alt_dir1}")
    if [[ "${alt_dir1_abs}" != "${config_dir_abs}" ]]; then
      config_dirs_to_remove+=("${alt_dir1_abs}")
    fi
  fi
  if [[ -d "${alt_dir2}" ]]; then
    alt_dir2_abs=$(realpath "${alt_dir2}" 2>/dev/null || echo "${alt_dir2}")
    if [[ "${alt_dir2_abs}" != "${config_dir_abs}" ]]; then
      config_dirs_to_remove+=("${alt_dir2_abs}")
    fi
  fi
fi

# Remove all found directories
for dir in "${config_dirs_to_remove[@]}"; do
  if [[ -d "${dir}" ]]; then
    run_with_spinner "Removing configuration directory" "rm -rf \"${dir}\"" || exit $?
    
    # Verify deletion succeeded
    if [[ -d "${dir}" ]]; then
      msg_error "Failed to remove configuration directory: ${dir}"
      exit 1
    fi
  fi
done

# Remove environment from registry
if [[ -n "${DC_ORO_NAME:-}" ]]; then
  unregister_environment "${DC_ORO_NAME}" 2>/dev/null || true
fi

msg_ok "Project purged successfully"
