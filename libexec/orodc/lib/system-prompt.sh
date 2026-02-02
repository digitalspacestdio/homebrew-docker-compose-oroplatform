#!/bin/bash
# System prompt generation library for AI agents
# This library provides unified functions for generating system prompts for all AI agents

# Detect or load CMS type
# Normalizes: base -> php-generic
get_cms_type() {
  local cms_type
  # Load from environment if available (from .env.orodc)
  if [[ -n "${DC_ORO_CMS_TYPE:-}" ]]; then
    cms_type="$(echo "${DC_ORO_CMS_TYPE}" | tr '[:upper:]' '[:lower:]')"
  else
    # Auto-detect using detect_application_kind function (includes marello)
    cms_type=$(detect_application_kind)
  fi
  
  # Normalize: base -> php-generic
  if [[ "$cms_type" == "base" ]]; then
    echo "php-generic"
  else
    echo "$cms_type"
  fi
}

# Get documentation context
# Returns path to README.md (project or OroDC) or temp file with help output
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
  else
    # Try to find relative to libexec/orodc/lib/system-prompt.sh
    local lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local libexec_dir="$(cd "$lib_dir/.." && pwd)"
    if [[ -f "$libexec_dir/../../bin/orodc" ]]; then
      bin_orodc="$(cd "$libexec_dir/../../bin" && pwd)/orodc"
    fi
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

# Generate system prompt
# Arguments:
#   $1 - CMS type
#   $2 - Documentation context (file path or content)
#   $3 - Agents source directory (path to agents/ folder)
generate_system_prompt() {
  local cms_type="$1"
  local doc_context="$2"
  local agents_source_dir="$3"
  
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
  # Other files are accessed via orodc agents commands, not included directly
  # Read directly from source directory (passed as parameter) - no need to copy files
  local common_content=""
  if [[ -f "${agents_source_dir}/AGENTS_common.md" ]]; then
    common_content=$(cat "${agents_source_dir}/AGENTS_common.md")
  fi
  
  # Generate application URLs based on CMS type
  local application_urls=""
  if [[ -n "${DC_ORO_NAME:-}" ]]; then
    case "$cms_type" in
      oro|magento)
        application_urls="- Frontend: https://${DC_ORO_NAME}.docker.local
- Admin Panel: https://${DC_ORO_NAME}.docker.local/admin"
        ;;
      wintercms)
        application_urls="- Frontend: https://${DC_ORO_NAME}.docker.local
- Admin Panel: https://${DC_ORO_NAME}.docker.local/backend"
        ;;
      *)
        application_urls="- Application: https://${DC_ORO_NAME}.docker.local"
        ;;
    esac
  fi
  
  cat <<EOF
You are an AI coding assistant specialized in helping developers work with OroDC projects.

# ACCESSING DOCUMENTATION

