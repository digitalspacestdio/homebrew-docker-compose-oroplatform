# Design: CLI Modular Architecture

## Architecture Overview

The OroDC CLI application follows a modular architecture pattern where the main `bin/orodc` script acts as a command router, delegating execution to specialized modules in `libexec/orodc/`. This design enables maintainability, testability, and clear separation of concerns.

## File Structure

### Main Entry Point
```
bin/
└── orodc                    # Main CLI entry point (router)
```

### Module Structure
```
libexec/orodc/
├── lib/                    # Shared libraries
│   ├── common.sh          # Common utilities (logging, timing, binary resolution)
│   ├── ui.sh              # UI functions (messages, spinners, prompts)
│   ├── environment.sh     # Environment initialization and registry
│   ├── docker-utils.sh    # Docker Compose utilities
│   └── port-manager.sh    # Port management and allocation
│
├── database/              # Database command modules
│   ├── mysql.sh           # MySQL client access
│   ├── psql.sh            # PostgreSQL client access
│   ├── import.sh          # Database import operations
│   ├── export.sh          # Database export operations
│   └── cli.sh             # CLI container access
│
├── tests/                 # Testing command modules
│   ├── install.sh         # Test environment installation
│   ├── run.sh             # Test runner
│   ├── behat.sh           # Behat test execution
│   ├── phpunit.sh         # PHPUnit test execution
│   └── shell.sh           # Test shell access
│
├── proxy/                 # Proxy management modules
│   ├── up.sh              # Start Traefik proxy
│   ├── down.sh            # Stop proxy
│   └── install-certs.sh   # Install CA certificates
│
├── image/                 # Image building modules
│   └── build.sh           # Build Docker images
│
├── compose.sh             # Docker Compose operations
├── init.sh                # Environment initialization
├── purge.sh               # Environment cleanup
├── config-refresh.sh       # Configuration refresh
├── ssh.sh                 # SSH connection to containers
├── install.sh             # Platform installation
├── cache.sh               # Cache management
├── php.sh                 # PHP command execution
├── composer.sh             # Composer command execution
├── platform-update.sh      # Platform update operations
└── menu.sh                 # Interactive menu system
```

## Service Structure

### Docker Compose Services

The Docker Compose configuration follows a modular file loading pattern:

```
compose/
├── docker-compose.yml           # Base configuration (always loaded)
├── docker-compose-default.yml   # Default sync mode (Linux/WSL2)
├── docker-compose-pgsql.yml     # PostgreSQL database service
├── docker-compose-mysql.yml    # MySQL/MariaDB database service
└── docker/                      # Dockerfile definitions
    ├── project-php-node-symfony/  # Application container images
    └── php-node-symfony/          # Base PHP/Node images
```

### Core Services

**Base Services** (defined in `docker-compose.yml`):
- `database` - Database placeholder (busybox)
- `fpm` - PHP-FPM service
- `cli` - CLI container for commands
- `ssh` - SSH server container
- `nginx` - Web server
- `redis` - Cache and session storage
- `search` - Elasticsearch
- `mq` - RabbitMQ message queue
- `mail` - Mailpit mail catcher

**Database Services** (loaded conditionally):
- PostgreSQL: `docker-compose-pgsql.yml` → `database` service with PostgreSQL 15.1
- MySQL: `docker-compose-mysql.yml` → `database` service with MySQL 8.0

**Sync Mode Services** (loaded conditionally):
- Default mode: `docker-compose-default.yml` → volume mounts
- Mutagen mode: Managed by mutagen daemon
- SSH mode: Managed by rsync over SSH

## Command Routing Architecture

### Main Router (`bin/orodc`)

The main script performs the following functions:

1. **Path Resolution**: Resolves script location and sets up library paths
2. **Library Loading**: Sources shared libraries from `libexec/orodc/lib/`
3. **Environment Initialization**: Calls `initialize_environment()` for project detection
4. **Command Routing**: Routes commands to appropriate modules via `exec`

### Routing Patterns

#### Command Groups
Commands are organized into groups with subcommands:

```bash
orodc database mysql      → libexec/orodc/database/mysql.sh
orodc database psql       → libexec/orodc/database/psql.sh
orodc tests phpunit       → libexec/orodc/tests/phpunit.sh
orodc proxy up            → libexec/orodc/proxy/up.sh
orodc image build         → libexec/orodc/image/build.sh
```

#### Single-File Commands
Simple commands route directly to single modules:

```bash
orodc init                → libexec/orodc/init.sh
orodc ssh                 → libexec/orodc/ssh.sh
orodc install             → libexec/orodc/install.sh
```

#### Command Aliases
The router provides convenient aliases:

```bash
orodc start               → orodc compose up -d
orodc stop                → orodc compose stop
orodc mysql               → orodc database mysql
orodc psql                → orodc database psql
```

### Module Execution Pattern

All modules follow a consistent pattern:

