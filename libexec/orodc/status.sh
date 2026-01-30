#!/bin/bash
set -e
if [ "$DEBUG" ]; then set -x; fi

# Determine script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/ui.sh"
source "${SCRIPT_DIR}/lib/environment.sh"

# READ-ONLY MODE: Only read existing config files, do NOT initialize or create anything
# This command should never create files or directories

# Try to detect project directory (read-only, using find-up)
if [[ -z "${DC_ORO_APPDIR:-}" ]]; then
  project_dir=""
  # Use find-up to search for composer.json or .env.orodc
  project_dir=$(find-up composer.json 2>/dev/null || echo "")
  if [[ -z "$project_dir" ]]; then
    project_dir=$(find-up .env.orodc 2>/dev/null || echo "")
  fi
  if [[ -n "$project_dir" ]]; then
    export DC_ORO_APPDIR="$project_dir"
  elif [[ -f "composer.json" ]] || [[ -f ".env.orodc" ]]; then
    export DC_ORO_APPDIR="$PWD"
  fi
fi

# Load config files if they exist (read-only, using load_env_safe which only reads)
if [[ -n "${DC_ORO_APPDIR:-}" ]]; then
  project_name=$(basename "${DC_ORO_APPDIR}")
  if [[ "$project_name" == "$HOME" ]] || [[ -z "$project_name" ]] || [[ "$project_name" == "/" ]]; then
    project_name="default"
  fi
  
  local_config="${DC_ORO_APPDIR}/.env.orodc"
  global_config="${HOME}/.orodc/${project_name}/.env.orodc"
  
  # Load global config first (lower priority) - read-only
  if [[ -f "$global_config" ]]; then
    load_env_safe "$global_config"
  fi
  # Load local config last (higher priority, overrides global) - read-only
  if [[ -f "$local_config" ]]; then
    load_env_safe "$local_config"
  fi
fi

# Function to check if project is initialized
check_initialized() {
  local initialized=false
  
  # Check for DC_ORO_CONFIG_DIR
  if [[ -n "${DC_ORO_CONFIG_DIR:-}" ]] && [[ -d "${DC_ORO_CONFIG_DIR}" ]]; then
    initialized=true
  fi
  
  # Check for .env.orodc files (local or global)
  local project_name=""
  if [[ -n "${DC_ORO_NAME:-}" ]]; then
    project_name="$DC_ORO_NAME"
  elif [[ -n "${DC_ORO_APPDIR:-}" ]]; then
    project_name=$(basename "$DC_ORO_APPDIR")
  else
    project_name=$(basename "$PWD")
  fi
  
  if [[ "$project_name" == "$HOME" ]] || [[ -z "$project_name" ]] || [[ "$project_name" == "/" ]]; then
    project_name="default"
  fi
  
  local local_config="${DC_ORO_APPDIR:-$PWD}/.env.orodc"
  local global_config="${HOME}/.orodc/${project_name}/.env.orodc"
  
  if [[ -f "$local_config" ]] || [[ -f "$global_config" ]]; then
    initialized=true
  fi
  
  echo "$initialized"
}

# Function to detect CMS type (uses detect_application_kind for detailed detection)
get_cms_type() {
  local cms_type=""
  
  # Check explicit override first
  if [[ -n "${DC_ORO_CMS_TYPE:-}" ]]; then
    cms_type="$(echo "${DC_ORO_CMS_TYPE}" | tr '[:upper:]' '[:lower:]')"
    # Normalize php-generic to base internally
    if [[ "$cms_type" == "php-generic" ]]; then
      cms_type="base"
    fi
  else
    # Use detect_application_kind for detailed detection (includes marello)
    cms_type=$(detect_application_kind 2>/dev/null || echo "")
  fi
  
  if [[ -z "$cms_type" ]]; then
    cms_type="unknown"
  fi
  
  # Normalize for display (base -> php-generic)
  if [[ "$cms_type" == "base" ]]; then
    cms_type="php-generic"
  fi
  
  echo "$cms_type"
}

