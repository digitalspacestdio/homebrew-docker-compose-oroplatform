# Project Context

## Purpose

**OroDC (Oro Docker Compose)** is a modern CLI tool that provides a complete Docker-based development environment for ORO Platform applications (OroPlatform, OroCRM, OroCommerce, MarelloCommerce). The project's goals are:

- **Zero Configuration**: Work out of the box with sensible defaults
- **Developer Experience**: Smart PHP command detection, direct database access, beautiful CLI output
- **Performance**: Optimized sync modes (native, Mutagen, SSH) for different platforms
- **Production-Like**: Same containerized environment across dev, staging, and production
- **Minimal Dependencies**: No application code changes required
- **Enterprise-Grade**: Support for multisite, WebSockets, testing, profiling, and more

The tool is distributed as a Homebrew formula and manages multi-container Docker environments with services like PostgreSQL, Redis, Elasticsearch, RabbitMQ, Nginx, and PHP-FPM.

## Tech Stack

### Core Technologies
- **Shell**: Bash/Zsh (primary CLI implementation)
- **Container Orchestration**: Docker Compose
- **Package Management**: Homebrew (macOS, Linux, WSL2)
- **File Sync**: Mutagen (macOS), Rsync (SSH mode), Native Docker volumes (Linux)

### Docker Images

#### Custom Built Images (via GitHub Actions)
- **PHP Base**: `ghcr.io/digitalspacestdio/orodc-php-node-symfony`
  - PHP versions: 7.4, 8.1, 8.2, 8.3, 8.4, 8.5
  - Node.js versions: 18, 20, 22
  - Composer versions: 1, 2
  - Base distro: Alpine Linux
- **PostgreSQL**: `ghcr.io/digitalspacestdio/orodc-pgsql:15.1`
  - Based on official `postgres:15.1`
  - Includes pgpool2 and pg_repack extensions
  - Performance-optimized settings

#### Official Images
- **MySQL**: `mysql:8.0-oracle`
- **Cache**: `redis:6.2`, `redis:7.0`
- **Search**: `elasticsearch:8.10.3`
- **Queue**: `oroinc/rabbitmq:3.9-1-management-alpine`
- **Web Server**: `nginx:latest`
- **Mail**: `cd2team/mailhog` (testing)
- **Profiling**: `xhgui/xhgui` + `mongo:4.4`

**Build Strategy**: All custom images are built in GitHub Actions and published to GitHub Container Registry. No local builds required.

### Infrastructure
- **Reverse Proxy**: Traefik 2.x (host + Docker modes)
- **DNS**: Dnsmasq (local .docker.local domain resolution)
- **SSL/TLS**: Self-signed certificates via digitalspace-local-ca

### CI/CD
- **GitHub Actions**: Multi-architecture (X64, ARM64) containerized testing
- **Testing Tools**: Goss (infrastructure validation), PHPUnit, Behat
- **Quality Tools**: Hadolint (Dockerfile), yamllint, ShellCheck, actionlint

### Dependencies
- **Required**: coreutils, jq, yq, rsync
- **Optional**: mutagen (macOS performance)

## Project Conventions

### Code Style

#### Shell Scripts (Bash/Zsh)
- **Strict Mode**: Always use `set -e` for error handling
- **Zsh Compatibility**: All commands must work in both bash and zsh
- **Debug Support**: Check `[[ -n "${DEBUG:-}" ]]` for verbose output
- **No Emojis**: Use plain ASCII for maximum compatibility (e.g., `[OK]`, `[ERROR]`, `[INFO]`)
- **Quote Safety**: Always quote variable expansions: `"${VAR}"` not `$VAR`
- **Path Handling**: Support both relative and absolute paths

#### Naming Conventions
- **Environment Variables**: `DC_ORO_*` prefix (e.g., `DC_ORO_PHP_VERSION`, `DC_ORO_MODE`)
- **Container Names**: `${DC_ORO_NAME}_servicename_version` format
- **Hostnames**: `service.${DC_ORO_NAME}.docker.local`
- **Branch Names**: Verb-led kebab-case (`fix/`, `feature/`, `update/`, `refactor/`)
- **Docker Volumes**: Prefixed with project name (e.g., `appcode`, `home-user`)

