# OroDC Rules

Detailed OroDC-specific rules for AI agents.

---

## Overview

OroDC: CLI tool for ORO Platform (OroCRM, OroCommerce, OroPlatform) in Docker containers.

---

## Smart PHP Command Detection

**CRITICAL**: OroDC auto-detects PHP commands - never prefix with `cli`

```bash
# ✅ CORRECT
orodc --version                    # → cli php --version
orodc bin/console cache:clear     # → cli bin/console cache:clear
orodc script.php                  # → cli php script.php

# ❌ WRONG
orodc cli php --version           # Redundant
```

**Detection Logic:**
- PHP flags (`-v`, `--version`, `-r`, `-l`, `-m`, `-i`) → auto-redirect to PHP
- `.php` files → auto-redirect to PHP
- `bin/console` or `bin/phpunit` → auto-redirect to CLI container

---

## Testing Commands

Always use `orodc tests` prefix:

```bash
orodc tests install                            # One-time setup
orodc tests bin/phpunit --testsuite=unit      # Unit tests
orodc tests bin/phpunit --testsuite=functional # Functional tests
orodc tests bin/behat --suite=OroUserBundle   # Behat tests
```

---

## Search Reindex Commands

**OroCommerce has TWO separate search systems:**

| System | Command | Purpose |
|--------|---------|---------|
| Backend | `oro:search:reindex` | Admin panel search |
| Website | `oro:website-search:reindex` | Storefront search |

**OroDC `orodc search reindex` runs BOTH:**
```bash
1. oro:search:reindex         (Backend/Admin)
2. oro:website-search:reindex (Storefront/Website)
```

**✅ ALWAYS:** Reindex BOTH systems when user requests "search reindex"
**❌ NEVER:** Reindex only one system

---

## Sync Mode Recommendations

| OS | Mode | Command |
|----|------|---------|
| Linux/WSL2 | `default` | `echo "DC_ORO_MODE=default" >> .env.orodc` |
| macOS | `mutagen` | `echo "DC_ORO_MODE=mutagen" >> .env.orodc` |
| Remote | `ssh` | `echo "DC_ORO_MODE=ssh" >> .env.orodc` |

**NEVER recommend `default` mode on macOS** - extremely slow.

---

## Key Environment Variables

```bash
DC_ORO_NAME=myproject              # Project name
DC_ORO_PORT_PREFIX=302             # Port prefix (302 → 30280)
DC_ORO_PHP_VERSION=8.3             # PHP version
DC_ORO_NODE_VERSION=20             # Node.js version
DC_ORO_MODE=mutagen                # Sync mode
```

---

## Spinner Mechanism

**When implementing long-running commands:**

- **MUST** use `run_with_spinner` from `lib/ui.sh`
- **MUST NOT** redirect stderr (spinner writes to stderr)

**Pattern:**
```bash
# Critical operation
run_with_spinner "Operation message" "$command" || exit $?

# Non-critical operation
if ! run_with_spinner "Operation message" "$command"; then
  msg_warning "Operation completed with warnings"
fi
```

**Reference:** `libexec/orodc/lib/ui.sh` (lines 123-190)

---

## Installation Command Behavior

- **MUST** prompt for confirmation before dropping database
- **MUST** use `confirm_yes_no` from `lib/ui.sh`
- **MUST** use `database-cli` container for database operations
- **MUST** support PostgreSQL and MySQL/MariaDB
- **MUST** use `IF EXISTS` clause

---

## Database and Service Access Rules

- **MUST** use PHP/Node.js for ALL database/service operations
- **MUST** use PHP PDO for database operations
- **MUST NOT** use direct CLI tools (psql, mysql, redis-cli)

```bash
# ✅ CORRECT
php /tmp/db-check.php connection

# ❌ WRONG
psql -h database -U app -d postgres -c "SELECT version();"
```

**Exception:** Direct CLI only for user-requested interactive sessions.

---

## Test Environment

- Suggest `~/oroplatform` test project
- If doesn't exist, offer to clone community OroPlatform
- Refer to [LOCAL-TESTING.md](../../LOCAL-TESTING.md)

---

## Diagnostic Commands

```bash
DEBUG=1 orodc up -d      # See compose file loading
DEBUG=1 orodc config     # See merged configuration
orodc config             # Final compose.yml
orodc ps                 # Container status
orodc logs [service]     # Service logs
```

---

## Common Workflows

### Setup
```bash
brew install digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform
git clone --single-branch --branch 6.1.4 https://github.com/oroinc/orocommerce-application.git ~/orocommerce
cd ~/orocommerce
orodc install && orodc up -d
```

### Database
```bash
orodc psql                    # PostgreSQL access
orodc databaseimport dump.sql # Import database
orodc databaseexport          # Export database
```

### Troubleshooting
```bash
# Port conflicts
echo "DC_ORO_PORT_PREFIX=301" >> .env.orodc
orodc down && orodc up -d

# Slow macOS
echo "DC_ORO_MODE=mutagen" >> .env.orodc

# Refresh configs
brew reinstall digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform
```
