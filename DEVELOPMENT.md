# OroDC Development Guide

## Overview
OroDC: CLI tool for PHP applications in Docker containers. Supports ORO Platform (OroCRM, OroCommerce, OroPlatform, MarelloCommerce), Magento 2, Symfony, Laravel, WinterCMS, and generic PHP projects.

## Architecture

### Cross-Platform Path Resolution
**CRITICAL**: OroDC uses dynamic Homebrew prefix detection for compose file paths.

**Path Resolution Logic:**
```bash
# Get Homebrew prefix dynamically (works on macOS and Linux)
BREW_PREFIX="$(brew --prefix)"

# Try paths in order:
# 1. Development tap directory: ${BREW_PREFIX}/Homebrew/Library/Taps/.../compose
# 2. Installed pkgshare: ${BREW_PREFIX}/share/docker-compose-oroplatform/compose
# 3. Relative to script: $SCRIPT_DIR/../compose
```

**Platform-Specific Homebrew Locations:**
- **Linux**: `/home/linuxbrew/.linuxbrew`
- **macOS Intel**: `/usr/local`
- **macOS Apple Silicon**: `/opt/homebrew`

### Smart PHP Command Detection
**CRITICAL**: OroDC auto-detects PHP commands - never prefix with `cli`

```bash
# ✅ CORRECT
orodc --version                    # → cli php --version
orodc bin/console cache:clear     # → cli bin/console cache:clear (Oro/Symfony)
orodc bin/magento cache:clean     # → cli bin/magento cache:clean (Magento)
orodc script.php                  # → cli php script.php

# ❌ WRONG
orodc cli php --version           # Redundant
```

**Detection Logic:**
- PHP flags (`-v`, `--version`, `-r`, `-l`, `-m`, `-i`) → auto-redirect to PHP
- `.php` files → auto-redirect to PHP
- `bin/console`, `bin/phpunit`, `bin/magento` → auto-redirect to CLI container

**Composer Non-Interactive Mode:**
- ALL composer commands automatically run with `--no-interaction`
- Uses `docker compose run -T` to disable pseudo-TTY
- Auto-creates `config/parameters.yml` from `.dist` if not exists

```bash
# ✅ CORRECT - automatically runs with --no-interaction
orodc composer install
orodc composer update
orodc composer require vendor/package
```

### Testing Commands
Always use `orodc tests` prefix:

```bash
orodc tests install                            # One-time setup
orodc tests bin/phpunit --testsuite=unit      # Unit tests
orodc tests bin/phpunit --testsuite=functional # Functional tests
orodc tests bin/behat --suite=OroUserBundle   # Behat tests
```

## Environment Configuration

### Sync Mode (Performance Critical)
| OS | Mode | Command | Reason |
|----|------|---------|--------|
| Linux/WSL2 | `default` | `echo "DC_ORO_MODE=default" >> .env.orodc` | Fastest |
| macOS | `mutagen` | `echo "DC_ORO_MODE=mutagen" >> .env.orodc` | Avoids slow Docker FS |
| Remote | `ssh` | `echo "DC_ORO_MODE=ssh" >> .env.orodc` | Only option |

**NEVER use `default` mode on macOS** - extremely slow.

### Key Environment Variables
```bash
DC_ORO_NAME=myproject              # Project name
DC_ORO_PORT_PREFIX=302             # Port prefix (302 → 30280)
DC_ORO_PHP_VERSION=8.3             # PHP version
DC_ORO_NODE_VERSION=20             # Node.js version
DC_ORO_MODE=mutagen                # Sync mode
```

## Common Workflows

### Setup (New Project)

**OroCommerce:**
```bash
brew install digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform
git clone --single-branch --branch 6.1.4 https://github.com/oroinc/orocommerce-application.git ~/orocommerce
cd ~/orocommerce
orodc install && orodc up -d
```

**Magento 2 (Mage-OS):**
```bash
mkdir ~/mageos && cd ~/mageos
orodc init && orodc up -d
orodc exec composer create-project --repository-url=https://repo.mage-os.org/ mage-os/project-community-edition .
```

### Test Project Setup
For testing and development:

```bash
# Clone community OroPlatform
git clone --single-branch --branch 6.1 https://github.com/oroinc/platform-application.git ~/oroplatform
cd ~/oroplatform
orodc install && orodc up -d
```

### Development
```bash
orodc up -d                                    # Start services
orodc bin/console cache:clear                  # Clear cache
orodc bin/console oro:assets:build default -w # Watch assets
```

### Testing
```bash
cd ~/oroplatform
orodc tests install                            # Setup test env
orodc tests bin/phpunit --testsuite=unit      # Unit tests
orodc tests bin/phpunit --testsuite=functional # Functional tests
orodc tests bin/behat --suite=OroUserBundle   # Behat tests
```