#### File Organization
```
/
├── bin/                    # CLI executables (orodc, orodc-sync, orodc-find_free_port)
├── compose/                # Docker Compose configurations
│   ├── docker-compose.yml  # Main services definition
│   ├── docker/             # Dockerfiles for custom images
│   └── *.yml              # Profile-specific overrides
├── Formula/                # Homebrew formula definition
├── docs/                   # Documentation and assets
├── openspec/              # Change proposals and specifications
├── libexec/orodc/         # CLI command modules (modular architecture)
│   ├── lib/              # Shared libraries
│   ├── database/        # Database command modules
│   ├── tests/           # Testing command modules
│   ├── proxy/           # Proxy management modules
│   ├── image/           # Image building modules
│   └── *.sh             # Single-file command modules
└── .github/workflows/     # CI/CD pipeline definitions
```

### Architecture Patterns

#### CLI Modular Architecture

OroDC follows a modular architecture pattern where the main `bin/orodc` script acts as a lightweight command router, delegating execution to specialized modules in `libexec/orodc/`. This design enables maintainability, testability, and clear separation of concerns.

**Main Entry Point:**
- `bin/orodc` - Main CLI router (handles version, help, environment initialization, and command routing)

**Module Structure:**

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
│   ├── cli.sh             # CLI container access
│   ├── purge.sh           # Database purge operations
│   └── recreate.sh        # Database recreation
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
├── composer.sh            # Composer command execution
├── platform-update.sh      # Platform update operations
├── doctor.sh              # Health check and diagnostics
├── exec.sh                # Container execution
├── conf.sh                # Configuration management
├── list.sh                # List environments
└── menu.sh                # Interactive menu system
```

**Command Routing Patterns:**

1. **Command Groups** - Commands organized into groups with subcommands:
   ```bash
   orodc database mysql      → libexec/orodc/database/mysql.sh
   orodc database psql       → libexec/orodc/database/psql.sh
   orodc tests phpunit       → libexec/orodc/tests/phpunit.sh
   orodc proxy up            → libexec/orodc/proxy/up.sh
   orodc image build         → libexec/orodc/image/build.sh
   ```

2. **Single-File Commands** - Simple commands route directly to single modules:
   ```bash
   orodc init                → libexec/orodc/init.sh
   orodc ssh                 → libexec/orodc/ssh.sh
   orodc install             → libexec/orodc/install.sh
   ```

3. **Command Aliases** - Convenient aliases for common operations:
   ```bash
   orodc start               → orodc compose up -d
   orodc stop                → orodc compose stop
   orodc mysql               → orodc database mysql
   orodc psql                → orodc database psql
   ```

**Module Execution Pattern:**

All modules follow a consistent pattern:

```bash
#!/bin/bash
set -e
if [ "$DEBUG" ]; then set -x; fi

# Determine script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${SCRIPT_DIR}/../lib/ui.sh"
source "${SCRIPT_DIR}/../lib/environment.sh"

# Module-specific logic here
# ...

