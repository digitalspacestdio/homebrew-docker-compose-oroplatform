# Design: Interactive Menu UI for OroDC

## Architecture Overview

The interactive menu system adds a new entry point to `orodc` that activates when no arguments are provided. This design maintains backward compatibility while providing an intuitive interface for common operations.

## Components

### 1. Environment Registry

**Storage Format:**
- Location: `~/.orodc/environments.json` (JSON format for easy parsing)
- Alternative: `~/.orodc/environments.conf` (simple key-value format)
- Structure:
  ```json
  {
    "environments": [
      {
        "name": "myproject",
        "path": "/path/to/myproject",
        "config_dir": "~/.orodc/myproject",
        "last_used": "2024-01-15T10:30:00Z"
      }
    ]
  }
  ```

**Auto-Discovery:**
- Scan `~/.orodc/*` directories
- Each directory with a `compose.yml` or `.env.orodc` is a potential environment
- Extract environment name from directory name or `DC_ORO_NAME` from config

**Status Detection:**
- Use `docker compose ps` with project name to check if containers are running
- Cache status for performance (refresh on menu display)

### 2. Menu Display

**Layout:**
```
OroDC Interactive Menu
======================

Current Environment: myproject (running)
Current Directory: /path/to/myproject

Select an option:
  1) List all environments
  2) Initialize environment and determine versions
  3) Start environment in current folder
  4) Stop environment
  5) Delete environment
  6) Add/Manage domains
  7) Export database
  8) Import database
  9) Configure application URL
  10) Clear cache
  11) Platform update
  12) Connect via SSH
  13) Start proxy
  14) Stop proxy
  15) Run doctor (future)

Enter option [1-15] or 'q' to quit: 
```

**Input Handling:**
- Accept numbers (1-15) or two-digit numbers (10-15)
- Accept 'q' or 'Q' to quit
- Re-prompt on invalid input
- Support arrow keys (optional enhancement)

### 3. Menu Option Handlers

Each option delegates to existing `orodc` functionality:

1. **List Environments**: Scan registry, display table with name, path, status
2. **Init**: Execute `orodc init` (existing command)
3. **Start**: Execute `orodc up -d` in current directory
4. **Stop**: Execute `orodc down` in current directory
5. **Delete**: Execute `orodc purge` with confirmation prompt
6. **Add Domains**: Interactive prompt to modify `DC_ORO_EXTRA_HOSTS`
7. **Export Database**: Export database to `var/` folder with filename prompt
8. **Import Database**: List dumps in `var/` folder, allow selection or file path input
9. **Configure URL**: Interactive prompt for application URL, execute `orodc updateurl <URL>`
10. **Clear Cache**: Execute `orodc cache clear`
11. **Platform Update**: Stop application services, run only CLI container with `oro:platform:update --force`
12. **Connect via SSH**: Execute `orodc ssh` to open interactive SSH session
13. **Start Proxy**: Execute `orodc proxy up -d`
14. **Stop Proxy**: Execute `orodc proxy down`
15. **Run Doctor**: Placeholder (future feature)

### 4. Domain Management

**Interactive Flow:**
1. Display current `DC_ORO_EXTRA_HOSTS` value
2. Prompt: "Add domain (or 'remove' to delete, 'done' to finish):"
3. Validate domain format (trim whitespace, handle short/full hostnames)
4. Update `.env.orodc` file using existing `update_env_file` function
5. Show updated list and confirm

**Domain Format:**
- Short names: `api` → `api.docker.local`
- Full hostnames: `api.example.com` → used as-is
- Multiple: comma-separated list

### 5. Database Export/Import

**Export Database (Option 7):**
1. Check if `var/` directory exists in `$DC_ORO_APPDIR`, create if needed
2. Prompt for filename (default: `database-YYYYMMDDHHMMSS.sql.gz`)
3. Execute `orodc exportdb` with target path `var/<filename>`
4. Display success message with file path and size

**Import Database (Option 8):**
1. Scan `var/` directory for `.sql` and `.sql.gz` files
2. Display numbered list of available dumps
3. Prompt: "Select dump number or enter file path:"
4. If number selected, use corresponding file from `var/`
5. If path entered, validate file exists and is readable
6. Execute `orodc importdb <file>`
7. Display success message

**File Location:**
- Default export location: `$DC_ORO_APPDIR/var/`
- Supports both `.sql` and `.sql.gz` formats
- Auto-create `var/` directory if missing

### 6. URL Configuration

