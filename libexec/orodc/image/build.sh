#!/bin/bash
set -e
if [ "$DEBUG" ]; then set -x; fi

# Determine script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../lib/common.sh"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../lib/ui.sh"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../lib/environment.sh"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../lib/docker-utils.sh"

# Resolve Docker binary
DOCKER_BIN=$(resolve_bin "docker" "Docker is required. Install from https://docs.docker.com/get-docker/")

# Get Homebrew prefix dynamically
BREW_PREFIX="$(brew --prefix 2>/dev/null || echo "/home/linuxbrew/.linuxbrew")"

# Find compose directory
if [[ -d "${BREW_PREFIX}/Homebrew/Library/Taps/digitalspacestdio/homebrew-docker-compose-oroplatform/compose" ]]; then
  DC_ORO_COMPOSE_DIR="${BREW_PREFIX}/Homebrew/Library/Taps/digitalspacestdio/homebrew-docker-compose-oroplatform/compose"
elif [[ -d "${BREW_PREFIX}/share/docker-compose-oroplatform/compose" ]]; then
  DC_ORO_COMPOSE_DIR="${BREW_PREFIX}/share/docker-compose-oroplatform/compose"
else
  msg_error "Could not find OroDC compose directory"
  exit 1
fi

DOCKER_DIR="${DC_ORO_COMPOSE_DIR}/docker"

if [[ ! -d "$DOCKER_DIR" ]]; then
  msg_error "Docker directory not found: $DOCKER_DIR"
  exit 1
fi

msg_header "OroDC Image Builder"
msg_info ""

# Check for --no-cache flag
NO_CACHE_FLAG=""
has_no_cache=false
for arg in "$@"; do
  if [[ "$arg" == "--no-cache" ]]; then
    has_no_cache=true
    break
  fi
done

if [[ "$has_no_cache" == "true" ]]; then
  NO_CACHE_FLAG="--no-cache"
  msg_info "Build mode: No cache (full rebuild)"
else
  msg_info "Build mode: Using cache (faster)"
fi
msg_info ""

# Load environment from .env.orodc if it exists
if [[ -f ".env.orodc" ]]; then
  msg_info "Loading configuration from .env.orodc"
  set -a
  # shellcheck disable=SC1091
  source ".env.orodc"
  set +a
fi

# Detect PHP version
DC_ORO_PHP_VERSION="${DC_ORO_PHP_VERSION:-8.4}"
DC_ORO_NODE_VERSION="${DC_ORO_NODE_VERSION:-22}"
DC_ORO_COMPOSER_VERSION="${DC_ORO_COMPOSER_VERSION:-2}"
DC_ORO_PHP_DIST="${DC_ORO_PHP_DIST:-alpine}"

msg_ok "Configuration detected:"
msg_info "  PHP Version:      ${DC_ORO_PHP_VERSION}"
msg_info "  Node.js Version:  ${DC_ORO_NODE_VERSION}"
msg_info "  Composer Version: ${DC_ORO_COMPOSER_VERSION}"
msg_info "  PHP Distribution: ${DC_ORO_PHP_DIST}"
msg_info ""

# Check available disk space
msg_info "Checking available disk space..."
AVAILABLE_SPACE_KB=$(df -k . | tail -1 | awk '{print $4}')
AVAILABLE_SPACE_GB=$((AVAILABLE_SPACE_KB / 1024 / 1024))

if [[ $AVAILABLE_SPACE_GB -lt 5 ]]; then
  msg_warning "Low disk space detected: ${AVAILABLE_SPACE_GB}GB available"
  msg_warning "Docker image builds require at least 5GB of free space"
  msg_warning "Build may fail if disk space runs out"
  msg_info ""
  
  if [[ -t 0 ]]; then
    read -p "Continue anyway? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      msg_info "Build cancelled"
      exit 0
    fi
  fi
else
  msg_ok "Disk space: ${AVAILABLE_SPACE_GB}GB available"
fi
msg_info ""

