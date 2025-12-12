# AI Agents Guidelines

This document contains guidelines for AI agents working with the homebrew-docker-compose-oroplatform project.

---

# 🔴🔴🔴 **CRITICAL: "NEW BRANCH" ALWAYS MEANS FROM UPSTREAM!**

## ⚡ **WHEN USER SAYS "CREATE NEW BRANCH" OR "NEW BRANCH":**

**THIS ALWAYS MEANS:**
- ✅ Sync with upstream (main repository) FIRST
- ✅ Create branch from LATEST upstream master
- ✅ NEVER continue existing work
- ✅ NEVER assume current branch is correct

**MANDATORY WORKFLOW:**
```bash
# ✅ ALWAYS DO THIS WHEN USER SAYS "NEW BRANCH":
git fetch --all
git checkout master
git pull main master
git push origin master
git checkout -b feature/new-task-name
```

**⛔ NEVER:**
- ❌ Continue working in current branch when user says "new branch"
- ❌ Create branch without syncing upstream first
- ❌ Assume user wants to continue existing work

**💡 USER EXPECTATION:**
- "New branch" = fresh start from upstream
- "New branch" = abandon current work context
- "New branch" = sync with latest changes first

---

# 🔴 **CRITICAL: NEW TASK = NEW BRANCH!**

## ⚡ **MANDATORY RULE: ALWAYS CREATE NEW BRANCH FOR NEW TASK!**

**🚨 BEFORE STARTING ANY NEW TASK:**
```bash
# ✅ MANDATORY WORKFLOW FOR EVERY NEW TASK:
git fetch --all
git checkout master
git pull main master
git push origin master
git checkout -b fix/descriptive-task-name
```

**🔥 THIS RULE APPLIES TO:**
- ✅ New features
- ✅ Bug fixes
- ✅ Configuration changes
- ✅ Documentation updates
- ✅ ANY code modifications

**⛔ NEVER:**
- ❌ Start working without creating a branch
- ❌ Continue in old branch when starting new task
- ❌ Make changes directly in master
- ❌ Assume you're in the right branch

**💡 WHY THIS IS CRITICAL:**
- Prevents mixing unrelated changes
- Allows independent code review per task
- Enables parallel work on multiple features
- Maintains clean git history
- Prevents broken Pull Requests

---

# 🚨 **CRITICAL: PRE-PUSH MANDATORY SYNC!**

## ⚡ **BEFORE ANY BRANCH CREATION - MANDATORY STEPS:**

```bash
# ✅ ALWAYS DO THIS FIRST! EVERY TIME! NO EXCEPTIONS!
git fetch --all
git checkout master  
git pull main master    # NOT origin master!
git push origin master  # Update your fork

# ❌ ONLY AFTER SYNC - create branch:
git checkout -b feature/your-branch-name
```

**🔥 FAILURE TO SYNC CAUSES:**
- Merge conflicts
- Divergent branches  
- Failed CI/CD
- Broken Pull Requests
- Wasted time debugging

**⛔ NEVER SKIP THIS STEP!**

---

# Git Workflow Guidelines

## 🔄 **Upstream Repository Management**

### 📍 **CRITICAL: Identify Your Upstream**
If you see a remote called `main` or `upstream` in your `git remote -v` output, this is the **main upstream repository**:
```bash
git remote -v
# main      git@github.com:digitalspacestdio/homebrew-docker-compose-oroplatform.git
# origin    git@github.com:YOUR-USERNAME/homebrew-docker-compose-oroplatform.git
```

**ALWAYS sync with the upstream FIRST:**
```bash
# Update from upstream (main remote)
git fetch --all
git checkout master
git pull main master    # NOT origin master!
git push origin master  # Update your fork
```

## 🌿 **ALWAYS work in branches!**

### ✅ Correct workflow:

