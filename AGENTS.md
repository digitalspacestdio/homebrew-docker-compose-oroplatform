# AI Agents Guidelines

This document contains guidelines for AI agents working with the homebrew-docker-compose-oroplatform project.

---

# Git Workflow Guidelines

## 🌿 **ALWAYS work in branches!**

### ✅ Correct workflow:

1. **Start from master/main:**
   ```bash
   git checkout master
   git pull origin master
   ```

2. **Create a new branch for your task:**
   ```bash
   git checkout -b feature/descriptive-branch-name
   # or
   git checkout -b fix/issue-description
   # or  
   git checkout -b update/component-name
   ```

3. **Update formula version (REQUIRED before each commit):**
   ```bash
   # Edit Formula/docker-compose-oroplatform.rb
   # Increment version "X.Y.Z" -> "X.Y.Z+1" (e.g. "0.8.6" -> "0.8.7")
   # For semantic versioning:
   # - Patch: 0.8.6 -> 0.8.7 (bug fixes)
   # - Minor: 0.8.6 -> 0.9.0 (new features)
   # - Major: 0.8.6 -> 1.0.0 (breaking changes)
   ```

4. **Make commits in the branch:**
   ```bash
   git add .
   git commit -m "descriptive commit message"
   ```

5. **Push branch for review:**
   ```bash
   git push -u origin feature/descriptive-branch-name
   ```

### ❌ **NEVER work directly in master/main!**

### 📛 If you accidentally worked in master:

1. **Create a branch from current state:**
   ```bash
   git checkout -b fix/accidental-master-work
   ```

2. **Reset master to origin:**
   ```bash
   git checkout master
   git reset --hard origin/master
   ```

3. **Continue work in the branch**

### 🎯 Branch naming rules:

- `feature/short-description` - new features
- `fix/issue-description` - bug fixes  
- `update/component-name` - version/config updates
- `docs/topic` - documentation
- `refactor/component` - refactoring

### 💡 Examples of good branch names:

- `update/oro-workflow-versions`
- `fix/yaml-syntax-errors`  
- `feature/php-auto-detection`
- `docs/installation-guide`

### 📦 **Formula Versioning Examples:**

```ruby
# Before (in Formula/docker-compose-oroplatform.rb)
version "0.8.6"

# After - Bug fix
version "0.8.7"

# After - New feature
version "0.9.0"

# After - Breaking change
version "1.0.0"
```

### ⚠️ **CRITICAL: Version Update is Mandatory!**

- **ALWAYS** update the version before committing changes to `compose/` or `bin/`
- **NEVER** commit without version increment when modifying core functionality
- Version updates ensure proper Homebrew package management

---
**Remember: Version first, branch first, commit later! 📦🌳**

---

# OroDC Guidelines for Cursor

## Overview
OroDC: CLI tool for ORO Platform (OroCRM, OroCommerce, OroPlatform) in Docker containers.

## Core Rules

### 1. Smart PHP Command Detection
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

### 2. Testing Commands
Always use `orodc tests` prefix for test operations:

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

**NEVER recommend `default` mode on macOS** - extremely slow.

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
```bash
brew install digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform
git clone --single-branch --branch 6.1.4 https://github.com/oroinc/orocommerce-application.git ~/orocommerce
cd ~/orocommerce
orodc install && orodc up -d
```

### Test Project Setup
**For testing and development**, there's a dedicated OroPlatform project in `~/oroplatform`:

```bash
# If project doesn't exist, clone community OroPlatform
if [ ! -d ~/oroplatform ]; then
  git clone --single-branch --branch 6.1 https://github.com/oroinc/platform-application.git ~/oroplatform
  cd ~/oroplatform
  orodc install && orodc up -d
fi

# Use existing test project
cd ~/oroplatform
orodc up -d
```

**Benefits:**
- Always available for quick testing
- Isolated from main development projects  
- Community version - no enterprise dependencies
- Perfect for reproducing issues and testing features