# Stop stack and remove project images if we're in a project directory
if [[ -f ".env.orodc" ]] && [[ -n "${DC_ORO_CONFIG_DIR:-}" ]] && [[ -d "${DC_ORO_CONFIG_DIR:-}" ]]; then
  msg_header "Preparing project for rebuild"
  msg_info ""
  
  # Initialize environment to get docker compose command and project name
  initialize_environment 2>/dev/null || true
  
  if [[ -n "${DOCKER_COMPOSE_BIN_CMD:-}" ]] && [[ -n "${DC_ORO_NAME:-}" ]]; then
    # Stop the stack
    msg_info "Stopping project stack..."
    down_cmd="${DOCKER_COMPOSE_BIN_CMD} down --remove-orphans"
    if run_with_spinner "Stopping containers" "$down_cmd"; then
      msg_ok "Stack stopped successfully"
    else
      msg_warning "Some containers may still be running"
    fi
    msg_info ""
    
    # Remove project images
    msg_info "Removing project images..."
    if remove_project_images; then
      msg_ok "Project images removed"
    else
      msg_info "No project images found or removal skipped"
    fi
    msg_info ""
  else
    msg_warning "Could not determine docker compose command or project name, skipping stack stop"
    msg_info ""
  fi
fi

# Define image tags
PHP_BASE_TAG="ghcr.io/digitalspacestdio/orodc-php:${DC_ORO_PHP_VERSION}-${DC_ORO_PHP_DIST}"
PHP_FINAL_TAG="ghcr.io/digitalspacestdio/orodc-php-node-symfony:${DC_ORO_PHP_VERSION}-node${DC_ORO_NODE_VERSION}-composer${DC_ORO_COMPOSER_VERSION}-${DC_ORO_PHP_DIST}"

# Check if Dockerfiles exist
PHP_DOCKERFILE="${DOCKER_DIR}/php/Dockerfile.${DC_ORO_PHP_VERSION}.${DC_ORO_PHP_DIST}"
PHP_NODE_DOCKERFILE="${DOCKER_DIR}/php-node-symfony/${DC_ORO_PHP_VERSION}/Dockerfile"

if [[ ! -f "$PHP_DOCKERFILE" ]]; then
  msg_error "PHP Dockerfile not found: $PHP_DOCKERFILE"
  msg_info ""
  msg_info "Available PHP versions:"
  for dockerfile in "${DOCKER_DIR}"/php/Dockerfile.*."${DC_ORO_PHP_DIST}"; do
    if [[ -f "$dockerfile" ]]; then
      version=$(basename "$dockerfile" | sed "s/Dockerfile\.\(.*\)\.${DC_ORO_PHP_DIST}/\1/")
      msg_info "  - PHP ${version}"
    fi
  done
  msg_info ""
  msg_info "Set DC_ORO_PHP_VERSION in .env.orodc to use a different version"
  exit 1
fi