# Function to check if directory is empty
is_directory_empty() {
  local project_dir="${DC_ORO_APPDIR:-$PWD}"
  
  # Check if directory exists and is empty (or contains only .git)
  if [[ ! -d "$project_dir" ]]; then
    echo "true"
    return
  fi
  
  # List files excluding .git
  local files
  files=$(find "$project_dir" -maxdepth 1 -not -name '.' -not -name '.git' -not -path "$project_dir" 2>/dev/null | wc -l)
  
  if [[ "$files" -eq 0 ]]; then
    echo "true"
  else
    echo "false"
  fi
}

# Function to check if project codebase exists
check_project_exists() {
  local project_dir="${DC_ORO_APPDIR:-$PWD}"
  local exists=false
  
  # Check for composer.json
  if [[ -f "${project_dir}/composer.json" ]]; then
    exists=true
  fi
  
  # Check for framework-specific files
  if [[ -f "${project_dir}/bin/console" ]] || \
     [[ -f "${project_dir}/bin/magento" ]] || \
     [[ -f "${project_dir}/artisan" ]] || \
     [[ -f "${project_dir}/public/index.php" ]]; then
    exists=true
  fi
  
  echo "$exists"
}

# Function to get project directory
get_project_dir() {
  local project_dir="${DC_ORO_APPDIR:-$PWD}"
  echo "$project_dir"
}

# Function to get project name
get_project_name() {
  local project_name=""
  if [[ -n "${DC_ORO_NAME:-}" ]]; then
    project_name="$DC_ORO_NAME"
  elif [[ -n "${DC_ORO_APPDIR:-}" ]]; then
    project_name=$(basename "$DC_ORO_APPDIR")
  else
    project_name=$(basename "$PWD")
  fi
  
  if [[ "$project_name" == "$HOME" ]] || [[ -z "$project_name" ]] || [[ "$project_name" == "/" ]]; then
    project_name="default"
  fi
  
  echo "$project_name"
}