See [LOCAL-TESTING.md](LOCAL-TESTING.md) for comprehensive testing guide.

### Database Operations
```bash
orodc psql                         # PostgreSQL access
orodc databaseimport dump.sql      # Import database (with domain replacement)
orodc databaseexport              # Export database
```

**Database Import Features:**

- **Domain Replacement**: Automatically replace domain names in SQL dumps during import
- **Domain Memory**: Previously used domains are saved to `~/.orodc/{project-name}/.env.orodc` and suggested on next import
- **Progress Display**: Shows `pv` progress bar for PostgreSQL/MySQL (if available) or spinner otherwise
- **Interactive Prompts**: Confirms database deletion and optionally prompts for domain replacement

### Project Recreation from Database Dump
```bash
# Full project recreation
orodc purge && \
orodc importdb ~/backup.sql.gz && \
orodc platformupdate && \
orodc updateurl
```

## Troubleshooting

### Port Conflicts
```bash
orodc down && orodc up -d
# If still conflicts:
echo "DC_ORO_PORT_PREFIX=301" >> .env.orodc
orodc down && orodc up -d
```

### Slow macOS Performance
```bash
echo "DC_ORO_MODE=mutagen" >> .env.orodc
brew install mutagen-io/mutagen/mutagen
orodc down && orodc up -d
```

### Permission Errors
```bash
orodc purge
orodc install
```

### Container Issues
```bash
orodc logs [service-name]          # Check logs
DEBUG=1 orodc up -d               # Debug mode
orodc down && orodc up -d --build # Force rebuild
```

### Configuration Not Updating
```bash
# Reinstall formula to refresh files
brew reinstall digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform

# Remove old config and restart
rm -rf ~/.orodc/[project-name]
orodc up -d
```

## Diagnostic Commands

**Use `DEBUG=1` for troubleshooting:**

```bash
DEBUG=1 orodc up -d               # Full execution flow
DEBUG=1 orodc config              # Merged configuration
DEBUG=1 orodc [any-command]       # Verbose output

orodc config                      # Final merged compose.yml
orodc config | grep -A 20 "database:"
orodc ps                          # Container status
orodc logs [service]              # Service logs  
orodc ssh                         # Container access
```

## DC_ORO_CONFIG_DIR

**Custom configuration directory:**

```bash
# Default behavior
orodc install  # Uses ~/.orodc/{project_name}

# Custom config directory
export DC_ORO_CONFIG_DIR="/path/to/custom/config"
orodc install

# Project-local config (recommended for CI/CD)
export DC_ORO_CONFIG_DIR="$(pwd)/.orodc"
orodc install
```

**CI/CD Requirements:**
- **MUST** be inside workspace for Docker volume mounting
- Use unique suffixes for parallel runs
- Never use .env.orodc file - only environment variables

```bash
# ✅ CORRECT
export DC_ORO_CONFIG_DIR="${GITHUB_WORKSPACE}/test-${BUILD_ID}/.orodc"
export DC_ORO_NAME="project-${BUILD_ID}-${RANDOM}"

# ❌ WRONG
export DC_ORO_CONFIG_DIR="/tmp/.orodc"  # Docker mounting fails!
```

## Code Quality Tools

### Dockerfile Linting
```bash
# Using Docker
docker run --rm -i hadolint/hadolint < compose/docker/php/Dockerfile.8.5.alpine

# Install locally
brew install hadolint
hadolint compose/docker/php/Dockerfile.8.5.alpine
```

### GitHub Actions Validation
```bash
brew install actionlint
actionlint .github/workflows/*.yml
```

### YAML Validation
```bash
yq eval '.github/workflows/test.yml' > /dev/null

pip install yamllint
yamllint .github/workflows/
```

### Shell Script Validation
```bash
brew install shellcheck
shellcheck bin/orodc
shellcheck .github/scripts/*.sh
```

## Command Reference
| Task | Command | Notes |
|------|---------|-------|
| Setup | `orodc install && orodc up -d` | One-time |
| PHP | `orodc [php-command]` | Auto-detected |
| Test | `orodc tests [command]` | Isolated env |
| DB | `orodc psql` | Direct access |
| Import DB | `orodc importdb dump.sql.gz` | Import database |
| Recreate | `orodc --profile=X purge && orodc importdb ...` | Full recreation |
| Platform Update | `orodc platformupdate` | After DB import |
| Update URLs | `orodc updateurl` | Fix local URLs |
| Debug | `DEBUG=1 orodc [command]` | Verbose |
| SSH | `orodc ssh` | Container access |