1. **Start from master/main (updated from upstream):**
   ```bash
   git checkout master
   git pull main master    # Pull from upstream, not origin
   git push origin master  # Update your fork
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

### 🚫 **CRITICAL: NEVER push directly to master/main!**

**⛔ ABSOLUTELY FORBIDDEN:**
```bash
# NEVER DO THIS! NEVER!
git checkout master
git merge some-branch
git push origin master     # ❌ FORBIDDEN!
```

**✅ ALWAYS use Pull Requests:**
```bash
# ✅ CORRECT: Push branch and create PR
git push -u origin feature/my-feature
# Then create Pull Request via GitHub interface
```

**Why this rule exists:**
- 🔍 **Code Review**: Every change must be reviewed
- 🛡️ **Quality Control**: Prevent breaking changes
- 📝 **Documentation**: Maintain clear change history  
- 🤝 **Collaboration**: Allow team discussion
- 🔄 **CI/CD**: Automated testing before merge

**⚠️ If you accidentally pushed to master:**
1. Immediately notify the team
2. Create rollback PR if needed
3. Follow proper branch workflow for future changes

### 🔄 **CRITICAL: New Changes After Push Rule**

**⛔ NEVER add new changes to already pushed branches:**

If you've already pushed a branch and want to add MORE changes, **ALWAYS**:

1. **Update from upstream first:**
   ```bash
   git fetch --all
   git checkout master
   git pull main master
   git push origin master
   ```

2. **Create NEW branch for additional changes:**
   ```bash
   git checkout -b fix/additional-improvements
   # Make your new changes
   git commit -m "Additional improvements"
   git push -u origin fix/additional-improvements
   ```

**⛔ NEVER do this after push:**
```bash
# ❌ WRONG: Adding to already pushed branch
git checkout existing-pushed-branch
# make changes
git commit -m "more changes" 
git push  # ❌ This creates messy history!
```

**Why this rule exists:**
- 🔄 **Clean History**: Each branch represents one logical change
- 🔍 **Clear Review**: Easier to review focused changes
- 🛡️ **Safer Merges**: Avoid complex merge conflicts
- 📝 **Better Tracking**: Each PR has clear scope and purpose

**Exception:** Only add to pushed branches if explicitly fixing issues in the SAME Pull Request discussion.

### 🚨 **CRITICAL: When User Says "I Merged"**

**⚡ IMMEDIATE ACTION REQUIRED:**
When the user says **"я смерджил"** (I merged) or **"смерджил"** or **"merged"**, this means:

1. **The current branch is now merged into main repository**
2. **You MUST immediately create a NEW branch for any new work**
3. **Do NOT continue working in the current branch**

**✅ CORRECT workflow after merge:**
```bash
# 1. Sync with upstream (main repository)  
git fetch --all
git checkout master
git pull main master    # Pull from upstream
git push origin master  # Update your fork

