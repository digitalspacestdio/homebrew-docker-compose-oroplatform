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

# Function to detect CMS type
get_cms_type() {
  local cms_type=""
  
  # Check explicit override first
  if [[ -n "${DC_ORO_CMS_TYPE:-}" ]]; then
    cms_type="${DC_ORO_CMS_TYPE,,}"
    # Normalize php-generic to base internally
    if [[ "$cms_type" == "php-generic" ]]; then
      cms_type="base"
    fi
  else
    # Try to detect from project
    cms_type=$(detect_cms_type 2>/dev/null || echo "")
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
  
  # Display status
  msg_header "OroDC Project Status"
  echo ""
  
  # Project directory
  echo "Project Directory: ${project_dir}"
  echo "Project Name: ${project_name}"
  echo ""
  
  # Initialization status
  if [[ "$initialized" == "true" ]]; then
    msg_ok "Environment initialized: Yes"
    if [[ -n "${DC_ORO_CONFIG_DIR:-}" ]]; then
      echo "  Config directory: ${DC_ORO_CONFIG_DIR}"
    fi
  else
    msg_warning "Environment initialized: No"
    echo "  Run 'orodc init' to initialize the environment"
  fi
  echo ""
  
  # CMS type
  if [[ "$cms_type" != "unknown" ]]; then
    msg_ok "CMS Type: ${cms_type}"
  else
    msg_warning "CMS Type: Not detected"
    echo "  Set DC_ORO_CMS_TYPE in .env.orodc or ensure composer.json exists"
  fi
  echo ""
  
  # Project codebase
  if [[ "$directory_empty" == "true" ]]; then
    msg_warning "Project codebase: Directory is empty"
    echo "  Project is waiting for code delivery:"
    echo "  - Clone repository: orodc exec git clone <repo-url> ."
    echo "  - Create project: orodc exec composer create-project <package> ."
    echo "  - Follow installation guide: AGENTS_INSTALLATION_${cms_type}.md"
  elif [[ "$project_exists" == "true" ]]; then
    msg_ok "Project codebase: Exists"
    if [[ -f "${project_dir}/composer.json" ]]; then
      echo "  Found: composer.json"
    fi
    if [[ -f "${project_dir}/bin/console" ]]; then
      echo "  Found: bin/console (Symfony/Oro)"
    fi
    if [[ -f "${project_dir}/bin/magento" ]]; then
      echo "  Found: bin/magento (Magento)"
    fi
    if [[ -f "${project_dir}/artisan" ]]; then
      echo "  Found: artisan (Laravel)"
    fi
  else
    msg_warning "Project codebase: Not found"
    echo "  Directory contains files but no project detected"
    echo "  Follow installation guide to create a new project"
  fi
  echo ""
  
  # Summary
  local all_ok=true
  if [[ "$initialized" != "true" ]]; then
    all_ok=false
  fi
  if [[ "$cms_type" == "unknown" ]]; then
    all_ok=false
  fi
  if [[ "$project_exists" != "true" ]]; then
    all_ok=false
  fi
  
  if [[ "$all_ok" == "true" ]]; then
    msg_ok "Status: Ready to work"
  elif [[ "$directory_empty" == "true" ]] && [[ "$initialized" == "true" ]]; then
    msg_info "Status: Environment ready, waiting for project code"
  else
    msg_warning "Status: Configuration incomplete"
  fi
}

main "$@"
