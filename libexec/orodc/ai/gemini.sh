#!/bin/bash
set -e
if [ "$DEBUG" ]; then set -x; fi

# Determine script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${SCRIPT_DIR}/../lib/ui.sh"
source "${SCRIPT_DIR}/../lib/environment.sh"
source "${SCRIPT_DIR}/../lib/system-prompt.sh"

# Prepare project environment
prepare_project_environment

# Check if Gemini CLI is installed
GEMINI_BIN=$(resolve_bin "gemini" "Gemini CLI is required. Install from: https://github.com/context7/gemini-cli")

# Main execution
main() {
  # Detect CMS type
  local cms_type=$(get_cms_type)
  msg_info "Detected CMS type: $cms_type"
  
  # Get documentation context
  local doc_context=$(get_documentation_context)
  if [[ -f "$doc_context" ]]; then
    msg_info "Using documentation: $doc_context"
  else
    msg_info "Using orodc help output as documentation"
  fi
  
  # Get project name
  local project_name=$(get_project_name)
  
  # Create AGENTS.md file in ~/.orodc/{project_name}/ directory
  local agents_dir="${HOME}/.orodc/${project_name}"
  local agents_file="${agents_dir}/AGENTS.md"
  mkdir -p "$agents_dir"
  
  # Generate system prompt file (AGENTS.md) which references orodc agents commands
  local agents_source_dir="${SCRIPT_DIR}/../agents"
  generate_system_prompt "$cms_type" "$doc_context" "$agents_source_dir" > "$agents_file"
  msg_info "Created system prompt file: $agents_file"
  
  # Track temp files for cleanup (only help output, not AGENTS.md - it should persist)
  local temp_files=()
  if [[ ! -f "$doc_context" ]] || [[ "$doc_context" == /tmp/orodc-help.* ]]; then
    temp_files+=("$doc_context")
  fi
  
  # Cleanup temp files on exit (AGENTS.md is not in temp_files, so it will persist)
  if [[ ${#temp_files[@]} -gt 0 ]]; then
    cleanup_temp_files() {
      rm -f "${temp_files[@]}"
    }
    trap cleanup_temp_files EXIT
  fi
  
  # Execute Gemini CLI with all passed arguments
  # Gemini CLI accepts [query..] as positional arguments for initial prompt
  # System prompt is passed via GEMINI_SYSTEM_MD environment variable pointing to AGENTS.md
  msg_info "Launching Gemini CLI with CMS type: $cms_type"
  
  # Export Docker and project context
  export_environment_context
  
  # Pass system prompt via GEMINI_SYSTEM_MD environment variable
  # Gemini CLI will use this file as the system prompt
  # AGENTS.md file is created in ~/.orodc/{project_name}/AGENTS.md
  export GEMINI_SYSTEM_MD="$agents_file"
  
  # Pass context via environment variables (for reference)
  export GEMINI_SYSTEM_PROMPT="$(cat "$agents_file")"
  export GEMINI_CMS_TYPE="$cms_type"
  export GEMINI_DOC_CONTEXT="$doc_context"
  
  # Build Gemini CLI arguments
  # Gemini CLI uses positional arguments for user prompt
  local gemini_args=()
  
  # EXTREMELY DANGEROUS: Skip all confirmation prompts and execute commands without sandboxing
  # This gives Gemini full system access without any restrictions or safety checks
  # Intended solely for running in environments that are externally sandboxed
  # Use --yolo flag (equivalent to --approval-mode yolo)
  gemini_args+=("--yolo")
  
  # If user provided arguments, pass them as positional prompt arguments
  # System prompt is already set via GEMINI_SYSTEM_MD environment variable
  if [[ $# -gt 0 ]]; then
    # User provided a prompt - pass all arguments as positional prompt
    gemini_args+=("$@")
  fi
  
  # Change to project directory if available (Gemini CLI works in current directory)
  if [[ -n "${DC_ORO_APPDIR:-}" ]] && [[ -d "${DC_ORO_APPDIR}" ]]; then
    cd "${DC_ORO_APPDIR}" || true
  fi
  
  # Execute gemini with arguments
  # System prompt is set via GEMINI_SYSTEM_MD environment variable
  # User prompt (if provided) is passed as positional arguments
  
  # Print command being executed (dark gray text)
  msg_debug "Executing: $GEMINI_BIN ${gemini_args[*]}"
  msg_debug "System prompt file: $agents_file"
  msg_debug "Working directory: $PWD"
  
  exec "$GEMINI_BIN" "${gemini_args[@]}"
}

main "$@"