# Main function
main() {
  local initialized
  initialized=$(check_initialized)
  local cms_type
  cms_type=$(get_cms_type)
  local project_exists
  project_exists=$(check_project_exists)
  local directory_empty
  directory_empty=$(is_directory_empty)
  local project_dir
  project_dir=$(get_project_dir)
  local project_name
  project_name=$(get_project_name)
  
  # Determine config directory
  local config_dir=""
  if [[ -n "${DC_ORO_CONFIG_DIR:-}" ]] && [[ -d "${DC_ORO_CONFIG_DIR}" ]]; then
    config_dir="${DC_ORO_CONFIG_DIR}"
  else
    # Try to determine from project name
    local config_dir_candidate="${HOME}/.orodc/${project_name}"
    if [[ -d "$config_dir_candidate" ]]; then
      config_dir="$config_dir_candidate"
    fi
  fi
  
  # Get environment status if in a project
  local env_status=""
  local env_status_display=""
  if [[ -n "$project_name" ]] && [[ "$project_name" != "default" ]]; then
    env_status=$(get_environment_status "$project_name" "${project_dir}" 2>/dev/null || echo "uninitialized")
    case "$env_status" in
      running)
        env_status_display="\033[32mrunning\033[0m"
        ;;
      stopped)
        env_status_display="\033[31mstopped\033[0m"
        ;;
      *)
        env_status_display="\033[33muninitialized\033[0m"
        ;;
    esac
  fi
  
  # Display status
  msg_header "OroDC Project Status"
  # Project name first, then Current Environment, then Application Kind
  msg_key_value "Project Name" "${project_name}"
  # Current Environment (if in a project)
  if [[ -n "$project_name" ]] && [[ "$project_name" != "default" ]] && [[ -n "$env_status_display" ]]; then
    echo -e "\033[1;34m==> Current Environment:\033[0m \033[1m${project_name}\033[0m ($env_status_display)"
  fi
  # CMS type (right after project name)
  if [[ "$cms_type" != "unknown" ]]; then
    msg_key_value "Application Kind" "${cms_type}"
  else
    msg_warning "Application Kind: Not detected"
    echo "  Set DC_ORO_CMS_TYPE in .env.orodc or ensure composer.json exists"
  fi
  msg_key_value "Project Directory" "${project_dir}"
  if [[ -n "$config_dir" ]]; then
    msg_key_value "Config Directory" "${config_dir}"
  fi
  # Initialization status
  # Don't show warning if project is detected and ready (has composer.json, CMS type detected)
  local project_ready=false
  if [[ "$project_exists" == "true" ]] && [[ "$cms_type" != "unknown" ]]; then
    project_ready=true
  fi
  
  if [[ "$initialized" == "true" ]]; then
    msg_key_value "Environment initialized" "Yes"
  elif [[ "$project_ready" != "true" ]]; then
    # Only show warning if project is not ready (not detected)
    msg_warning "Environment initialized: No"
    echo "  Run 'orodc init' to initialize the environment"
  fi
  # If project is ready but not initialized, skip this section entirely
  
  # Project codebase
  if [[ "$directory_empty" == "true" ]]; then
    msg_warning "Project codebase: Directory is empty"
    echo "  Project is waiting for code delivery:"
    echo "  - Clone repository: orodc exec git clone <repo-url> ."
    echo "  - Create project: orodc exec composer create-project <package> ."
    echo "  - Follow installation guide: orodc agents installation"
  elif [[ "$project_exists" == "true" ]]; then
    msg_key_value "Project codebase" "Exists"
    
    # Detect CMS type first (to use for all Found messages)
    local detected_type=""
    local oro_type=""
    if is_oro_project; then
      oro_type=$(detect_oro_type)
      if [[ -n "$oro_type" ]]; then
        case "$oro_type" in
          commerce)
            detected_type="Oro Commerce"
            ;;
          crm)
            detected_type="Oro CRM"
            ;;
          platform)
            detected_type="Oro Platform"
            ;;
        esac
      else
        detected_type="Oro"
      fi
    else
      local cms_type=$(detect_cms_type)
      case "$cms_type" in
        symfony)
          detected_type="Symfony"
          ;;
        laravel)
          detected_type="Laravel"
          ;;
        magento)
          detected_type="Magento"
          ;;
      esac
    fi
    
    # Output all Found messages first
    if [[ -f "${project_dir}/composer.json" ]]; then
      echo "  Found: composer.json"
    fi
    if [[ -f "${project_dir}/bin/console" ]]; then
      local console_type="${detected_type:-Symfony}"
      if [[ -n "$oro_type" ]]; then
        case "$oro_type" in
          commerce)
            console_type="Oro Commerce"
            ;;
          crm)
            console_type="Oro CRM"
            ;;
          platform)
            console_type="Oro Platform"
            ;;
          *)
            console_type="Oro"
            ;;
        esac
      elif [[ -z "$detected_type" ]]; then
        console_type="Symfony"
      fi
      echo "  Found: bin/console ($console_type)"
    fi
    if [[ -f "${project_dir}/bin/magento" ]]; then
      echo "  Found: bin/magento (Magento)"
    fi
    if [[ -f "${project_dir}/artisan" ]]; then
      echo "  Found: artisan (Laravel)"
    fi
    
    # Output Detected message after all Found messages
    if [[ -n "$detected_type" ]]; then
      echo "  Detected: $detected_type"
    fi
  else
    msg_warning "Project codebase: Not found"
    echo "  Directory contains files but no project detected"
    echo "  Follow installation guide to create a new project"
  fi
  
  # Summary
  # If project is ready (detected and CMS type known), consider it ready to work
  if [[ "$project_ready" == "true" ]]; then
    msg_key_value "Status" "Ready to work"
  elif [[ "$initialized" == "true" ]] && [[ "$cms_type" != "unknown" ]] && [[ "$project_exists" == "true" ]]; then
    msg_key_value "Status" "Ready to work"
  elif [[ "$directory_empty" == "true" ]] && [[ "$initialized" == "true" ]]; then
    msg_key_value "Status" "Environment ready, waiting for project code"
  elif [[ "$directory_empty" == "true" ]]; then
    msg_key_value "Status" "Waiting for project code"
  elif [[ "$project_exists" != "true" ]]; then
    msg_warning "Status: Project codebase not found"
  elif [[ "$cms_type" == "unknown" ]]; then
    msg_warning "Status: CMS type not detected"
  else
    msg_key_value "Status" "Run 'orodc init' to configure environment"
  fi
}

main "$@"