### Development
```bash
orodc up -d                                    # Start services
orodc bin/console cache:clear                  # Clear cache
orodc bin/console oro:assets:build default -w # Watch assets
```

### Testing
```bash
# In any OroPlatform project or use ~/oroplatform test project
cd ~/oroplatform  # Use dedicated test project
orodc tests install                            # Setup test env
orodc tests bin/phpunit --testsuite=unit      # Unit tests
orodc tests bin/phpunit --testsuite=functional # Functional tests
orodc tests bin/behat --suite=OroUserBundle   # Behat tests
```

**Note:** Use `~/oroplatform` for consistent testing environment across all OroDC development.

### Database
```bash
orodc psql                         # PostgreSQL access
orodc databaseimport dump.sql      # Import database
orodc databaseexport              # Export database
```

### Project Recreation from Database Dump
Complete project recreation from existing database dump:

```bash
# Full project recreation with specific profile
orodc --profile=consumer purge && \
orodc importdb ~/orocommerce-backup-2024-01-15.sql.gz && \
orodc platformupdate && \
orodc bin/console oro:user:update --user-password=12345678 admin && \
orodc updateurl
```

**Step-by-step breakdown:**
```bash
orodc --profile=consumer purge     # Clean existing project with profile
orodc importdb ~/orocommerce-backup-2024-01-15.sql.gz  # Import database dump
orodc platformupdate               # Update platform after import
orodc bin/console oro:user:update --user-password=12345678 admin  # Reset admin password
orodc updateurl                    # Update URLs for local development
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

## Diagnostic Commands
```bash
orodc ps                          # Container status
DEBUG=1 orodc [command]           # Debug output
orodc logs [service]              # Service logs
orodc ssh                         # Container access
```

## Response Guidelines

### Always Include:
- Complete workflows, not isolated commands
- OS-specific considerations
- Performance implications
- Error context when troubleshooting

### Never Suggest:
- `cli` prefix for PHP commands
- `default` mode on macOS
- Commands without setup context
- Incomplete workflows
- `[[ -n "${DEBUG:-}" ]]` syntax (causes script termination due to `set -e`)
- Emojis in terminal commands or output
- Shell syntax that isn't zsh compatible

### Ask User For:
- Operating system
- Current sync mode
- Error messages
- Output of `orodc ps`

### When User Needs Test Environment:
- Suggest using `~/oroplatform` test project
- If it doesn't exist, offer to clone community OroPlatform
- Always prefer `~/oroplatform` for consistent testing and troubleshooting

### Repository Management (CRITICAL):
- **ALWAYS merge/pull ONLY from remote repositories** (origin, main, upstream)
- **NEVER suggest merging local branches** unless explicitly requested by user
- Default workflow: `git pull --rebase origin master` or `git rebase master` after updating from remote
- When updating branches: always sync with remote first, then rebase feature branches
- Exception: Only merge local branches if user explicitly asks for local branch operations

## Shell Compatibility Requirements

### Zsh Compatibility (CRITICAL)
**All commands MUST be zsh compatible** to avoid shell escaping issues:

```bash
# ✅ CORRECT - Works in both bash and zsh
echo "DC_ORO_MODE=mutagen" >> .env.orodc
orodc bin/console cache:clear --env=prod

# ❌ WRONG - May break in zsh due to quote escaping
echo 'DC_ORO_MODE="mutagen"' >> .env.orodc  # Double quote escaping issues
```

### Terminal Output Rules
- **NEVER use emojis** in terminal commands or output
- **NEVER use Unicode symbols** that may not render properly
- Use plain ASCII text for maximum compatibility
- Use simple status indicators: `[OK]`, `[ERROR]`, `[INFO]`

```bash
# ✅ CORRECT
echo "[OK] OroDC installation completed"
echo "[ERROR] Port conflict detected"

# ❌ WRONG  
echo "✅ OroDC installation completed"
echo "🚨 Port conflict detected"
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