if [[ ! -f "$PHP_NODE_DOCKERFILE" ]]; then
  msg_error "PHP+Node.js Dockerfile not found: $PHP_NODE_DOCKERFILE"
  msg_info ""
  msg_info "Available PHP+Node.js versions:"
  for dockerfile_dir in "${DOCKER_DIR}"/php-node-symfony/*/; do
    if [[ -d "$dockerfile_dir" ]] && [[ -f "${dockerfile_dir}Dockerfile" ]]; then
      version=$(basename "$dockerfile_dir")
      msg_info "  - PHP ${version}"
    fi
  done
  msg_info ""
  msg_info "Set DC_ORO_PHP_VERSION in .env.orodc to use a different version"
  exit 1
fi

# Stage 1: Build PHP base image
msg_header "Stage 1/2: PHP ${DC_ORO_PHP_VERSION} base image"
msg_info ""

# Check if image exists
if ${DOCKER_BIN} images -q "${PHP_BASE_TAG}" 2>/dev/null | grep -q .; then
  msg_ok "Image exists locally: ${PHP_BASE_TAG}"
  IMAGE_SIZE=$(${DOCKER_BIN} images "${PHP_BASE_TAG}" --format "{{.Size}}")
  msg_info "Image size: ${IMAGE_SIZE}"
else
  msg_info "Image not found locally: ${PHP_BASE_TAG}"
fi

msg_info ""

# Ask user what to do
SHOULD_PULL=false
SHOULD_BUILD=false

if [[ -t 0 ]]; then
  # Ensure terminal is in normal mode (wait for Enter)
  stty echo icanon 2>/dev/null || true
  msg_info "Choose action:"
  msg_info "  1) Pull from registry"
  msg_info "  2) Build locally"
  msg_info "  3) Skip"
  msg_info ""
  read -r -p "Your choice (1/2/3): " REPLY
  
  case $REPLY in
    1) SHOULD_PULL=true ;;
    2) SHOULD_BUILD=true ;;
    3) msg_info "Skipping PHP base image" ;;
    *) msg_warning "Invalid choice, skipping" ;;
  esac
else
  SHOULD_BUILD=true
fi

if [[ "$SHOULD_PULL" == "true" ]]; then
  msg_info "Attempting to pull from registry..."
  if ${DOCKER_BIN} pull "${PHP_BASE_TAG}" 2>/dev/null; then
    msg_ok "Successfully pulled from registry: ${PHP_BASE_TAG}"
    IMAGE_SIZE=$(${DOCKER_BIN} images "${PHP_BASE_TAG}" --format "{{.Size}}")
    msg_info "Image size: ${IMAGE_SIZE}"
  else
    msg_error "Failed to pull from registry"
    msg_info ""
    read -p "Build locally instead? (Y/n): " -r
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
      SHOULD_BUILD=true
    fi
  fi
fi

if [[ "$SHOULD_BUILD" == "true" ]]; then
  BUILD_START=$(date +%s)
  build_cmd="${DOCKER_BIN} build ${NO_CACHE_FLAG} -f \"${PHP_DOCKERFILE}\" -t \"${PHP_BASE_TAG}\" \"${DOCKER_DIR}/php/\""
  if run_with_spinner "Building PHP base image" "$build_cmd"; then
    BUILD_END=$(date +%s)
    BUILD_DURATION=$((BUILD_END - BUILD_START))
    msg_ok "PHP base image built successfully in ${BUILD_DURATION}s"
    
    IMAGE_SIZE=$(${DOCKER_BIN} images "${PHP_BASE_TAG}" --format "{{.Size}}")
    msg_info "Image size: ${IMAGE_SIZE}"
  else
    msg_error "PHP base image build failed"
    msg_info ""
    msg_info "Troubleshooting:"
    msg_info "  - Check Docker daemon is running: docker ps"
    msg_info "  - Check internet connectivity for package downloads"
    msg_info "  - Try rebuilding without cache: orodc image build --no-cache"
    exit 1
  fi
fi

msg_info ""

# Stage 2: Build PHP+Node.js final image
msg_header "Stage 2/2: PHP+Node.js final image"
msg_info ""

# Check if image exists
if ${DOCKER_BIN} images -q "${PHP_FINAL_TAG}" 2>/dev/null | grep -q .; then
  msg_ok "Image exists locally: ${PHP_FINAL_TAG}"
  IMAGE_SIZE=$(${DOCKER_BIN} images "${PHP_FINAL_TAG}" --format "{{.Size}}")
  msg_info "Image size: ${IMAGE_SIZE}"
else
  msg_info "Image not found locally: ${PHP_FINAL_TAG}"
fi

msg_info ""

# Ask user what to do
SHOULD_PULL_FINAL=false
SHOULD_BUILD_FINAL=false

if [[ -t 0 ]]; then
  # Ensure terminal is in normal mode (wait for Enter)
  stty echo icanon 2>/dev/null || true
  msg_info "Choose action:"
  msg_info "  1) Pull from registry"
  msg_info "  2) Build locally"
  msg_info "  3) Skip"
  msg_info ""
  read -r -p "Your choice (1/2/3): " REPLY
  
  case $REPLY in
    1) SHOULD_PULL_FINAL=true ;;
    2) SHOULD_BUILD_FINAL=true ;;
    3) msg_info "Skipping PHP+Node.js final image" ;;
    *) msg_warning "Invalid choice, skipping" ;;
  esac
else
  SHOULD_BUILD_FINAL=true
fi

if [[ "$SHOULD_PULL_FINAL" == "true" ]]; then
  msg_info "Attempting to pull from registry..."
  if ${DOCKER_BIN} pull "${PHP_FINAL_TAG}" 2>/dev/null; then
    msg_ok "Successfully pulled from registry: ${PHP_FINAL_TAG}"
    IMAGE_SIZE=$(${DOCKER_BIN} images "${PHP_FINAL_TAG}" --format "{{.Size}}")
    msg_info "Image size: ${IMAGE_SIZE}"
  else
    msg_error "Failed to pull from registry"
    msg_info ""
    read -p "Build locally instead? (Y/n): " -r
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
      SHOULD_BUILD_FINAL=true
    fi
  fi
fi

if [[ "$SHOULD_BUILD_FINAL" == "true" ]]; then
  BUILD_START=$(date +%s)
  build_cmd="${DOCKER_BIN} build ${NO_CACHE_FLAG} --build-arg PHP_VERSION=\"${DC_ORO_PHP_VERSION}\" --build-arg NODE_VERSION=\"${DC_ORO_NODE_VERSION}\" --build-arg COMPOSER_VERSION=\"${DC_ORO_COMPOSER_VERSION}\" --build-arg PHP_IMAGE=\"${PHP_BASE_TAG}\" -f \"${DOCKER_DIR}/php-node-symfony/${DC_ORO_PHP_VERSION}/Dockerfile\" -t \"${PHP_FINAL_TAG}\" \"${DOCKER_DIR}/php-node-symfony/\""
  if run_with_spinner "Building PHP+Node.js final image" "$build_cmd"; then
    BUILD_END=$(date +%s)
    BUILD_DURATION=$((BUILD_END - BUILD_START))
    msg_ok "PHP+Node.js final image built successfully in ${BUILD_DURATION}s"
    
    IMAGE_SIZE=$(${DOCKER_BIN} images "${PHP_FINAL_TAG}" --format "{{.Size}}")
    msg_info "Image size: ${IMAGE_SIZE}"
  else
    msg_error "PHP+Node.js final image build failed"
    msg_info ""
    msg_info "Troubleshooting:"
    msg_info "  - Check Docker daemon is running: docker ps"
    msg_info "  - Check internet connectivity for package downloads"
    msg_info "  - Try rebuilding without cache: orodc image build --no-cache"
    exit 1
  fi
fi

msg_info ""

# Stage 3: Rebuild project images if in a project directory
# Always rebuild project images at the end if we're in a project directory
# This ensures project images use the latest base images and any changes to Dockerfile.project
if [[ -f ".env.orodc" ]] && [[ -n "${DC_ORO_CONFIG_DIR:-}" ]] && [[ -d "${DC_ORO_CONFIG_DIR:-}" ]]; then
  # Determine if base images were updated (built or pulled)
  BASE_IMAGES_UPDATED=false
  if [[ "${SHOULD_BUILD:-false}" == "true" ]] || [[ "${SHOULD_PULL:-false}" == "true" ]] || [[ "${SHOULD_BUILD_FINAL:-false}" == "true" ]] || [[ "${SHOULD_PULL_FINAL:-false}" == "true" ]]; then
    BASE_IMAGES_UPDATED=true
  fi
  
  msg_header "Stage 3/3: Project images"
  msg_info ""
  
  SHOULD_REBUILD_PROJECT=false
  if [[ "$BASE_IMAGES_UPDATED" == "true" ]]; then
    # Base images were updated, rebuild project images automatically
    msg_info "Base images were updated. Rebuilding project images to use updated base images..."
    SHOULD_REBUILD_PROJECT=true
  elif [[ -t 0 ]]; then
    # Interactive mode: always ask user if they want to rebuild project images
    # Ensure terminal is in normal mode (wait for Enter)
    stty echo icanon 2>/dev/null || true
    msg_info "Project detected. Rebuild project images (fpm, cli, consumer, websocket, ssh)?"
    msg_info "  1) Yes, rebuild project images"
    msg_info "  2) Skip"
    msg_info ""
    read -r -p "Your choice (1/2): " REPLY
    case $REPLY in
      1) SHOULD_REBUILD_PROJECT=true ;;
      2) msg_info "Skipping project images rebuild" ;;
      *) msg_warning "Invalid choice, skipping" ;;
    esac
  else
    # Non-interactive mode: always rebuild project images
    msg_info "Rebuilding project images..."
    SHOULD_REBUILD_PROJECT=true
  fi
  
  if [[ "$SHOULD_REBUILD_PROJECT" == "true" ]]; then
    msg_info ""
    
    # Initialize environment to get docker compose command
    initialize_environment 2>/dev/null || true
    
    # Remove old project images before rebuilding if base images were updated
    if [[ "$BASE_IMAGES_UPDATED" == "true" ]]; then
      msg_info "Removing old project images before rebuild..."
      remove_project_images || true
      msg_info ""
    fi
    
    # Setup certificates for project build
    setup_project_certificates
    
    # Build project images using docker compose
    # Build only services that use Dockerfile.project (fpm, cli, consumer, websocket, ssh)
    if [[ -n "${DOCKER_COMPOSE_BIN_CMD:-}" ]]; then
      BUILD_START=$(date +%s)
      
      # Check which services exist before building
      # Websocket and consumer are only available for Oro projects
      services_to_build="fpm cli ssh"
      
      if ${DOCKER_COMPOSE_BIN_CMD} config --services 2>/dev/null | grep -q "^websocket$"; then
        services_to_build="${services_to_build} websocket"
      fi
      if ${DOCKER_COMPOSE_BIN_CMD} config --services 2>/dev/null | grep -q "^consumer$"; then
        services_to_build="${services_to_build} consumer"
      fi
      
      build_cmd="${DOCKER_COMPOSE_BIN_CMD} build ${NO_CACHE_FLAG} ${services_to_build}"
      if run_with_spinner "Building project images" "$build_cmd"; then
        BUILD_END=$(date +%s)
        BUILD_DURATION=$((BUILD_END - BUILD_START))
        msg_ok "Project images rebuilt successfully in ${BUILD_DURATION}s"
      else
        msg_warning "Project images rebuild completed with warnings (see log above for details)"
        msg_info "You can rebuild project images manually with: orodc compose build"
      fi
    else
      msg_warning "Could not determine docker compose command, skipping project images rebuild"
      msg_info "You can rebuild project images manually with: orodc compose build"
    fi
  fi
  msg_info ""
fi

# Optional: stop current project and remove ONLY its locally built images
# This is useful when project images are built at runtime (e.g. due to per-project certificates).
PROJECT_IMAGES_REMOVED=false
if [[ -t 0 ]]; then
  # Ensure environment is initialized so we have DC_ORO_NAME and DOCKER_COMPOSE_BIN_CMD
  initialize_environment 2>/dev/null || true

  if check_in_project 2>/dev/null; then
    msg_header "Optional cleanup"
    msg_warning "This will stop the current project and remove ONLY its locally built images."
    msg_info "Volumes, databases, and config will NOT be removed."
    msg_info ""

    if confirm_yes_no "Stop project and remove project images now?" "no"; then
      if [[ -n "${DOCKER_COMPOSE_BIN_CMD:-}" ]]; then
        down_cmd="${DOCKER_COMPOSE_BIN_CMD} down --remove-orphans"
        run_with_spinner "Stopping and removing project containers" "$down_cmd" || true
      else
        msg_warning "Could not determine docker compose command; skipping container stop"
      fi

      remove_project_images || true
      PROJECT_IMAGES_REMOVED=true
      msg_info ""
    fi
  fi
fi

msg_header "Build Complete!"
msg_ok "Built images:"
msg_info "  - ${PHP_BASE_TAG}"
msg_info "  - ${PHP_FINAL_TAG}"
if [[ -f ".env.orodc" ]] && [[ -n "${DC_ORO_CONFIG_DIR:-}" ]]; then
  msg_info "  - Project images (fpm, cli, consumer, websocket, ssh)"
fi
if [[ "${PROJECT_IMAGES_REMOVED}" == "true" ]]; then
  msg_info "  - (project images were removed after build; next run will rebuild them)"
fi
msg_info ""
msg_header "Usage"
msg_info "Images are built with full registry path and ready to use."
msg_info "They can be used in FROM statements and pushed to registry."
msg_info ""
