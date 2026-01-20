#!/bin/bash
set -e
if [ "$DEBUG" ]; then set -x; fi

# Determine script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/ui.sh"
source "${SCRIPT_DIR}/lib/environment.sh"

# Determine project directory (same logic as codex.sh)
if [[ -z "${DC_ORO_APPDIR:-}" ]]; then
  PROJECT_DIR=$(find-up composer.json)
fi
if [[ -z "$PROJECT_DIR" ]]; then
  PROJECT_DIR=$(find-up .env.orodc)
fi
if [[ -z "$PROJECT_DIR" ]]; then
  PROJECT_DIR="$PWD"
fi
export DC_ORO_APPDIR="$PROJECT_DIR"

# Determine project name for config lookup
PROJECT_NAME=$(basename "$PROJECT_DIR")
if [[ "$PROJECT_NAME" == "$HOME" ]] || [[ -z "$PROJECT_NAME" ]] || [[ "$PROJECT_NAME" == "/" ]]; then
  PROJECT_NAME="default"
fi

# Load .env.orodc files to get DC_ORO_CMS_TYPE
local_config_file="$PROJECT_DIR/.env.orodc"
global_config_file="${HOME}/.orodc/${PROJECT_NAME}/.env.orodc"

# Load global config first (lower priority)
if [[ -f "$global_config_file" ]]; then
  load_env_safe "$global_config_file"
fi

# Load local config last (higher priority, overrides global)
if [[ -f "$local_config_file" ]]; then
  load_env_safe "$local_config_file"
fi

# Detect or load CMS type
get_cms_type() {
  local cms_type
  # Load from environment if available (from .env.orodc)
  if [[ -n "${DC_ORO_CMS_TYPE:-}" ]]; then
    cms_type="${DC_ORO_CMS_TYPE,,}"
  else
    # Auto-detect using detect_application_kind function (includes marello)
    cms_type=$(detect_application_kind)
  fi
  
  # Normalize: base -> php-generic for file names
  if [[ "$cms_type" == "base" ]]; then
    echo "php-generic"
  else
    echo "$cms_type"
  fi
}

# Get agents directory
get_agents_dir() {
  local agents_source_dir="${SCRIPT_DIR}/agents"
  echo "$agents_source_dir"
}

# Show usage
show_usage() {
  local cms_type=$(get_cms_type)
  local cms_example=""
  local other_cms_example=""
  
  # Use detected CMS type as primary example, or default to "oro"
  if [[ -n "$cms_type" ]] && [[ "$cms_type" != "base" ]]; then
    cms_example="$cms_type"
    # Use different CMS for second example
    if [[ "$cms_type" == "oro" ]]; then
      other_cms_example="magento"
    else
      other_cms_example="oro"
    fi
  else
    cms_example="oro"
    other_cms_example="magento"
  fi
  
  cat <<EOF
Usage: orodc agents <command> [cms-type]

Commands:
  installation [cms-type]  Show installation guide (common + CMS-specific)
  rules [cms-type]         Show coding rules (common + CMS-specific)
  common                   Show common instructions
  <cms-type>               Show CMS-specific instructions (oro, magento, laravel, etc.)

Examples:
  orodc agents installation              # Show installation guide for detected CMS
  orodc agents installation ${cms_example}      # Show installation guide for ${cms_example^}
  orodc agents rules                     # Show coding rules for detected CMS
  orodc agents rules ${other_cms_example}       # Show coding rules for ${other_cms_example^}
  orodc agents common                    # Show common instructions
  orodc agents ${cms_example}                    # Show ${cms_example^}-specific instructions

Available CMS types: oro, magento, laravel, symfony, wintercms, php-generic
EOF
}

# Get file content
get_file_content() {
  local file_path="$1"
  if [[ -f "$file_path" ]]; then
    cat "$file_path"
  else
    msg_error "File not found: $file_path"
    return 1
  fi
}

