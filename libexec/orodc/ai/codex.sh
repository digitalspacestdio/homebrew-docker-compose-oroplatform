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

# Check if Codex CLI is installed
CODEX_BIN=$(resolve_bin "codex" "Codex CLI is required. Install from: https://github.com/context7/codex-cli")

# Main execution
main() {
  # Detect CMS type
  local cms_type
  cms_type=$(get_cms_type)
  msg_info "Detected CMS type: $cms_type"
  
  # Get documentation context
  local doc_context
  doc_context=$(get_documentation_context)
  if [[ -f "$doc_context" ]]; then
    msg_info "Using documentation: $doc_context"
  else
    msg_info "Using orodc help output as documentation"
  fi
  
  # Get project name
  local project_name
  project_name=$(get_project_name)
  
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
  
  # Execute Codex CLI with all passed arguments
  # Codex CLI accepts [PROMPT] as optional first argument for initial prompt
  # System prompt is passed via model_instructions_file config pointing to AGENTS.md
  msg_info "Launching Codex CLI with CMS type: $cms_type"
  
  # Export Docker and project context
  export_environment_context
  
  # Pass system prompt and context via environment variables (for reference)
  local codex_system_prompt
  codex_system_prompt="$(cat "$agents_file")"
  export CODEX_SYSTEM_PROMPT="$codex_system_prompt"
  export CODEX_CMS_TYPE="$cms_type"
  export CODEX_DOC_CONTEXT="$doc_context"
  
  # Build Codex CLI arguments
  # Codex CLI uses model_instructions_file for system prompt
  # First argument (if provided) is the user prompt, not a subcommand
  local codex_args=()
  
  # EXTREMELY DANGEROUS: Skip all confirmation prompts and execute commands without sandboxing
  # This gives Codex full system access without any restrictions or safety checks
  # Intended solely for running in environments that are externally sandboxed
  codex_args+=("--dangerously-bypass-approvals-and-sandbox")
  
  # Set working directory to project directory if available
  if [[ -n "${DC_ORO_APPDIR:-}" ]] && [[ -d "${DC_ORO_APPDIR}" ]]; then
    codex_args+=("-C" "${DC_ORO_APPDIR}")
  fi
  
  # Pass system prompt via model_instructions_file config
  # AGENTS.md file is created in ~/.orodc/{project_name}/AGENTS.md
  codex_args+=("-c" "model_instructions_file=\"${agents_file}\"")
  
  # If user provided arguments, pass them as user prompt (first positional argument)
  # System prompt is already set via model_instructions_file
  if [[ $# -gt 0 ]]; then
    # User provided a prompt - pass all arguments as user prompt
    codex_args+=("$@")
  fi
  
  # Execute codex with arguments
  # System prompt is set via model_instructions_file config
  # User prompt (if provided) is passed as first positional argument after flags
  
  # Print command being executed (dark gray text)
  msg_debug "Executing: $CODEX_BIN ${codex_args[*]}"
  
  exec "$CODEX_BIN" "${codex_args[@]}"
}

main "$@"
