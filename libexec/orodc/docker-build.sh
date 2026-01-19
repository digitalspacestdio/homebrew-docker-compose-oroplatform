#!/bin/bash
# docker-build.sh - Non-interactive Docker image builder
# Usage: orodc docker-build <image> [options]
set -e

# Get script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/ui.sh"
source "${SCRIPT_DIR}/lib/common.sh"

# Resolve Docker binary
DOCKER_BIN=$(resolve_bin "docker" "Docker is required. Install from https://docs.docker.com/get-docker/")

# Get Homebrew prefix dynamically
BREW_PREFIX="$(brew --prefix 2>/dev/null || echo "/home/linuxbrew/.linuxbrew")"

# Find compose directory
if [[ -d "${BREW_PREFIX}/Homebrew/Library/Taps/digitalspacestdio/homebrew-docker-compose-oroplatform/compose" ]]; then
  DC_ORO_COMPOSE_DIR="${BREW_PREFIX}/Homebrew/Library/Taps/digitalspacestdio/homebrew-docker-compose-oroplatform/compose"
elif [[ -d "${BREW_PREFIX}/share/docker-compose-oroplatform/compose" ]]; then
  DC_ORO_COMPOSE_DIR="${BREW_PREFIX}/share/docker-compose-oroplatform/compose"
elif [[ -d "$SCRIPT_DIR/../../compose" ]]; then
  DC_ORO_COMPOSE_DIR="$SCRIPT_DIR/../../compose"
else
  msg_error "Could not find OroDC compose directory"
  exit 1
fi

DOCKER_DIR="${DC_ORO_COMPOSE_DIR}/docker"

# Get subcommand
BUILD_TARGET="${1:-}"

# Parse global flags
NO_CACHE_FLAG=""
PUSH_IMAGES=false
PG_VERSION=""

for arg in "${@:2}"; do
  case "$arg" in
    --no-cache) NO_CACHE_FLAG="--no-cache" ;;
    --push) PUSH_IMAGES=true ;;
    --version=*) PG_VERSION="${arg#*=}" ;;
    *)
      # Could be pg version without flag
      if [[ -z "$PG_VERSION" && "$arg" =~ ^[0-9]+\.[0-9]+ ]]; then
        PG_VERSION="$arg"
      fi
      ;;
  esac
done

# Helper function to build single image
build_image() {
  local dockerfile="$1"
  local context="$2"
  local tag="$3"
  local name="$4"
  shift 4
  local build_args=("$@")

  if [[ ! -f "$dockerfile" ]]; then
    msg_error "Dockerfile not found: $dockerfile"
    return 1
  fi

  msg_info "Building ${name}..."
  msg_info "  Tag: ${tag}"

  local build_cmd="${DOCKER_BIN} build ${NO_CACHE_FLAG}"
  for arg in "${build_args[@]}"; do
    build_cmd+=" --build-arg ${arg}"
  done
  build_cmd+=" -f ${dockerfile} -t ${tag} ${context}"

  BUILD_START=$(date +%s)
  if eval "$build_cmd"; then
    BUILD_END=$(date +%s)
    BUILD_DURATION=$((BUILD_END - BUILD_START))
    msg_ok "${name} built in ${BUILD_DURATION}s"

    if [[ "$PUSH_IMAGES" == "true" ]]; then
      msg_info "Pushing ${tag}..."
      if ${DOCKER_BIN} push "${tag}"; then
        msg_ok "Pushed ${tag}"
      else
        msg_warning "Failed to push ${tag}"
      fi
    fi
    return 0
  else
    msg_error "Failed to build ${name}"
    return 1
  fi
}

