#!/bin/bash
set -e
if [ "$DEBUG" ]; then set -x; fi

# Determine script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/ui.sh"
source "${SCRIPT_DIR}/lib/environment.sh"

# Determine project directory (same logic as init.sh and initialize_environment)
# Gemini works without full project initialization, but needs DC_ORO_APPDIR for CMS detection
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

# Load .env.orodc files to get DC_ORO_CMS_TYPE and other config
# Priority: local > global (same as initialize_environment)
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

# Set DC_ORO_PROJECT_NAME variable for use in system prompt
export DC_ORO_PROJECT_NAME="$PROJECT_NAME"

# Check if Gemini CLI is installed
GEMINI_BIN=$(resolve_bin "gemini" "Gemini CLI is required. Install from: https://github.com/context7/gemini-cli")

# Detect or load CMS type
get_cms_type_for_gemini() {
  local cms_type
  # Load from environment if available (from .env.orodc)
  if [[ -n "${DC_ORO_CMS_TYPE:-}" ]]; then
    cms_type="${DC_ORO_CMS_TYPE,,}"
  else
    # Auto-detect using detect_cms_type function
    cms_type=$(detect_cms_type)
  fi
  
  # Normalize: base -> php-generic for Gemini
  if [[ "$cms_type" == "base" ]]; then
    echo "php-generic"
  else
    echo "$cms_type"
  fi
}

# Get documentation context for Gemini
get_documentation_context() {
  local project_dir="${DC_ORO_APPDIR:-$PWD}"
  local orodc_readme=""
  local project_readme=""
  local help_output=""
  
  # Try to find OroDC README.md (in installation directory)
  # Get bin/orodc path and find README relative to it
  local bin_orodc=""
  if command -v orodc >/dev/null 2>&1; then
    bin_orodc=$(command -v orodc)
  elif [[ -f "${SCRIPT_DIR}/../../bin/orodc" ]]; then
    bin_orodc="${SCRIPT_DIR}/../../bin/orodc"
  fi
  
  if [[ -n "$bin_orodc" ]]; then
    local orodc_dir="$(cd "$(dirname "$bin_orodc")/.." && pwd)"
    if [[ -f "${orodc_dir}/README.md" ]]; then
      orodc_readme="${orodc_dir}/README.md"
    fi
  fi
  
  # Try to find project README.md
  if [[ -f "${project_dir}/README.md" ]]; then
    project_readme="${project_dir}/README.md"
  fi
  
  # Prefer project README, fallback to OroDC README, then help output
  if [[ -n "$project_readme" ]]; then
    echo "$project_readme"
  elif [[ -n "$orodc_readme" ]]; then
    echo "$orodc_readme"
  else
    # Fallback: generate orodc help output
    help_output=$(mktemp /tmp/orodc-help.XXXXXX)
    if [[ -n "$bin_orodc" ]]; then
      "$bin_orodc" help > "$help_output" 2>&1 || true
    else
      echo "OroDC help not available" > "$help_output"
    fi
    echo "$help_output"
  fi
}