```bash
#!/bin/bash
set -e
if [ "$DEBUG" ]; then set -x; fi

# Determine script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/ui.sh"
source "${SCRIPT_DIR}/lib/environment.sh"

# Module-specific logic here
# ...

# Execute command (often with exec for process replacement)
exec "${COMMAND}" "$@"
```

## Library Architecture

### Shared Libraries (`libexec/orodc/lib/`)

#### `common.sh`
- Binary resolution (`resolve_bin`)
- Timing functions (`get_previous_timing`, `save_timing`)
- Environment variable management (`update_env_var`)
- Flag parsing utilities (`parse_compose_flags`)

#### `ui.sh`
- Message functions (`msg_info`, `msg_error`, `msg_warning`, `msg_ok`)
- Spinner display (`show_spinner`, `run_with_spinner`)
- User prompts (`confirm_yes_no`, `prompt_port`)

#### `environment.sh`
- Environment initialization (`initialize_environment`)
- Project detection (`check_in_project`, `find-up`)
- Environment registry (`register_environment`, `list_environments`)
- Status detection (`get_environment_status`)

#### `docker-utils.sh`
- Compose config generation (`generate_compose_config_if_needed`)
- Compose command execution (`exec_compose_command`, `handle_compose_up`)
- Certificate setup (`setup_project_certificates`)
- Service URL display (`show_service_urls`)

#### `port-manager.sh`
- Port allocation (`find_and_export_ports`, `find_single_port`)
- Port conflict detection
- Batch port resolution

## Service Interaction Patterns

### Container Communication

**CLI Container Access:**
- `orodc database cli` → `docker compose run --rm cli`
- Used for PHP commands, Composer, console commands

**SSH Container Access:**
- `orodc ssh` → SSH connection to `ssh` service on port `DC_ORO_PORT_SSH`
- Provides persistent shell access with proper user environment

**Database Access:**
- `orodc database mysql` → Direct MySQL client connection
- `orodc database psql` → Direct PostgreSQL client connection
- Uses auto-configured credentials from environment

### Volume Management

**Application Code:**
- Volume: `{DC_ORO_NAME}_appcode`
- Mounted to: `${DC_ORO_APPDIR:-/var/www}`
- Sync mode determines mount type (bind, volume, mutagen)

**User Home Directories:**
- `home-user`: `/home/{PHP_USER_NAME}`
- `home-root`: `/root`
- Persists user configurations and SSH keys

**SSH Host Keys:**
- Volume: `ssh-hostkeys`
- Mounted to: `/etc/ssh/hostkeys`
- Persists SSH server keys across container restarts

## Module Development Conventions

### Module Structure
1. **Shebang and Error Handling**: Always start with `#!/bin/bash`, `set -e`, debug support
2. **Library Sourcing**: Source required libraries from `lib/`
3. **Environment Check**: Use `check_in_project` for commands requiring project context
4. **Error Messages**: Use `msg_error`, `msg_info` for user feedback
5. **Command Execution**: Use `exec` for process replacement when appropriate

### Naming Conventions
- **Module Files**: Lowercase with hyphens: `database-cli.sh` → `database/cli.sh`
- **Command Groups**: Directory-based: `database/`, `tests/`, `proxy/`
- **Single Commands**: Direct module files: `init.sh`, `ssh.sh`

### Error Handling
- Use `set -e` for automatic error detection
- Provide helpful error messages with `msg_error`
- Include suggestions for resolution
- Use `|| true` only when error is expected and handled

## Integration Points

### Environment Initialization
All modules that require project context depend on `initialize_environment()`:
- Sets up Docker Compose command
- Loads environment variables
- Configures port allocation
- Sets up certificate management

### Compose File Loading
Modules that interact with Docker Compose rely on:
- `generate_compose_config_if_needed()` - Ensures `compose.yml` exists
- `DOCKER_COMPOSE_BIN_CMD` - Pre-configured compose command
- Dynamic file loading based on database schema and sync mode

### Port Management
Services that need ports use:
- `find_and_export_ports()` - Batch port allocation
- `DC_ORO_PORT_*` variables - Exported port numbers
- Port conflict detection via `orodc-find_free_port`

## Future Extension Points

### Adding New Command Groups
1. Create directory: `libexec/orodc/{group}/`
2. Add modules: `{group}/{subcommand}.sh`
3. Update router in `bin/orodc`:
   ```bash
   {group})
     shift
     case "$1" in
       {subcommand})
         exec "${LIBEXEC_DIR}/{group}/{subcommand}.sh" "$@"
   ```

### Adding Single Commands
1. Create module: `libexec/orodc/{command}.sh`
2. Add route in `bin/orodc`:
   ```bash
   {command})
     exec "${LIBEXEC_DIR}/{command}.sh" "$@"
   ```

### Adding New Services
1. Define service in `compose/docker-compose.yml` or profile-specific file
2. Add port allocation in `port-manager.sh` if needed
3. Create access modules if direct access is required