**IMPORTANT:** All project documentation, installation guides, coding rules, and CMS-specific instructions are available via the \`orodc agents\` command.

**To access documentation, use these commands:**
- \`orodc agents installation\` - **For installation:** Complete installation guide (common + CMS-specific steps). Use this when creating new projects or following installation procedures.
- \`orodc agents rules\` - **For coding rules:** Coding rules and best practices (common + CMS-specific). Use this when writing code or reviewing coding standards.
- \`orodc agents ${cms_file_type}\` - **For CMS-specific info:** CMS-specific instructions for ${cms_type} projects. Use this for framework-specific commands and workflows.
- \`orodc agents common\` - **For common info:** Common instructions applicable to all projects.

**Examples:**
- **Installing a new project?** → Run \`orodc agents installation\` first, then follow the steps
- **Need coding guidelines?** → Run \`orodc agents rules\` for complete coding standards
- **CMS-specific commands?** → Run \`orodc agents ${cms_file_type}\` for ${cms_type}-specific instructions

**Always use \`orodc agents\` commands** to access detailed documentation when needed. The system prompt below provides general context, but specific instructions, installation steps, and coding rules should be retrieved using \`orodc agents\` commands.

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
- If project doesn't exist (empty directory): **🔴 MUST follow installation guide**
  - **FIRST: Run \`orodc agents installation\`** to get complete installation guide (common + CMS-specific steps)
  - Read and understand ALL steps BEFORE starting installation
  - Create project using method specified in CMS-specific guide
  - **🚨 UNIVERSAL RULES (Apply to ALL CMS Types):**
    - Demo data → install if user requested
    - Frontend build → complete this step (ALWAYS required for most CMSes)
    - Cache operations → clear/warm cache after installation
  - Never skip installation steps marked as CRITICAL or REQUIRED
- **ONLY use \`orodc exec\`** when you need to run commands INSIDE containers (after containers are running)

**OroDC Command System:**
- ALWAYS use OroDC commands (\`orodc <command>\`) for ALL operations
- NEVER suggest direct Docker or docker-compose commands unless explicitly required
- **CRITICAL**: NEVER suggest running \`orodc init\` - it must be executed by user BEFORE launching agent
- \`orodc init\` is NOT interactive and requires user to run it manually in terminal before using agent
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

**MANDATORY:** To access CMS-specific instructions, **MUST run:** \`orodc agents ${cms_file_type}\`
- This command shows detailed instructions, commands, and best practices specific to ${cms_type} projects
- **Always use this command** when you need CMS-specific guidance
- **Do NOT rely only on this system prompt** - run \`orodc agents ${cms_file_type}\` for complete information

# CODING RULES

**MANDATORY:** To access coding rules, **MUST run:** \`orodc agents rules\`
- This command shows general coding guidelines and CMS-specific coding rules and best practices
- It automatically combines common guidelines and ${cms_type}-specific rules
- **Always use this command** when you need coding guidelines
- Run \`orodc agents rules ${cms_file_type}\` to see only ${cms_type}-specific rules

# INSTALLATION GUIDES

**🔴 CRITICAL: BEFORE creating ANY new project, you MUST read the installation guide!**

**MANDATORY:** To access installation guides, **MUST run:** \`orodc agents installation\`
- This command shows complete installation steps (common + CMS-specific)
- It automatically detects CMS type and shows the appropriate guide
- **Always use this command** when creating new projects or following installation procedures
- Run \`orodc agents installation ${cms_file_type}\` to see installation guide for ${cms_type}

**🚨 UNIVERSAL INSTALLATION RULES (Apply to ALL CMS Types):**

1. **Demo/Sample Data Rule:**
   - If user requests "demo data", "sample data", "test products", "with demo" → YOU MUST install demo data
   - Each CMS has its own method - check CMS-specific guide for exact command
   - **DO NOT skip demo data when user explicitly requests it**

2. **Frontend/Assets Build Rule:**
   - Most CMSes require a frontend build step (CSS, JavaScript, assets compilation)
   - This step is usually **CRITICAL** - frontend will not work without it
   - **DO NOT skip frontend build steps**

3. **Cache Operations Rule:**
   - Always clear and warm up cache after installation
   - Cache operations should be done AFTER installation and frontend build

4. **Step Order Rule:**
   - Follow the **EXACT order** specified in the CMS-specific installation guide
   - Wrong order can cause failures

5. **Never Skip CRITICAL Steps:**
   - Steps marked as CRITICAL, REQUIRED, or 🔴 must **ALWAYS** be executed
   - Skipping them will result in broken functionality

**For ${cms_type} projects:** Run \`orodc agents installation\` for complete step-by-step guide

**Application URLs:**
${application_urls}

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
     - **🔴 FIRST:** Run \`orodc agents installation\` to get complete installation guide - THIS IS MANDATORY
     - Read and understand ALL steps from the guide before starting
     - Follow ALL steps from the guide shown by \`orodc agents installation\`
     - **🚨 UNIVERSAL RULES (Apply to ALL CMS Types):**
       - **Demo data**: If user requests demo data → MUST install it (method varies by CMS)
       - **Frontend build**: MUST complete frontend/assets build step (method varies by CMS)
       - **Cache operations**: Clear/warm cache after installation
       - **Step order**: Follow exact order from installation guide
     - Create project using method specified in CMS-specific guide
     - Complete ALL installation steps exactly as shown in \`orodc agents installation\` output
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

# Prepare project environment for AI agent
# Sets up project directory, loads config, determines project name
prepare_project_environment() {
  # Determine project directory (same logic as init.sh and initialize_environment)
  # AI agents work without full project initialization, but need DC_ORO_APPDIR for CMS detection
  if [[ -z "${DC_ORO_APPDIR:-}" ]]; then
    PROJECT_DIR=$(find-up composer.json)
  fi
  if [[ -z "$PROJECT_DIR" ]]; then
    PROJECT_DIR=$(find-up .env.orodc)
  fi
  
  # If still not found, check for global configuration by project name (directory name)
  # This allows working in a directory that has global config but no local files yet
  if [[ -z "$PROJECT_DIR" ]]; then
    local project_name=$(basename "$PWD")
    if [[ "$project_name" == "$HOME" ]] || [[ -z "$project_name" ]] || [[ "$project_name" == "/" ]]; then
      project_name="default"
    fi
    local global_config_file="${HOME}/.orodc/${project_name}/.env.orodc"
    # Also check for old format global config
    local old_global_config_file="${HOME}/.orodc/${project_name}.env.orodc"
    # Check for config directory (indicates project was initialized before)
    local config_dir="${HOME}/.orodc/${project_name}"
    
    if [[ -f "$global_config_file" ]] || [[ -f "$old_global_config_file" ]]; then
      # Global config exists for this directory name, use current directory as project
      PROJECT_DIR="$PWD"
    elif [[ -d "$config_dir" ]]; then
      # Config directory exists (project was initialized), use current directory as project
      PROJECT_DIR="$PWD"
    else
      # Fallback to current directory if nothing found
      PROJECT_DIR="$PWD"
    fi
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
}

# Get project name for AGENTS.md file location
get_project_name() {
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
  
  echo "$project_name"
}

# Export Docker and project context variables for AI agent
export_environment_context() {
  # Pass Docker access to AI agent via environment variables
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
}