# Execute command (often with exec for process replacement)
exec "${COMMAND}" "$@"
```

**Library Architecture:**

- **`common.sh`**: Binary resolution, timing functions, environment variable management, flag parsing utilities
- **`ui.sh`**: Message functions (msg_info, msg_error, msg_warning, msg_ok), spinner display, user prompts
- **`environment.sh`**: Environment initialization, project detection, environment registry, status detection
- **`docker-utils.sh`**: Compose config generation, compose command execution, certificate setup, service URL display
- **`port-manager.sh`**: Port allocation, port conflict detection, batch port resolution

**Benefits:**
- **Maintainability**: Each command is isolated and easy to modify
- **Testability**: Modules can be tested independently
- **Extensibility**: New commands can be added without modifying the main router
- **Separation of Concerns**: Clear boundaries between routing, initialization, and command logic

**Implementation Reference:**
- Main router: `bin/orodc` (command routing logic)
- Module examples: `libexec/orodc/database/mysql.sh`, `libexec/orodc/tests/phpunit.sh`
- Shared libraries: `libexec/orodc/lib/*.sh`
- Architecture specification: `openspec/specs/cli-architecture/spec.md`

#### UI/UX: Spinner Mechanism for Long-Running Commands

OroDC uses a consistent spinner mechanism for all long-running operations to provide visual feedback and clean output.

**Core Function: `run_with_spinner`**

All long-running commands MUST use `run_with_spinner` from `libexec/orodc/lib/ui.sh`:

```bash
# Standard usage (like in start containers)
run_with_spinner "Operation message" "$command" || exit $?

# For non-critical operations (errors as warnings)
if ! run_with_spinner "Operation message" "$command"; then
  msg_warning "Operation completed with warnings (see log above for details)"
fi
```

**Key Features:**

1. **Automatic Spinner Display:**
   - Shows animated spinner (`|/-\`) during command execution
   - Writes spinner animation to stderr (doesn't interfere with command output)
   - Automatically hides when `DEBUG=1` or `VERBOSE=1` is set

2. **Output Redirection:**
   - Command stdout/stderr redirected to temporary log file (`/tmp/orodc-output.XXXXXX`)
   - Spinner animation displayed on stderr separately
   - Keeps terminal output clean and readable

3. **Error Handling:**
   - On success: Log file is removed, success message displayed
   - On failure: Log file preserved, error message shown with log location
   - Last 20 lines of log displayed automatically (full log available at path)

4. **Consistent Usage Pattern:**
   - **Critical operations**: `run_with_spinner "Message" "$cmd" || exit $?`
   - **Non-critical operations**: Check exit code, show warning instead of error
   - **Always use**: Same pattern as `docker-utils.sh` for "Starting services"

**Implementation Reference:**
- Core function: `libexec/orodc/lib/ui.sh` (`run_with_spinner` function, lines 123-190)
- Example usage: `libexec/orodc/lib/docker-utils.sh` (start containers, line 144)
- Example with warnings: `libexec/orodc/cache.sh` (cache clear, lines 26-30)

**Rules:**
- ✅ ALWAYS use `run_with_spinner` for long-running operations
- ✅ NEVER redirect stderr when using `run_with_spinner` (breaks spinner display)
- ✅ Use same pattern as start containers everywhere
- ❌ NEVER use `show_spinner` directly (use `run_with_spinner` wrapper)
- ❌ NEVER capture stderr from `run_with_spinner` (spinner writes to stderr)

#### Smart Command Detection
OroDC automatically detects PHP commands and redirects them to the CLI container:
- PHP flags (`-v`, `--version`, `-r`, `-l`, `-m`, `-i`) → `cli php [command]`
- `.php` files → `cli php [file]`
- `bin/console`, `bin/phpunit` → `cli [command]`

#### Database Access Abstraction
Direct database commands with auto-configured credentials:
- `orodc psql` → PostgreSQL with connection details
- `orodc mysql` → MySQL with connection details

#### Multi-Mode Sync
Environment-specific file synchronization:
- **default**: Native Docker volumes (Linux/WSL2 - fastest)
- **mutagen**: Two-way sync daemon (macOS - avoids slow Docker FS)
- **ssh**: Remote sync via SSH (remote Docker, special cases)

#### Profile-Based Architecture
Docker Compose profiles for different workloads:
- **Default**: FPM, CLI, Nginx, Database, Redis, Elasticsearch
- **consumer**: Message queue workers
- **websocket**: WebSocket server
- **php-cli**: Standalone PHP CLI
- **database-cli**: Database management tools

#### Dynamic Compose File Loading
OroDC dynamically assembles the Docker Compose command by conditionally including configuration files based on application state. This allows zero-configuration database selection and environment-specific customizations.

**Loading Order and Priority:**

1. **Base Configuration** (`docker-compose.yml`):
   - Always loaded first
   - Contains all core services with dummy database (busybox placeholder)
   - Provides service definitions for FPM, CLI, Nginx, Redis, Elasticsearch, RabbitMQ, Mail

2. **Sync Mode Configuration** (`docker-compose-default.yml`):
   - Loaded when `DC_ORO_MODE=default`
   - Adds volume mount configuration for native Docker volumes (Linux/WSL2)
   - Skipped for mutagen/ssh modes which handle syncing separately

3. **Database-Specific Configuration**:
   - **PostgreSQL** (`docker-compose-pgsql.yml`):
     - Loaded when `DC_ORO_DATABASE_SCHEMA` matches: `pgsql`, `postgres`, `postgresql`
     - Uses pre-built image: `ghcr.io/digitalspacestdio/orodc-pgsql:15.1`
     - Custom image includes pgpool2 and pg_repack extensions
     - Sets `DC_ORO_DATABASE_PORT=5432`
   - **MySQL/MariaDB** (`docker-compose-mysql.yml`):
     - Loaded when `DC_ORO_DATABASE_SCHEMA` matches: `mysql`, `mariadb`
     - Uses official image: `mysql:8.0-oracle`
     - Sets `DC_ORO_DATABASE_PORT=3306`

4. **User Custom Configuration** (`.docker-compose.user.yml`):
   - Loaded last if exists in project root (`$DC_ORO_APPDIR`)
   - Allows project-specific overrides and custom services
   - Has highest priority due to Docker Compose merge order

**Schema Detection Mechanism:**

```bash
# 1. Parse ORO_DB_URL environment variable (from .env-app or .env-app.local)
parse_dsn_uri "$ORO_DB_URL" "database" "DC_ORO"

# 2. Extract schema (postgres, mysql, etc.) into DC_ORO_DATABASE_SCHEMA
# Example: postgres://user:pass@host:5432/db → DC_ORO_DATABASE_SCHEMA=postgres

# 3. Include appropriate compose file
if [[ "${DC_ORO_DATABASE_SCHEMA}" == "pgsql" ]] || [[ "${DC_ORO_DATABASE_SCHEMA}" == "postgres" ]] || [[ "${DC_ORO_DATABASE_SCHEMA}" == "postgresql" ]]; then
  DOCKER_COMPOSE_BIN_CMD="${DOCKER_COMPOSE_BIN_CMD} -f ${DC_ORO_CONFIG_DIR}/docker-compose-pgsql.yml"
elif [[ "${DC_ORO_DATABASE_SCHEMA}" == "mariadb" ]] || [[ "${DC_ORO_DATABASE_SCHEMA}" == "mysql" ]]; then
  DOCKER_COMPOSE_BIN_CMD="${DOCKER_COMPOSE_BIN_CMD} -f ${DC_ORO_CONFIG_DIR}/docker-compose-mysql.yml"
fi
```

**Busybox Cleanup:**

After loading database-specific compose files, OroDC automatically removes any running dummy database containers:

```bash
# Detect busybox database container
SERVICE_DATABASE_ID=$(${DOCKER_COMPOSE_BIN_CMD} ps -q database)
if [[ -n "$SERVICE_DATABASE_ID" ]] && docker inspect -f '{{ .Config.Image }}' "$SERVICE_DATABASE_ID" | grep -q 'busybox'; then
  # Stop and remove dummy container
  ${DOCKER_COMPOSE_BIN_CMD} stop database
  ${DOCKER_COMPOSE_BIN_CMD} rm -f database
fi
```

**Final Command Example:**

```bash
# With PostgreSQL application:
docker compose -f docker-compose.yml \
               -f docker-compose-default.yml \
               -f docker-compose-pgsql.yml \
               -f .docker-compose.user.yml \
               up -d

# With MySQL application:
docker compose -f docker-compose.yml \
               -f docker-compose-default.yml \
               -f docker-compose-mysql.yml \
               up -d
```

**Debugging Dynamic Loading:**

Use `DEBUG=1` to see the complete compose file loading sequence:

```bash
DEBUG=1 orodc up -d 2>&1 | grep -E "DATABASE_SCHEMA|docker-compose.*yml"
```

This shows:
1. Schema detection: `export DC_ORO_DATABASE_SCHEMA=postgres`
2. Base file loading: `-f docker-compose.yml`
3. Mode file addition: `-f docker-compose-default.yml`
4. Database file addition: `-f docker-compose-pgsql.yml`
5. Final command execution

**Common Issues:**

- **Database container not starting**: Check `ORO_DB_URL` is set correctly in `.env-app.local`
- **Busybox database persists**: `DC_ORO_DATABASE_SCHEMA` not detected - verify DSN parsing with `DEBUG=1`
- **Wrong database type**: Schema detection case-sensitive - use lowercase values in `ORO_DB_URL`
- **Container keeps stopping**: Normal behavior during busybox → real database transition

**Implementation Reference:**
- Database detection: `bin/orodc:1151` (parse_dsn_uri call)
- Compose file inclusion: `bin/orodc:1259-1269`
- Busybox cleanup: `bin/orodc:1270-1276`

#### Multi-Stage Configuration
Configuration hierarchy (lowest to highest priority):
1. Hardcoded defaults in `bin/orodc`
2. Global `.env.orodc` in project root
3. Profile-specific `.env.orodc.{profile}` files
4. Environment variables at runtime

### Testing Strategy

#### Test Environment Isolation
- **CRITICAL**: Tests run in completely separate containers from main application
- **REQUIRED**: `orodc tests install` before any test execution
- **MANDATORY**: Use `orodc tests` prefix for all test commands

#### Testing Layers

1. **Unit Tests**: PHPUnit with `--testsuite=unit`
2. **Functional Tests**: PHPUnit with `--testsuite=functional`
3. **Behavior Tests**: Behat with suite-specific execution
4. **Infrastructure Tests**: Goss for container/service validation
5. **CI/CD Tests**: Multi-architecture GitHub Actions runners

#### Quality Gates
- **Dockerfile Linting**: Hadolint validation before Docker builds
- **YAML Validation**: yamllint for all workflow files
- **Shell Script Validation**: ShellCheck for bash/zsh scripts
- **GitHub Actions Validation**: actionlint for workflow syntax

#### CI/CD Pipeline
- **Multi-Architecture**: X64 and ARM64 runners (self-hosted)
- **Matrix Testing**: All ORO applications (OroPlatform, OroCRM, OroCommerce, Marello)
- **Version Coverage**: Multiple PHP versions (8.3, 8.4), Node.js versions (20, 22)
- **Containerized Runners**: Docker-in-Docker with `myoung34/github-runner`
- **Goss Validation**: Comprehensive post-install checks

#### Local Testing
See `LOCAL-TESTING.md` for comprehensive local testing methods:
- Quick commands for rapid iteration
- Manual testing procedures
- GitHub Actions locally with Act

### Git Workflow

#### Branch Strategy
**CRITICAL RULES:**
1. **ALWAYS** create new branch for new tasks
2. **ALWAYS** sync with upstream before creating branches
3. **NEVER** work directly in master/main
4. **NEVER** push directly to master/main (use Pull Requests)
5. **NEVER** add changes to already-pushed branches (create new branch)

#### Standard Workflow
```bash
# 1. Sync with upstream
git fetch --all
git checkout master
git pull main master    # Pull from upstream (main remote)
git push origin master  # Update your fork

# 2. Create feature branch
git checkout -b feature/descriptive-name

# 3. Update formula version BEFORE commit
# Edit Formula/docker-compose-oroplatform.rb
# Increment version: 0.8.6 -> 0.8.7 (patch), 0.9.0 (minor), 1.0.0 (major)

# 4. Commit and push
git add .
git commit -m "descriptive message"
git push -u origin feature/descriptive-name

# 5. Create Pull Request via GitHub
```

#### Branch Naming
- `feature/description` - New features
- `fix/description` - Bug fixes
- `update/component` - Version/config updates
- `docs/topic` - Documentation
- `refactor/component` - Code refactoring

#### Version Bumping
**MANDATORY**: Always update version in `Formula/docker-compose-oroplatform.rb` before committing:
- **Patch**: Bug fixes, typos (0.8.6 → 0.8.7)
- **Minor**: New features, backwards compatible (0.8.6 → 0.9.0)
- **Major**: Breaking changes (0.8.6 → 1.0.0)

#### Commit After Merge
When user says "я смерджил" (I merged) or "merged":
1. **IMMEDIATELY** sync with upstream
2. **CREATE** new branch for any new work
3. **NEVER** continue in merged branch

## Domain Context

### ORO Platform Ecosystem
- **OroPlatform**: Base platform for business applications
- **OroCRM**: Customer Relationship Management
- **OroCommerce**: B2B E-commerce platform
- **MarelloCommerce**: Omnichannel commerce solution

### ORO Application Structure
- **Symfony-based**: PHP framework (Symfony 5.x/6.x)
- **Doctrine ORM**: Database abstraction
- **Message Queue**: Background job processing
- **WebSocket**: Real-time communication
- **Assets**: Webpack-based frontend builds
- **Admin Panel**: `/admin` URL path
- **Default Credentials**: `admin` / `12345678` or `$ecretPassw0rd`
- **Authelia**: Optional authentication layer (credentials: `oro` / `oro`)

### Docker Environment Specifics
- **Project URL Format**: `https://{project-folder-name}.docker.local`
- **Admin URL**: `https://{project-folder-name}.docker.local/admin`
- **Port Prefix System**: `DC_ORO_PORT_PREFIX=302` → ports 30280, 30243, etc.
- **Container Naming**: `{projectname}_servicename_version`
- **Volume Persistence**: Named volumes for data, code sync varies by mode

### Configuration Files
- `.env.orodc`: Project-specific OroDC settings (optional, user-created)
- `app/.env.local`: ORO application environment variables
- `docker-compose.yml`: Generated from templates (never edit directly)
- `DC_ORO_CONFIG_DIR`: Custom config location (default: `~/.orodc/{project_name}`)
- `~/.orodc/{project_name}/.env.orodc`: Global project configuration (auto-created, stores domain replacement preferences)

**Important:** OroDC never creates files in project directory without user permission. Configuration is stored globally in `~/.orodc/{project_name}/.env.orodc` unless user explicitly creates `.env.orodc` in project root.

## Important Constraints

### Technical Constraints
- **Zsh Compatibility**: All shell commands must work in zsh (quote escaping issues)
- **Docker Requirement**: Docker Desktop (macOS/Windows) or Docker Engine (Linux)
- **Homebrew Requirement**: Package manager for installation
- **Architecture Support**: X64 and ARM64 (Apple Silicon, AWS Graviton)
- **macOS Performance**: MUST use Mutagen mode (native Docker FS is extremely slow)
- **CI/CD Config Location**: `DC_ORO_CONFIG_DIR` MUST be inside workspace for Docker volume mounting

### Business Constraints
- **Homebrew Distribution**: Formula must follow Homebrew conventions
- **Zero Application Changes**: Works without modifying ORO application code
- **Backward Compatibility**: Support multiple PHP/Node.js/Composer versions
- **Enterprise Features**: Multisite, WebSockets, profiling, testing

### Platform Constraints
- **Linux/WSL2**: Use `default` mode (fastest)
- **macOS**: Use `mutagen` mode (required for performance)
- **Windows**: Only via WSL2 with Docker Desktop
- **Docker Desktop VM**: Requires two-stage Traefik setup (host + Docker)
- **Native Docker**: Direct Traefik connection to containers

## External Dependencies

### Homebrew Packages
- **digitalspacestdio/ngdev**: Infrastructure tap
  - `digitalspace-traefik`: Reverse proxy
  - `digitalspace-dnsmasq`: Local DNS resolver
  - `digitalspace-local-ca`: SSL certificate authority
  - `digitalspace-allutils`: Helper scripts

### Docker Images (External)
- **PostgreSQL**: `postgres:15/16/17`
- **MySQL**: `mysql:8`
- **Redis**: `redis:6.2/7.0`
- **Elasticsearch**: `elasticsearch:8.10.3`
- **RabbitMQ**: `rabbitmq:3.9-management-alpine`
- **Nginx**: `nginx:latest`
- **MailHog**: `mailhog/mailhog:latest`
- **XHGui**: `perftools/xhgui:0.18.4`
- **MongoDB**: `mongo:4.4`

### Docker Images (Internal)
- **PHP Base**: `ghcr.io/digitalspacestdio/orodc-php-node-symfony:{version}`
  - Multi-arch (amd64, arm64)
  - PHP 7.4-8.5 variants
  - Node.js 18/20/22 variants
  - Composer 1/2 variants

### GitHub Actions
- **Runners**: Self-hosted Linux (X64, ARM64)
- **Container Image**: `myoung34/github-runner:latest` (Docker-in-Docker)
- **Actions**: `actions/checkout@v4`, custom workflows

### External Services
- **GitHub Container Registry**: Docker image hosting
- **GitHub Packages**: Alternative registry
- **ORO Repositories**: Official application sources
  - `https://github.com/oroinc/*-application.git`
  - `https://github.com/marellocommerce/marello-application.git`

### Testing Tools
- **Goss**: Infrastructure validation (`dgoss`, `goss validate`)
- **Hadolint**: Dockerfile linting
- **ShellCheck**: Shell script validation
- **yamllint**: YAML syntax validation
- **actionlint**: GitHub Actions validation