# Main execution
main() {
  local subcommand="${1:-}"
  
  # Show usage if no subcommand provided
  if [[ -z "$subcommand" ]]; then
    show_usage
    exit 0
  fi
  
  # Handle help
  if [[ "$subcommand" == "help" ]] || [[ "$subcommand" == "--help" ]] || [[ "$subcommand" == "-h" ]]; then
    show_usage
    exit 0
  fi
  
  local agents_dir=$(get_agents_dir)
  local cms_type=$(get_cms_type)
  
  # Handle subcommands
  case "$subcommand" in
    installation)
      local cms_arg="${2:-$cms_type}"
      local cms_file_type="$cms_arg"
      if [[ "$cms_file_type" == "base" ]]; then
        cms_file_type="php-generic"
      fi
      
      local cms_file="${agents_dir}/AGENTS_INSTALLATION_${cms_file_type}.md"
      
      # Check if CMS-specific file exists
      if [[ ! -f "$cms_file" ]]; then
        msg_warning "CMS-specific installation guide not found for: $cms_file_type"
        msg_info "Available installation guides:"
        ls -1 "${agents_dir}"/AGENTS_INSTALLATION_*.md 2>/dev/null | sed 's|.*/AGENTS_INSTALLATION_||;s|\.md$||' | sed 's/^/  - /' || true
        exit 1
      fi
      
      # Check if CMS-specific file references common part
      # If it mentions "common part" or "orodc agents installation" (common), show common first
      local needs_common=false
      if grep -qiE "(common part|orodc agents installation.*common|complete steps.*from.*common)" "$cms_file" 2>/dev/null; then
        needs_common=true
      fi
      
      # Show common installation guide only if CMS file references it
      if [[ "$needs_common" == "true" ]] && [[ -f "${agents_dir}/AGENTS_INSTALLATION_common.md" ]]; then
        get_file_content "${agents_dir}/AGENTS_INSTALLATION_common.md"
        echo ""
        echo "---"
        echo ""
      fi
      
      # Show CMS-specific installation guide
      get_file_content "$cms_file"
      ;;
    
    rules)
      local cms_arg="${2:-$cms_type}"
      local cms_file_type="$cms_arg"
      if [[ "$cms_file_type" == "base" ]]; then
        cms_file_type="php-generic"
      fi
      
      local cms_file="${agents_dir}/AGENTS_CODING_RULES_${cms_file_type}.md"
      
      # Check if CMS-specific file exists
      if [[ ! -f "$cms_file" ]]; then
        msg_warning "CMS-specific coding rules not found for: $cms_file_type"
        msg_info "Available coding rules:"
        ls -1 "${agents_dir}"/AGENTS_CODING_RULES_*.md 2>/dev/null | sed 's|.*/AGENTS_CODING_RULES_||;s|\.md$||' | sed 's/^/  - /' || true
        exit 1
      fi
      
      # Check if CMS-specific file references common part
      # If it mentions "common" or references common rules, show common first
      local needs_common=false
      if grep -qiE "(common|see.*common|orodc agents rules.*common)" "$cms_file" 2>/dev/null; then
        needs_common=true
      fi
      
      # Show common coding rules only if CMS file references it
      if [[ "$needs_common" == "true" ]] && [[ -f "${agents_dir}/AGENTS_CODING_RULES_common.md" ]]; then
        get_file_content "${agents_dir}/AGENTS_CODING_RULES_common.md"
        echo ""
        echo "---"
        echo ""
      fi
      
      # Show CMS-specific coding rules
      get_file_content "$cms_file"
      ;;
    
    common)
      if [[ -f "${agents_dir}/AGENTS_common.md" ]]; then
        get_file_content "${agents_dir}/AGENTS_common.md"
      else
        msg_error "Common instructions file not found: ${agents_dir}/AGENTS_common.md"
        exit 1
      fi
      ;;
    
    # CMS-specific instructions (oro, magento, laravel, etc.)
    oro|magento|laravel|symfony|wintercms|php-generic)
      local cms_file_type="$subcommand"
      if [[ -f "${agents_dir}/AGENTS_${cms_file_type}.md" ]]; then
        get_file_content "${agents_dir}/AGENTS_${cms_file_type}.md"
      else
        msg_error "CMS-specific instructions not found for: $cms_file_type"
        msg_info "Available CMS types:"
        ls -1 "${agents_dir}"/AGENTS_*.md 2>/dev/null | grep -v "CODING_RULES\|INSTALLATION\|common" | sed 's|.*/AGENTS_||;s|\.md$||' | sed 's/^/  - /' || true
        exit 1
      fi
      ;;
    
    *)
      msg_error "Unknown subcommand: $subcommand"
      echo ""
      show_usage
      exit 1
      ;;
  esac
}

main "$@"
