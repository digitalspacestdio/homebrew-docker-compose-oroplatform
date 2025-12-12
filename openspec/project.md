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
- **PHP Base**: Custom multi-arch images (ghcr.io/digitalspacestdio/orodc-php-node-symfony)
  - PHP versions: 7.4, 8.1, 8.2, 8.3, 8.4, 8.5
  - Node.js versions: 18, 20, 22
  - Composer versions: 1, 2
  - Base distro: Alpine Linux
- **Database**: PostgreSQL 15/16/17, MySQL 8
- **Cache**: Redis 6.2/7.0
- **Search**: Elasticsearch 8.10.3
- **Queue**: RabbitMQ 3.9-management-alpine
- **Web Server**: Nginx (latest)
- **Mail**: MailHog (testing)
- **Profiling**: XHGui + MongoDB

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
└── .github/workflows/     # CI/CD pipeline definitions
```

### Architecture Patterns

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
- `.env.orodc`: Project-specific OroDC settings
- `app/.env.local`: ORO application environment variables
- `docker-compose.yml`: Generated from templates (never edit directly)
- `DC_ORO_CONFIG_DIR`: Custom config location (default: `~/.orodc/{project_name}`)

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