case "$BUILD_TARGET" in
  list|"")
    msg_header "OroDC Docker Images"
    msg_info ""
    msg_info "Available images to build:"
    msg_info ""
    msg_info "  nginx     - Nginx web server (orodc-nginx:latest)"
    msg_info "  mail      - Mailpit mail catcher (orodc-mail:latest)"
    msg_info "  pgsql     - PostgreSQL database (orodc-pgsql:VERSION)"
    msg_info "              Versions: 15.1, 16.6, 17.4"
    msg_info "  all       - Build all images above"
    msg_info ""
    msg_info "Usage:"
    msg_info "  orodc docker-build <image> [options]"
    msg_info ""
    msg_info "Options:"
    msg_info "  --no-cache    Build without cache"
    msg_info "  --push        Push to GHCR after build"
    msg_info "  --version=X   PostgreSQL version (for pgsql)"
    msg_info ""
    msg_info "Examples:"
    msg_info "  orodc docker-build nginx"
    msg_info "  orodc docker-build pgsql 17.4"
    msg_info "  orodc docker-build pgsql --version=16.6"
    msg_info "  orodc docker-build all --no-cache"
    msg_info "  orodc docker-build mail --push"
    msg_info ""
    msg_info "Note: PHP images use 'orodc image build' (multi-stage interactive)"
    msg_info ""
    exit 0
    ;;

  nginx)
    msg_header "Building Nginx Image"
    build_image \
      "${DOCKER_DIR}/nginx/Dockerfile" \
      "${DOCKER_DIR}/nginx/" \
      "ghcr.io/digitalspacestdio/orodc-nginx:latest" \
      "Nginx"
    exit $?
    ;;

  mail)
    msg_header "Building Mailpit Image"
    build_image \
      "${DOCKER_DIR}/mail/Dockerfile" \
      "${DOCKER_DIR}/mail/" \
      "ghcr.io/digitalspacestdio/orodc-mail:latest" \
      "Mailpit"
    exit $?
    ;;

  pgsql)
    msg_header "Building PostgreSQL Image"

    # Default versions if not specified
    if [[ -z "$PG_VERSION" ]]; then
      PG_VERSIONS=("15.1" "16.6" "17.4")
      msg_info "Building all PostgreSQL versions: ${PG_VERSIONS[*]}"
    else
      PG_VERSIONS=("$PG_VERSION")
    fi

    FAILED=0
    for ver in "${PG_VERSIONS[@]}"; do
      msg_info ""
      build_image \
        "${DOCKER_DIR}/pgsql/Dockerfile" \
        "${DOCKER_DIR}/pgsql/" \
        "ghcr.io/digitalspacestdio/orodc-pgsql:${ver}" \
        "PostgreSQL ${ver}" \
        "PG_VERSION=${ver}" || FAILED=1
    done

    exit $FAILED
    ;;

  all)
    msg_header "Building All OroDC Images"
    msg_info ""

    BUILT=()
    FAILED=()

    # Nginx
    msg_info "=== Nginx ==="
    if build_image \
      "${DOCKER_DIR}/nginx/Dockerfile" \
      "${DOCKER_DIR}/nginx/" \
      "ghcr.io/digitalspacestdio/orodc-nginx:latest" \
      "Nginx"; then
      BUILT+=("nginx")
    else
      FAILED+=("nginx")
    fi

    msg_info ""

    # Mail
    msg_info "=== Mailpit ==="
    if build_image \
      "${DOCKER_DIR}/mail/Dockerfile" \
      "${DOCKER_DIR}/mail/" \
      "ghcr.io/digitalspacestdio/orodc-mail:latest" \
      "Mailpit"; then
      BUILT+=("mail")
    else
      FAILED+=("mail")
    fi

    msg_info ""

    # PostgreSQL (all versions)
    msg_info "=== PostgreSQL ==="
    for ver in 15.1 16.6 17.4; do
      if build_image \
        "${DOCKER_DIR}/pgsql/Dockerfile" \
        "${DOCKER_DIR}/pgsql/" \
        "ghcr.io/digitalspacestdio/orodc-pgsql:${ver}" \
        "PostgreSQL ${ver}" \
        "PG_VERSION=${ver}"; then
        BUILT+=("pgsql:${ver}")
      else
        FAILED+=("pgsql:${ver}")
      fi
    done

    # Summary
    msg_info ""
    msg_header "Build Summary"

    if [[ ${#BUILT[@]} -gt 0 ]]; then
      msg_ok "Built: ${BUILT[*]}"
    fi

    if [[ ${#FAILED[@]} -gt 0 ]]; then
      msg_error "Failed: ${FAILED[*]}"
      exit 1
    fi

    msg_ok "All images built successfully!"
    exit 0
    ;;

  *)
    msg_error "Unknown image type: ${BUILD_TARGET}"
    msg_info ""
    msg_info "Run 'orodc docker-build list' to see available images"
    msg_info ""
    exit 1
    ;;
esac