# 2. Create NEW branch for new work
git checkout -b feature/next-improvements
```

**❌ WRONG: Continue working in merged branch**
```bash
# This pollutes merge history and creates confusion
git commit -m "more changes"  # ❌ NEVER do this after merge!
```

**Why this rule exists:**
- 🔄 **Clean History**: Each branch represents one complete feature/fix
- 🛡️ **Avoid Conflicts**: Prevents merge pollution and history confusion
- 📋 **Clear Tracking**: Each branch has clear purpose and lifecycle
- 🚀 **Proper Flow**: Maintain proper git workflow discipline

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

**📋 For comprehensive local testing guidance:** See [LOCAL-TESTING.md](LOCAL-TESTING.md) for detailed testing methods, including quick commands, manual testing, and GitHub Actions locally with Act.

## CI/CD Testing with Goss

### Structured Workflow Steps
The OroDC CI/CD pipeline is structured into clear, separate steps:

1. **Install Homebrew and OroDC** - One-time setup with caching
2. **Setup test environment** - Create unique project workspace  
3. **Clone application** - Download Oro application code
4. **Configure OroDC** - Set unique project names and ports
5. **Install application** - Run `orodc install` 
6. **Start services** - Run `orodc up -d` and wait for health
7. **Run tests** - Execute comprehensive Goss verification tests

### Goss Testing Framework
**Goss** is used for comprehensive installation verification:

```bash
# Goss tests verify:
# - Container health (6+ containers running)
# - PHP version (8.3/8.4) 
# - Database connectivity (PostgreSQL)
# - HTTP server accessibility (nginx)
# - Admin interface availability
# - Service endpoint responses
# - Port accessibility
```

**Benefits of Goss:**
- ✅ **Structured tests**: YAML-based test definitions
- ✅ **Multiple formats**: JUnit XML, Pretty output, JSON
- ✅ **Comprehensive**: Tests containers, services, HTTP, commands
- ✅ **Fast execution**: Parallel test execution  
- ✅ **Clear results**: Pass/fail with detailed reporting

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
- **For detailed testing methods:** Refer user to [LOCAL-TESTING.md](LOCAL-TESTING.md) for comprehensive local testing guide

### Repository Management (CRITICAL):
- **ALWAYS merge/pull ONLY from remote repositories** (origin, main, upstream)
- **NEVER suggest merging local branches** unless explicitly requested by user
- Default workflow: `git pull --rebase origin master` or `git rebase master` after updating from remote
- When updating branches: always sync with remote first, then rebase feature branches
- Exception: Only merge local branches if user explicitly asks for local branch operations

## OroDC Configuration Directory Customization

### DC_ORO_CONFIG_DIR Environment Variable
**NEW FEATURE**: OroDC now supports custom configuration directory location via `DC_ORO_CONFIG_DIR` environment variable.

**Usage:**
```bash
# Default behavior (unchanged)
orodc install  # Uses ~/.orodc/{project_name}

# Custom config directory
export DC_ORO_CONFIG_DIR="/path/to/custom/config"
orodc install  # Uses /path/to/custom/config

# Project-local config (recommended for CI/CD)
export DC_ORO_CONFIG_DIR="$(pwd)/.orodc"
orodc install  # Uses ./.orodc in current project
```

**Benefits:**
- 🏠 **Project-local configs**: Store OroDC config alongside project sources
- 🐳 **Docker-friendly**: Eliminates complex volume mounting in containerized environments
- 🔒 **Better isolation**: Each project has completely separate OroDC configuration

**CRITICAL for CI/CD and Containerized Environments:**
- **DC_ORO_CONFIG_DIR MUST be inside the workspace/project directory**
- **Required for Docker volume mounting to work properly**
- **Use unique suffixes for parallel test runs to prevent conflicts**
- **Never use .env.orodc file in CI - only environment variables**

**CI/CD Example:**
```bash
# ✅ CORRECT - config inside workspace
export DC_ORO_CONFIG_DIR="${GITHUB_WORKSPACE}/test-${BUILD_ID}/.orodc"
export DC_ORO_NAME="myproject-${BUILD_ID}-${RANDOM}"

# ❌ WRONG - config outside workspace
export DC_ORO_CONFIG_DIR="/tmp/.orodc"  # Docker mounting fails!
```

### Recommended Project Structure
```
my-oro-project/
├── .orodc/                  # OroDC configuration & data
│   ├── docker-compose.yml   # Generated Docker configuration
│   ├── ssh_id_ed25519       # SSH keys for remote mode
│   └── .cached_profiles     # Cached Docker profiles
├── src/                     # Oro application sources
├── vendor/                  # Composer dependencies
├── .env.orodc              # OroDC environment variables
└── .gitignore              # Add .orodc/ if you don't want to version control it
```

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

## Containerized Testing

### DC_ORO_MODE Configuration for Different Environments

#### Local Development
```bash
# Linux/WSL2 (fastest)
echo "DC_ORO_MODE=default" >> .env.orodc

