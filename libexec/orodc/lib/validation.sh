#!/bin/bash
# Project Validation Library
# Provides validation functions to ensure we're in a valid Oro project

# ============================================================================
# GLOBAL PROJECT VALIDATION
# Validates that we're in a real Oro project with proper configuration
# Runs after initialize_environment but before any command execution
# ============================================================================
validate_project() {
  local command="${1:-}"
  
  # Skip validation for commands that don't require a project
  case "$command" in
    help|man|version|proxy|image|docker-build|init|codex|gemini|cursor|status|"")
      return 0
      ;;
  esac
  
  # Check 1: DC_ORO_APPDIR must be set and not empty
  if [[ -z "${DC_ORO_APPDIR:-}" ]]; then
    msg_error "DC_ORO_APPDIR is not set - not in a project directory"
    msg_info "Please navigate to a project directory or run 'orodc init'"
    exit 1
  fi
  
  # Check 2: DC_ORO_CONFIG_DIR must be set and not empty
  if [[ -z "${DC_ORO_CONFIG_DIR:-}" ]]; then
    msg_error "DC_ORO_CONFIG_DIR is not set - project not initialized"
    msg_info "Please run 'orodc init' to initialize the project"
    exit 1
  fi
  
  # Check 3: DC_ORO_NAME must be set and not empty
  if [[ -z "${DC_ORO_NAME:-}" ]]; then
    msg_error "DC_ORO_NAME is not set - project not initialized"
    msg_info "Please run 'orodc init' to initialize the project"
    exit 1
  fi
  
  # Check 4: DC_ORO_APPDIR must not be HOME or root (prevent dangerous operations)
  if [[ "${DC_ORO_APPDIR}" == "${HOME}" ]]; then
    msg_error "Cannot run orodc commands in home directory"
    msg_info "Please navigate to a project directory"
    exit 1
  fi
  
  if [[ "${DC_ORO_APPDIR}" == "/" ]]; then
    msg_error "Cannot run orodc commands in root directory"
    exit 1
  fi
  
  # Check 5: Must have composer.json OR .env.orodc (local OR global) OR config directory
  # This ensures we're in a real Oro project, not just a random directory
  # If DC_ORO_CONFIG_DIR is set and directory exists, project was initialized via 'orodc init'
  local has_config=false
  
  if [[ -f "${DC_ORO_APPDIR}/composer.json" ]]; then
    has_config=true
    debug_log "validate_project: Found composer.json"
  elif [[ -f "${DC_ORO_APPDIR}/.env.orodc" ]]; then
    has_config=true
    debug_log "validate_project: Found local .env.orodc"
  elif [[ -f "${HOME}/.orodc/${DC_ORO_NAME}/.env.orodc" ]]; then
    has_config=true
    debug_log "validate_project: Found global .env.orodc"
  elif [[ -n "${DC_ORO_CONFIG_DIR:-}" ]] && [[ -d "${DC_ORO_CONFIG_DIR}" ]]; then
    # Config directory exists - project was initialized via 'orodc init'
    # This allows running commands like 'orodc exec composer create-project' after 'orodc init'
    has_config=true
    debug_log "validate_project: Found config directory (project initialized via orodc init)"
  fi
  
  if [[ "$has_config" == "false" ]]; then
    msg_error "Not a valid Oro project"
    msg_info "Project must have one of:"
    msg_info "  - composer.json (Oro project)"
    msg_info "  - .env.orodc (local config)"
    msg_info "  - ~/.orodc/${DC_ORO_NAME}/.env.orodc (global config)"
    msg_info ""
    msg_info "To create a new project:"
    msg_info "  1. Run: orodc init"
    msg_info "  2. Run: orodc up -d"
    msg_info "  3. Then run: orodc exec composer create-project ..."
    exit 1
  fi
  
  debug_log "validate_project: PASSED - DC_ORO_APPDIR=${DC_ORO_APPDIR}, DC_ORO_NAME=${DC_ORO_NAME}"
  return 0
}