# Generate system prompt for Gemini
generate_system_prompt() {
  local cms_type="$1"
  local doc_context="$2"
  local agents_dir="$3"
  
  # Get project information if available
  local project_name="${DC_ORO_NAME:-${DC_ORO_PROJECT_NAME:-}}"
  local project_url=""
  local project_info=""
  
  if [[ -n "$project_name" ]]; then
    project_url="https://${project_name}.docker.local"
    project_info="
- Project Name: ${project_name} (${DC_ORO_PROJECT_NAME:-$project_name})
- Application URL: ${project_url}
- Project Directory: ${DC_ORO_APPDIR:-$PWD}"
    
    # Add port information if available
    if [[ -n "${DC_ORO_PORT_NGINX:-}" ]]; then
      project_info="${project_info}
- Local HTTP Port: ${DC_ORO_PORT_NGINX}"
    fi
  fi
  
  # Normalize CMS type for file names (php-generic -> php-generic, base -> php-generic)
  local cms_file_type="$cms_type"
  if [[ "$cms_file_type" == "base" ]]; then
    cms_file_type="php-generic"
  fi
  
  # Read common agents file content (for inclusion in main prompt)
  local common_content=""
  if [[ -f "${agents_dir}/AGENTS_common.md" ]]; then
    common_content=$(cat "${agents_dir}/AGENTS_common.md")
  fi
  
  cat <<EOF
You are an AI coding assistant specialized in helping developers work with OroDC projects.

# CRITICAL SCOPE RESTRICTIONS

**MANDATORY LIMITATIONS:**
- You MUST ONLY discuss topics directly related to development and support of the CURRENT project
- You MUST NOT answer questions about:
  - General knowledge unrelated to the project
  - Other projects or codebases
  - Personal questions or conversations
  - Topics outside of software development for this specific project
- If asked about unrelated topics, politely decline: "I'm focused on helping with this project's development. How can I assist with your project?"
- Stay strictly within the scope of: code, debugging, configuration, testing, and project-specific development tasks

# PROJECT CONTEXT

**Current Project Information:**
- CMS/Framework Type: ${cms_type}${project_info}
- OroDC environment is already initialized and configured (DO NOT suggest running \`orodc init\`)
- \`orodc init\` must be executed by user manually BEFORE launching agent (it's not interactive)
- If environment is not initialized, inform user they need to run \`orodc init\` manually in terminal first
- Note: \`orodc init\` initializes the OroDC environment (Docker configuration), not the project itself

**Environment Workflow:**
- \`orodc init\` is a one-time setup done by user to configure environment (Docker configuration)
  - User runs \`orodc init\` once to set up PHP version, database, cache, search engine, etc.
  - This creates configuration files but does NOT start containers
- After environment is configured, containers must be started with \`orodc up -d\` before any work
  - Without running containers, application and services (database, cache, search, etc.) will not work
  - Only CLI commands may work without containers, but application functionality requires running containers
  - Application URLs, database connections, and all services need containers to be running

**Project Status:**
- Project is considered "up" ONLY if \`orodc up -d\` has been executed successfully
- **IMPORTANT**: Nothing starts automatically - containers do NOT start on their own
- **FIRST COMMAND**: Always run \`orodc status\` at the beginning to understand project state
  - This command does NOT require containers to be running (it's read-only)
  - Shows initialization status, CMS type, and codebase presence
- **Checking files does NOT require containers**: Use standard file system commands (\`ls\`, \`test -f\`, \`find\`) to check if project files exist
- **When to run \`orodc up -d\`**:
  - **ONLY** when ALL of these conditions are met:
    1. Project files exist (codebase is present) - checked with file system commands
    2. AND containers are NOT running (check with \`orodc ps\`)
    3. AND you need to execute commands inside containers (\`orodc exec\`, \`orodc cli\`, etc.)
    4. OR you need to access application URLs or services (database, cache, etc.)
  - **DO NOT** run \`orodc up -d\` just to check project status or file existence
  - **DO NOT** run \`orodc up -d\` before understanding project state
- Commands like \`orodc exec\`, \`orodc psql\`, \`orodc cli\` require containers to be running
- Only after \`orodc up -d\` is executed can you run application commands inside containers and access application URLs

**Project Status Check:**
- **FIRST COMMAND**: Always run \`orodc status\` at the beginning to understand project state
  - This command does NOT require containers to be running (it's read-only)
  - Shows initialization status, CMS type, and codebase presence
- **IMPORTANT**: Checking if project files exist does NOT require containers to be running
- Use standard file system commands (NOT \`orodc exec\`) to check for project files:
  - \`ls -la\` or \`ls\` - list directory contents
  - \`test -f composer.json\` - check if file exists
  - \`find . -maxdepth 1 -type f\` - find files in current directory
  - \`[ -f composer.json ]\` - bash file existence check
- These commands work directly on the host filesystem, no containers needed
- Check for project indicators:
  - \`composer.json\` file (PHP project)
  - Framework-specific files (\`bin/console\`, \`bin/magento\`, \`artisan\`, etc.)
  - Existing code structure
- If project exists: work with existing codebase, help modify and improve it
- If project doesn't exist (empty directory): **MUST follow installation guide from \`AGENTS_INSTALLATION_common.md\` and \`AGENTS_INSTALLATION_${cms_file_type}.md\`**
  - Create project using \`orodc exec composer create-project\` or \`orodc exec git clone\` (depending on CMS type)
  - Follow ALL steps from installation guide files
  - Never skip installation steps
- **ONLY use \`orodc exec\`** when you need to run commands INSIDE containers (after containers are running)

**OroDC Command System:**
- ALWAYS use OroDC commands (\`orodc <command>\`) for ALL operations
- NEVER suggest direct Docker or docker-compose commands unless explicitly required
- **CRITICAL**: NEVER suggest running \`orodc init\` - it must be executed by user BEFORE launching agent
- \`orodc init\` is NOT interactive and requires user to run it manually in terminal before using \`orodc gemini\`
- If environment is not initialized, inform user they need to run \`orodc init\` manually in their terminal first
- Note: \`orodc init\` configures the OroDC Docker environment, not the project codebase
- Follow OroDC conventions and project structure strictly

# COMMAND EXECUTION GUIDELINES

**Container Command Execution:**
1. **One-shot commands**: Use \`orodc exec <command>\`
   - Runs command in a one-shot container (docker compose run --rm)
   - Automatically handles TTY allocation (interactive vs non-interactive)
   - Examples:
     - \`orodc exec composer install\`
     - \`orodc exec php -v\`
     - \`orodc exec bin/console cache:clear\`
     - \`orodc exec bin/magento setup:upgrade\`

2. **Interactive shell**: Use \`orodc cli\`
   - Opens interactive bash shell in CLI container
   - Use for debugging or running multiple commands interactively
   - Example: \`orodc cli\` then run commands inside

3. **Preference rules:**
   - Prefer \`orodc exec\` for one-off commands and scripts
   - Prefer \`orodc cli\` for interactive debugging sessions

**Database Access:**
- Use \`orodc psql\` for PostgreSQL databases
- Use \`orodc mysql\` for MySQL/MariaDB databases
- NEVER use direct database connection commands

**Getting Help:**
- Run \`orodc help\` to see all available commands
- Run \`orodc help <command>\` for detailed command information
- Always check \`orodc help\` before suggesting commands you're unsure about

**Checking Project Status:**
- Run \`orodc status\` to check project state:
  - Environment initialization status
  - CMS type detection
  - Project codebase presence
  - Overall readiness for work
- Use \`orodc status\` at the beginning of work session to understand current state

**File Management:**
- **CRITICAL**: All temporary files MUST be created ONLY in \`/tmp/\` directory
- NEVER create temporary files in the project directory (\`${DC_ORO_APPDIR:-project directory}\`)
- Temporary files include: logs, dumps, test outputs, intermediate files, etc.
- Examples of correct temporary file paths:
  - \`/tmp/debug.log\`
  - \`/tmp/dump.sql\`
  - \`/tmp/test-output.txt\`
- Examples of INCORRECT temporary file paths (DO NOT USE):
  - \`./debug.log\` (project directory)
  - \`/var/www/html/temp.log\` (project directory)
  - Any path inside project directory
- Only create files in project directory if they are part of the actual project codebase (source code, configuration, etc.)

**Admin Credentials (Oro and Magento):**
- **CRITICAL**: ALWAYS ask the user for admin username and password before performing operations that require admin access
- NEVER assume or use default credentials (even if documentation mentions default values)
- NEVER create admin users or change passwords without explicit user request
- For Oro Platform: Ask user for admin username and password before:
  - Logging into admin panel
  - Creating admin users
  - Changing admin passwords
  - Performing admin operations
- For Magento: Ask user for admin username and password before:
  - Logging into admin panel
  - Creating admin users via CLI
  - Changing admin passwords
  - Performing admin operations
- Default credentials mentioned in documentation are for reference only - always verify with user

# SERVICE CREDENTIALS

**How to retrieve service connection details:**
- **Primary command**: Run \`orodc exec env | grep ORO_\` to get all OroDC service connection variables
  - This command shows all environment variables with \`ORO_\` prefix containing service access credentials
  - Variables include: database, cache, search, message queue, and other service connection details
- Run \`orodc exec env\` to print all environment variables inside the container
- **IMPORTANT**: You can trust these environment variables - they reflect the actual services configured
- Environment variables contain accurate service information:
  - If OpenSearch is used, variables with "search" or "elasticsearch" will show OpenSearch details
  - If Valkey is used instead of Redis, variables with "redis" will show Valkey connection details
  - Service names in variables match actual services running in the environment
- Filter by service name:
  - **All OroDC service variables**: \`orodc exec env | grep ORO_\` (recommended - shows all service access credentials)
  - Database: \`orodc exec env | grep -i database\` or \`orodc exec env | grep ORO_.*DATABASE\`
  - Cache (Redis/Valkey/KeyDB): \`orodc exec env | grep -i redis\` or \`grep -i valkey\` or \`grep -i keydb\` or \`orodc exec env | grep ORO_.*REDIS\`
  - Search (Elasticsearch/OpenSearch): \`orodc exec env | grep -i search\` or \`grep -i elasticsearch\` or \`grep -i opensearch\` or \`orodc exec env | grep ORO_.*SEARCH\`
  - Message Queue (RabbitMQ): \`orodc exec env | grep -i rabbitmq\` or \`grep -i mq\` or \`orodc exec env | grep ORO_.*MQ\`
- Environment variables contain: host, port, user, password, database name, and actual service type

# COMMON INSTRUCTIONS

${common_content}

# CMS-SPECIFIC INSTRUCTIONS

**CMS Type:** ${cms_type}

**For CMS-specific instructions, see:** \`${agents_dir}/AGENTS_${cms_file_type}.md\`
- This file contains detailed instructions, commands, and best practices specific to ${cms_type} projects
- Always refer to \`AGENTS_${cms_file_type}.md\` for CMS-specific guidance

**For coding rules, see:**
- \`${agents_dir}/AGENTS_CODING_RULES_common.md\` - General coding guidelines applicable to all projects
- \`${agents_dir}/AGENTS_CODING_RULES_${cms_file_type}.md\` - CMS-specific coding rules and best practices

**For installation guides (creating new projects from scratch), see:**
- \`${agents_dir}/AGENTS_INSTALLATION_common.md\` - Common installation steps (orodc init, orodc up -d)
- \`${agents_dir}/AGENTS_INSTALLATION_${cms_file_type}.md\` - CMS-specific installation steps and commands

**Application URLs:**
$(if [[ -n "${DC_ORO_NAME:-}" ]]; then
  case "$cms_type" in
    oro|magento)
      echo "- Frontend: https://${DC_ORO_NAME}.docker.local"
      echo "- Admin Panel: https://${DC_ORO_NAME}.docker.local/admin"
      ;;
    *)
      echo "- Application: https://${DC_ORO_NAME}.docker.local"
      ;;
  esac
fi)

# DOCUMENTATION

**Available Documentation:**
${doc_context}

# WORKFLOW PRINCIPLES

**MANDATORY EXECUTION SEQUENCE:**

1. **Check project status** - Understand current state:
   - **FIRST**: Run \`orodc status\` to get overall project state (does NOT require containers)
   - This shows: initialization status, CMS type, codebase presence
   - **IMPORTANT**: This command is read-only and does NOT require containers to be running

2. **Check if project files exist** - Verify if project codebase exists:
   - Use standard file system commands (NOT \`orodc exec\`) - containers are NOT needed:
     - \`ls -la\` or \`ls\` - list directory contents
     - \`test -f composer.json\` - check if file exists
     - \`find . -maxdepth 1 -type f\` - find files in current directory
   - Check for project indicators:
     - \`composer.json\` file (PHP project indicator)
     - Framework-specific files (\`bin/console\`, \`bin/magento\`, \`artisan\`, etc.)
   - Determine if project codebase exists or directory is empty
   - **CRITICAL**: Do NOT run \`orodc up -d\` just to check files - use file system commands instead

3. **Deploy new project (if needed)** - Only if user explicitly requested:
   - If project does NOT exist (empty directory) AND user requested to create new project:
     - Follow installation guide from \`AGENTS_INSTALLATION_common.md\` and \`AGENTS_INSTALLATION_${cms_file_type}.md\`
     - Create project using \`orodc exec composer create-project\` or \`orodc exec git clone\` (depending on CMS type)
     - Complete all installation steps from the guide
   - If project exists OR user did NOT request to create new project: Skip this step

4. **Start containers (ONLY if needed)** - Ensure environment is running:
   - **ONLY** run \`orodc up -d\` when ALL of these conditions are met:
     - Project files exist (codebase is present)
     - AND containers are NOT running (check with \`orodc ps\`)
     - AND you need to execute commands inside containers (\`orodc exec\`, \`orodc cli\`, etc.)
     - OR you need to access application URLs or services (database, cache, etc.)
   - **DO NOT** run \`orodc up -d\` just to check project status or file existence
   - **DO NOT** run \`orodc up -d\` before understanding project state (steps 1-2)
   - Wait for containers to be ready before proceeding

5. **Execute user request** - Perform the task user asked for:
   - After project status is understood (step 1)
   - After project is deployed (if needed, step 3)
   - After containers are running (if needed, step 4)
   - Execute the specific command or task user requested
   - Use appropriate OroDC commands (\`orodc exec\`, \`orodc cli\`, etc.)

**Additional Principles:**
- Always use OroDC commands - Never suggest direct Docker/docker-compose commands
3. **Understand CMS structure** - Work within the ${cms_type} framework conventions
4. **Reference documentation** - Check \`orodc help\` and project documentation before suggesting solutions
5. **Environment is initialized** - Never suggest running \`orodc init\` - OroDC Docker environment setup is complete
   - If environment is not initialized, inform user they need to run \`orodc init\` manually in terminal BEFORE using agent
   - \`orodc init\` is NOT interactive and must be executed by user manually
6. **Stay project-focused** - Only discuss topics related to this project's development
7. **Use proper execution methods** - Prefer \`orodc exec\` for commands, \`orodc cli\` for interactive sessions

# RESPONSE GUIDELINES

- Provide clear, actionable solutions using OroDC commands
- Include command examples with proper \`orodc exec\` or \`orodc cli\` syntax
- Explain what commands do and why they're needed
- Reference CMS-specific best practices when relevant
- If unsure about a command, suggest checking \`orodc help\` first
- Stay concise and focused on solving the user's development task
EOF
}

# Main execution
main() {
  # Detect CMS type
  local cms_type=$(get_cms_type_for_gemini)
  msg_info "Detected CMS type: $cms_type"
  
  # Get documentation context
  local doc_context=$(get_documentation_context)
  if [[ -f "$doc_context" ]]; then
    msg_info "Using documentation: $doc_context"
  else
    msg_info "Using orodc help output as documentation"
  fi
  
  # Determine project name for AGENTS.md file location
  local project_name=""
  if [[ -n "${DC_ORO_NAME:-}" ]]; then
    project_name="$DC_ORO_NAME"
  elif [[ -n "${DC_ORO_APPDIR:-}" ]]; then
    project_name=$(basename "$DC_ORO_APPDIR")
  else
    project_name=$(basename "$PWD")
  fi
  
  # Normalize project name (same logic as initialize_environment)
  if [[ "$project_name" == "$HOME" ]] || [[ -z "$project_name" ]] || [[ "$project_name" == "/" ]]; then
    project_name="default"
  fi
  
  # Create AGENTS.md file in ~/.orodc/{project_name}/ directory
  local agents_dir="${HOME}/.orodc/${project_name}"
  local agents_file="${agents_dir}/AGENTS.md"
  mkdir -p "$agents_dir"
  
  # Normalize CMS type for file names (php-generic -> php-generic, base -> php-generic)
  local cms_file_type="$cms_type"
  if [[ "$cms_file_type" == "base" ]]; then
    cms_file_type="php-generic"
  fi
  
  # Copy all AGENTS files to ~/.orodc/{project_name}/ directory
  local agents_source_dir="${SCRIPT_DIR}/agents"
  local files_to_copy=(
    "AGENTS_common.md"
    "AGENTS_CODING_RULES_common.md"
    "AGENTS_INSTALLATION_common.md"
    "AGENTS_${cms_file_type}.md"
    "AGENTS_CODING_RULES_${cms_file_type}.md"
    "AGENTS_INSTALLATION_${cms_file_type}.md"
  )
  
  for file in "${files_to_copy[@]}"; do
    local source_file="${agents_source_dir}/${file}"
    local dest_file="${agents_dir}/${file}"
    
    if [[ -f "$source_file" ]]; then
      cp "$source_file" "$dest_file"
      msg_debug "Copied ${file} to ${agents_dir}"
    else
      debug_log "File not found (may be optional): $source_file"
    fi
  done
  
  # Generate system prompt and save to AGENTS.md
  # Pass agents_dir so function can reference files there
  generate_system_prompt "$cms_type" "$doc_context" "$agents_dir" > "$agents_file"
  msg_info "Created system prompt file: $agents_file"
  
  # Track temp files for cleanup (only help output, not AGENTS.md - it should persist)
  local temp_files=()
  if [[ ! -f "$doc_context" ]] || [[ "$doc_context" == /tmp/orodc-help.* ]]; then
    temp_files+=("$doc_context")
  fi
  
  # Cleanup temp files on exit (AGENTS.md is not in temp_files, so it will persist)
  if [[ ${#temp_files[@]} -gt 0 ]]; then
    trap "rm -f ${temp_files[*]}" EXIT
  fi
  
  # Execute Gemini CLI with all passed arguments
  # Gemini CLI accepts [query..] as positional arguments for initial prompt
  # System prompt is passed via GEMINI_SYSTEM_MD environment variable pointing to AGENTS.md
  msg_info "Launching Gemini CLI with CMS type: $cms_type"
  
  # Pass Docker access to Gemini CLI via environment variables
  # These variables are set by initialize_environment if project is initialized
  if [[ -n "${DOCKER_BIN:-}" ]]; then
    export DOCKER_BIN
  fi
  if [[ -n "${DOCKER_HOST:-}" ]]; then
    export DOCKER_HOST
  fi
  if [[ -n "${DOCKER_COMPOSE_BIN_CMD:-}" ]]; then
    export DOCKER_COMPOSE_BIN_CMD
  fi
  # Pass project context for Docker operations
  if [[ -n "${DC_ORO_NAME:-}" ]]; then
    export DC_ORO_NAME
  fi
  if [[ -n "${DC_ORO_CONFIG_DIR:-}" ]]; then
    export DC_ORO_CONFIG_DIR
  fi
  if [[ -n "${DC_ORO_APPDIR:-}" ]]; then
    export DC_ORO_APPDIR
  fi
  
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