# macOS (avoid slow Docker filesystem)  
echo "DC_ORO_MODE=mutagen" >> .env.orodc
brew install mutagen-io/mutagen/mutagen
```

#### Containerized Environments (CI/CD)
**RECOMMENDED: Use project-local config directory with default mode**

```bash
# Modern approach (recommended)
export DC_ORO_CONFIG_DIR="$(pwd)/.orodc"
echo "DC_ORO_MODE=default" >> .env.orodc
```

**Benefits of project-local config:**
- ✅ **No volume mounting complexity**: Config lives alongside project sources
- ✅ **Docker-in-Docker compatible**: Works in nested container scenarios  
- ✅ **Zero git conflicts**: No workspace interference with checkout operations
- ✅ **Better isolation**: Each test gets completely separate OroDC instance
- ✅ **Portable**: Config travels with project code

#### Legacy: SSH Mode for Docker-in-Docker (deprecated)
```bash
# Only use if project-local config doesn't work
echo "DC_ORO_MODE=ssh" >> .env.orodc
```

**When SSH mode was needed:**
- **Docker-in-Docker limitation**: bind mount volumes from nested containers didn't work properly
- **Volume isolation**: SSH mode bypassed filesystem mount issues in nested Docker environments

**Why project-local config is better:**
- Eliminates need for SSH mode complexity
- Faster setup and execution  
- No SSH key management required
- Works reliably in all containerized environments

## Code Quality Tools

### Linting and Validation
Always validate code changes before committing:

#### **1. Dockerfile Linting with Hadolint**
```bash
# Using Docker (recommended)
docker run --rm -i hadolint/hadolint < compose/docker/php/Dockerfile.8.5.alpine

# Install locally
brew install hadolint
hadolint compose/docker/php/Dockerfile.8.5.alpine
```

**Common Hadolint Rules:**
- `DL3018`: Pin package versions in `apk add` 
- `DL4006`: Set `SHELL -o pipefail` for pipes in RUN
- `DL3047`: Use `wget --progress=dot:giga` for progress

#### **2. GitHub Actions Validation**
```bash
# Install actionlint
brew install actionlint

# Validate workflow files
actionlint .github/workflows/*.yml
```

#### **3. YAML Validation**
```bash
# Using yq (already in dependencies)
yq eval '.github/workflows/test-oro-installations-containerized.yml' > /dev/null

# Using yamllint
pip install yamllint
yamllint .github/workflows/
```

#### **4. Bash/Shell Script Validation**
```bash
# Install ShellCheck
brew install shellcheck

# Validate shell scripts
shellcheck bin/orodc
shellcheck .github/scripts/*.sh
```

#### **5. Automated Pre-commit Validation**
Create `.pre-commit-config.yaml`:
```yaml
repos:
  - repo: https://github.com/hadolint/hadolint
    rev: v2.12.0
    hooks:
      - id: hadolint-docker
  - repo: https://github.com/koalaman/shellcheck-precommit
    rev: v0.9.0
    hooks:
      - id: shellcheck
  - repo: https://github.com/adrienverge/yamllint.git
    rev: v1.32.0
    hooks:
      - id: yamllint
```

**Installation:**
```bash
pip install pre-commit
pre-commit install
```

### **Quality Guidelines:**
- **Always lint Dockerfiles** before Docker image changes
- **Validate YAML syntax** before workflow modifications  
- **Check shell scripts** for common issues and security
- **Run actionlint** before GitHub Actions changes
- **Use consistent formatting** across all file types

### **CI/CD Integration:**
Add linting steps to workflows:
```yaml
- name: Lint Dockerfiles
  run: |
    docker run --rm -i hadolint/hadolint < compose/docker/php/Dockerfile.8.5.alpine
    
- name: Lint Shell Scripts
  run: shellcheck bin/orodc .github/scripts/*.sh
  
- name: Validate YAML
  run: yamllint .github/workflows/
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