**Interactive Flow:**
1. Display current application URL (from `oro:config:get` or default)
2. Prompt: "Enter new application URL [default: https://${DC_ORO_NAME}.docker.local]:"
3. Validate URL format (must start with `http://` or `https://`)
4. Execute `orodc updateurl <URL>`
5. Display success message with updated URL

**URL Update Commands:**
- Updates `oro_website.secure_url`
- Updates `oro_ui.application_url`
- Updates `oro_website.url`

### 7. Cache Management

**Clear Cache (Option 10):**
1. Execute `orodc cache clear`
2. Display success message: "Cache cleared successfully"
3. Return to menu

### 8. Platform Update

**Platform Update (Option 11):**
1. Stop all application services (FPM, Nginx, etc.) but keep dependencies running (database, Redis, etc.)
2. Execute `docker compose run --rm cli php bin/console oro:platform:update --force`
3. This runs only the CLI container without starting full application stack
4. Display progress during update
5. After completion, optionally prompt: "Platform update completed. Restart services? [Y/n]"
6. If user confirms, restart services with `orodc up -d`
7. Return to menu

**Platform Update Details:**
- Stops: FPM, Nginx, WebSocket, Consumer services
- Keeps running: Database, Redis, Elasticsearch, RabbitMQ (if needed by CLI)
- Uses `docker compose run` (not `exec`) to start only CLI container
- Clears cache before update: `rm -rf var/cache/*`
- Runs: `php bin/console oro:platform:update --force`

### 9. SSH Connection

**Connect via SSH (Option 12):**
1. Check if SSH service is running
2. If not running, display error: "SSH service is not running. Start environment first."
3. If running, execute `orodc ssh` command
4. This opens an interactive SSH session to the container
5. When SSH session ends, return to menu

**SSH Connection Details:**
- Uses SSH key from `${DC_ORO_CONFIG_DIR}/ssh_id_ed25519`
- Connects to `127.0.0.1:${SSH_PORT}` (port determined dynamically)
- User: `${DC_ORO_USER_NAME}` (default: `app`)
- Full interactive shell session

### 5. Non-Interactive Mode Detection

**Skip Menu When:**
- `$# -gt 0` (arguments provided)
- Not a TTY (`[[ ! -t 0 ]]`)
- `DC_ORO_NO_MENU=1` environment variable set
- Piped input detected

**Implementation:**
```bash
# Early in script, after argument parsing
if [[ $# -eq 0 ]] && [[ -t 0 ]] && [[ -z "${DC_ORO_NO_MENU:-}" ]]; then
  show_interactive_menu
  exit $?
fi
```

## Integration Points

### Existing Functions to Reuse
- `update_env_file()`: Update `.env.orodc` (from `bin/orodc`)
- `msg_info()`, `msg_ok()`, `msg_error()`: Message formatting
- `run_with_spinner()`: For long-running operations
- Docker Compose command building: Existing `DOCKER_COMPOSE_BIN_CMD` logic

### New Functions Needed
- `show_interactive_menu()`: Main menu display and input handler
- `get_environment_registry()`: Read environment registry
- `register_environment()`: Add/update environment in registry
- `get_environment_status()`: Check if environment is running
- `list_environments()`: Display all environments
- `manage_domains()`: Interactive domain management

## Trade-offs

### JSON vs Simple Config
- **JSON**: Easier to parse, structured data, but requires `jq` dependency
- **Simple Config**: No dependencies, but manual parsing needed
- **Decision**: Use JSON with `jq` (already a dependency per project.md)

### Menu Library vs Custom Implementation
- **Library (e.g., `dialog`, `whiptail`)**: Rich UI, but external dependency
- **Custom**: No dependencies, full control, but more code
- **Decision**: Custom implementation for portability and consistency

### Auto-Registration vs Manual
- **Auto**: Scan `~/.orodc/*` on every menu display
- **Manual**: User explicitly registers environments
- **Decision**: Hybrid - auto-discover on first use, allow manual registration

## Backward Compatibility

- All existing `orodc` commands continue to work unchanged
- Menu only activates when no arguments provided
- Non-interactive usage (scripts, CI/CD) unaffected
- Environment variable `DC_ORO_NO_MENU=1` allows explicit opt-out

## Future Enhancements

- Arrow key navigation (requires terminal control sequences)
- Environment switching (change directory and activate)
- Quick actions (shortcuts for common workflows)
- Menu themes/configurable appearance
- Doctor command implementation (health checks, diagnostics)

