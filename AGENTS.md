
# AI Agents Guidelines

Instructions for AI agents working with homebrew-docker-compose-oroplatform.

## Quick Links

| Topic | File |
|-------|------|
| Git workflow | [openspec/agents/git-workflow.md](openspec/agents/git-workflow.md) |
| OroDC rules | [openspec/agents/orodc-rules.md](openspec/agents/orodc-rules.md) |
| Code quality | [openspec/agents/code-quality.md](openspec/agents/code-quality.md) |
| Binary structure | [openspec/agents/binary-structure.md](openspec/agents/binary-structure.md) |
| Development docs | [DEVELOPMENT.md](DEVELOPMENT.md) |
| Architecture | [openspec/project.md](openspec/project.md) |
| Testing | [LOCAL-TESTING.md](LOCAL-TESTING.md) |

---

# 🔴 CRITICAL RULES

## 0. Always Start with Documentation

**MANDATORY:** Before implementing any feature or fixing any issue, **ALWAYS** read relevant documentation first:

1. **Project Architecture**: Read `openspec/project.md` to understand:
   - Configuration file locations (`.env.orodc`, `DC_ORO_CONFIG_DIR`)
   - Project structure and conventions
   - Where user data should be stored
   - What files can be created/modified

2. **Development Guidelines**: Check `DEVELOPMENT.md` for:
   - Command usage patterns
   - Workflow conventions
   - Testing procedures

3. **OpenSpec**: Check `openspec/AGENTS.md` for:
   - Project-specific rules
   - Architecture decisions
   - Change proposal process

**Why this matters:**
- Prevents creating files/directories in wrong locations
- Ensures compliance with project conventions
- Avoids breaking existing workflows
- Respects user's project structure

**Example:** Before saving domain replacement settings, check `openspec/project.md` to see that configuration should go in `.env.orodc`, not in custom directories.

## 1. Never Push Without User Confirmation

- ❌ Push branches without user explicitly asking
- ❌ Auto-push as part of "fix" or "implement" workflow
- ✅ Commit locally, then **ASK**: "Push to remote?"
- ✅ Push only if user says: "push", "create PR", "запушь"

## 2. New Task = New Branch

```bash
git fetch --all
git checkout master
git pull main master
git push origin master
git checkout -b fix/descriptive-task-name
```

## 3. Never Push to Master

- ❌ `git push origin master`
- ✅ Push to feature branch, create PR

## 4. Never Reset - Use Stash

- ❌ `git reset --hard`
- ✅ `git stash push -m "description"`

## 5. Never Modify User Files

- ❌ `~/.zshrc`, `~/.bashrc`, `/etc/*`
- ✅ Show user what to add manually

## 6. Shellcheck is Mandatory

**ALWAYS run shellcheck before committing ANY bash script changes:**

```bash
# 1. Check syntax first
bash -n script.sh

# 2. Run shellcheck (fix ALL warnings except SC1091)
shellcheck script.sh

# 3. Fix warnings and verify again
shellcheck script.sh

# 4. Only then commit
```

**MANDATORY workflow:**
- ✅ **MUST** run `shellcheck` on ALL `.sh` files you modify
- ✅ **MUST** run `bash -n script.sh` to check syntax
- ✅ **MUST** fix ALL warnings (except SC1091 - source file not found)
- ✅ **MUST NOT** commit without shellcheck passing

**See detailed rules:** `openspec/agents/code-quality.md`

No Bash changes without shellcheck!

**CRITICAL: `local` keyword can ONLY be used inside functions!**
- ❌ `local var="value"` in main script body → causes "local can only be used in a function" error
- ✅ `var="value"` in main script body
- ✅ `local var="value"` inside function body

## 7. Never Bloat bin/orodc - Use Modular Architecture

**CRITICAL:** `bin/orodc` is the router - keep it thin!

- ❌ Add large functions (>20 lines) directly to `bin/orodc`
- ❌ Add business logic to router
- ✅ Create new files in `libexec/orodc/lib/` for shared logic
- ✅ Create new files in `libexec/orodc/` for commands
- ✅ Keep `bin/orodc` focused on routing and initialization

**Modular architecture:**
```
bin/orodc                    # Router only (~3000 lines max)
libexec/orodc/
  ├── lib/
  │   ├── common.sh         # Utilities, logging
  │   ├── ui.sh             # UI messages, colors
  │   ├── environment.sh    # Environment initialization
  │   ├── validation.sh     # Project validation
  │   └── docker-utils.sh   # Docker helpers
  ├── ssh.sh                # SSH command
  ├── init.sh               # Init command
  └── database/
      └── import.sh         # Database import
```

**When adding new functionality:**
1. Create new file in appropriate location
2. Source it in `bin/orodc` or command script
3. Keep functions focused and testable

## 8. Fix Root Cause, Not Symptoms

- ❌ Add fallbacks that hide problems
- ✅ Investigate WHY something doesn't work

## 9. Version Update Required

Update `Formula/docker-compose-oroplatform.rb` before committing changes to `compose/` or `bin/`.

## 10. Reinstall After Changes

```bash
brew reinstall digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform
```

After modifying `libexec/` or `compose/` files.

## 11. Start Analysis with Router

Always check `bin/orodc` first before analyzing individual scripts.

## 12. Do Not Show Initiative

**CRITICAL:** Do not make changes beyond what the user explicitly asks for.

- ❌ Making additional "improvements" or "fixes" not requested
- ❌ Removing code "because it seems unnecessary" without user asking
- ❌ Refactoring or optimizing beyond the specific request
- ✅ Do exactly what is asked, nothing more
- ✅ If you see potential issues, ask the user first before fixing

**Example:** If user asks to fix a bug, fix ONLY that bug. Do not "also remove unused code" or "also optimize this function" unless explicitly requested.

## 13. Questions Require Answers, Not Code Changes

**CRITICAL:** If the user asks a question, they want an ANSWER, not code modifications.

- ❌ Changing code when user asks "why does X happen?" or "where is Y?"
- ❌ Making "fixes" when user asks "what is this?" or "how does this work?"
- ✅ Answer the question with explanation, code references, or documentation
- ✅ Only modify code if user explicitly asks to "fix", "change", "implement", etc.

**Examples:**
- User: "откуда у нас это?" → ✅ Explain where it comes from, ❌ Don't remove it
- User: "почему это происходит?" → ✅ Explain the reason, ❌ Don't "fix" it
- User: "где находится конфиг?" → ✅ Show the location, ❌ Don't move it

## 14. Docker Image Building

**CRITICAL:** Never manually build Docker images - use `orodc docker-build`!

### Image Build Commands

```bash
# List available images
orodc docker-build
orodc docker-build list

# Build specific images
orodc docker-build nginx        # Nginx web server
orodc docker-build mail         # Mailpit email catcher
orodc docker-build pgsql        # All PostgreSQL versions (15.1, 16.6, 17.4)
orodc docker-build pgsql 17.4   # Specific PostgreSQL version
orodc docker-build all          # Build all images

# Build options
orodc docker-build nginx --no-cache   # Build without cache
orodc docker-build nginx --push       # Push to GHCR after build
```

### PHP Images

PHP images use different command: `orodc image build` (interactive multi-stage builder)

```bash
orodc image build              # Interactive builder for PHP images
```

### Image Locations

| Image | Dockerfile | Build Context | Registry |
|-------|-----------|---------------|----------|
| Nginx | `compose/docker/nginx/Dockerfile` | `compose/docker/nginx/` | `ghcr.io/digitalspacestdio/orodc-nginx:latest` |
| Mail | `compose/docker/mail/Dockerfile` | `compose/docker/mail/` | `ghcr.io/digitalspacestdio/orodc-mail:latest` |
| PostgreSQL | `compose/docker/pgsql/Dockerfile` | `compose/docker/pgsql/` | `ghcr.io/digitalspacestdio/orodc-pgsql:VERSION` |
| PHP Base | `compose/docker/php/Dockerfile.X.X.alpine` | `compose/docker/php/` | `ghcr.io/digitalspacestdio/orodc-php:X.X-alpine` |
| PHP Final | `compose/docker/php-node-symfony/Dockerfile.X.X.alpine` | `compose/docker/php-node-symfony/` | `ghcr.io/digitalspacestdio/orodc-php-node-symfony:X.X-alpine` |

### When to Rebuild

**Rebuild required after modifying:**
- Nginx: `compose/docker/nginx/nginx-universal.conf`, `nginx-legacy.conf`, `entrypoint.sh`
- Mail: `compose/docker/mail/*`
- PostgreSQL: `compose/docker/pgsql/*`
- PHP: `compose/docker/php/**`, `compose/docker/php-node-symfony/**`

### Documentation

- **Detailed Docker docs**: `compose/docker/README.md` (multi-stage architecture, extensions, troubleshooting)
- **Image builder**: `libexec/orodc/docker-build.sh`
- **CI/CD workflows**: `.github/workflows/build-docker-*.yml`

---

# OroDC Quick Reference

OroDC supports **multiple CMS/frameworks**: Oro Platform (OroCommerce, OroCRM, OroPlatform, MarelloCommerce), Magento 2, Symfony, Laravel, WinterCMS, and generic PHP projects. The CMS type is auto-detected from `composer.json` or can be set via `DC_ORO_CMS_TYPE` in `.env.orodc`.

## Commands Auto-Detection

```bash
# ✅ CORRECT - auto-detects PHP
orodc --version
orodc bin/console cache:clear      # Oro/Symfony
orodc bin/magento cache:clean      # Magento

# ❌ WRONG - redundant cli
orodc cli php --version
```

## Sync Modes

| OS | Mode |
|----|------|
| Linux/WSL2 | `default` |
| macOS | `mutagen` (NEVER `default`) |

## Debug

```bash
DEBUG=1 orodc up -d
orodc config
```

---

# Response Guidelines

## Always Include
- Complete workflows
- OS-specific considerations
- Error context

## Never Suggest
- `cli` prefix for PHP commands
- `default` mode on macOS
- Emojis in terminal output
- `[[ -n "${DEBUG:-}" ]]` syntax

## Ask User For
- Operating system
- Error messages
- Output of `orodc ps`

---

# AI Agents and Proxy Integration

## Overview

OroDC provides integration with AI coding assistants (Codex, Gemini) through proxy commands (`orodc codex`, `orodc gemini`) and a dedicated command for accessing agent documentation (`orodc agents`).

## Architecture

### File Structure

```
libexec/orodc/
├── agents.sh              # Command handler for `orodc agents`
├── codex.sh               # Codex AI proxy integration
├── gemini.sh              # Gemini AI proxy integration
└── agents/                # Agent documentation files
    ├── AGENTS_common.md                    # Common instructions for all projects
    ├── AGENTS_oro.md                       # Oro Platform-specific instructions
    ├── AGENTS_magento.md                   # Magento-specific instructions
    ├── AGENTS_CODING_RULES_common.md       # Common coding rules
    ├── AGENTS_CODING_RULES_oro.md          # Oro-specific coding rules
    ├── AGENTS_INSTALLATION_common.md       # Common installation guide
    └── AGENTS_INSTALLATION_oro.md          # Oro-specific installation guide
```

### System Prompt Generation

When you run `orodc codex` or `orodc gemini`, the system:

1. **Detects CMS type** - Automatically detects project CMS type (oro, magento, laravel, etc.)
2. **Copies agent files** - Copies relevant agent documentation files to `~/.orodc/{project_name}/`
3. **Generates system prompt** - Creates `~/.orodc/{project_name}/AGENTS.md` with:
   - Common instructions (from `AGENTS_common.md`)
   - References to CMS-specific instructions via `orodc agents` commands
   - Project context (name, URL, directory)
   - Environment information
4. **Launches AI agent** - Starts Codex/Gemini with the generated system prompt

**Important:** The system prompt does NOT include full content of CMS-specific files. Instead, it references them via `orodc agents` commands, allowing agents to access documentation on-demand without exceeding token limits.

## Command: `orodc agents`

The `orodc agents` command provides access to agent documentation files.

### Usage

```bash
orodc agents <command> [cms-type]
```

### Commands

#### `orodc agents installation [cms-type]`

Shows installation guide combining common and CMS-specific steps.

**Logic:**
1. Checks if CMS-specific installation file exists
2. **Smart Common Detection:** Scans CMS-specific file for references to common part:
   - Looks for patterns like "common part", "orodc agents installation" (common), "complete steps...from...common"
3. **Conditional Display:**
   - If CMS file references common → Shows `AGENTS_INSTALLATION_common.md`, then separator `---`, then CMS-specific file
   - If CMS file is self-contained (no common references) → Shows only CMS-specific file
4. Auto-detects CMS type if not specified

**Examples:**
```bash
orodc agents installation          # Shows guide for detected CMS (with common if referenced)
orodc agents installation oro     # Shows Oro installation guide (with common if referenced)
orodc agents installation magento # Shows Magento installation guide (with common if referenced)
```

#### `orodc agents rules [cms-type]`

Shows coding rules combining common and CMS-specific guidelines.

**Logic:**
1. Checks if CMS-specific rules file exists
2. **Smart Common Detection:** Scans CMS-specific file for references to common:
   - Looks for patterns like "common", "see...common", "orodc agents rules...common"
3. **Conditional Display:**
   - If CMS file references common → Shows `AGENTS_CODING_RULES_common.md`, then separator `---`, then CMS-specific file
   - If CMS file is self-contained → Shows only CMS-specific file

**Examples:**
```bash
orodc agents rules                # Shows rules for detected CMS (with common if referenced)
orodc agents rules oro            # Shows Oro coding rules (with common if referenced)
```

#### `orodc agents common`

Shows common instructions applicable to all projects.

```bash
orodc agents common
```

#### `orodc agents <cms-type>`

Shows CMS-specific instructions.

**Available CMS types:** `oro`, `magento`, `laravel`, `symfony`, `wintercms`, `php-generic`

**Examples:**
```bash
orodc agents oro      # Shows Oro Platform-specific instructions
orodc agents magento   # Shows Magento-specific instructions
```

### Why Smart Common Detection?

Some CMS-specific files are **self-contained** and include all necessary information. Others **reference** common steps (like "Complete steps 1-4 from common part"). 

The smart detection ensures:
- **Self-contained files** are shown without redundant common content
- **Referencing files** get the common context they need
- **No duplication** of information
- **Flexible documentation** structure

## Proxy Commands: `orodc codex` and `orodc gemini`

### How They Work

1. **Environment Detection:**
   - Detects CMS type from project files or `.env.orodc`
   - Loads project configuration

2. **File Preparation:**
   - Copies agent files to `~/.orodc/{project_name}/`
   - Normalizes CMS type (e.g., `base` → `php-generic`)

3. **System Prompt Generation:**
   - Includes `AGENTS_common.md` content directly
   - References CMS-specific files via `orodc agents` commands:
     - `orodc agents {cms-type}` for CMS-specific instructions
     - `orodc agents rules` for coding rules
     - `orodc agents installation` for installation guides

4. **AI Agent Launch:**
   - Passes system prompt via `model_instructions_file` config
   - Sets working directory to project directory
   - Exports Docker and project context variables

### System Prompt Structure

The generated system prompt includes:

```
# COMMON INSTRUCTIONS
[Full content of AGENTS_common.md]

# CMS-SPECIFIC INSTRUCTIONS
**CMS Type:** {cms-type}

**For CMS-specific instructions, run:** `orodc agents {cms-type}`
- This command shows detailed instructions, commands, and best practices specific to {cms-type} projects

# CODING RULES
**For coding rules, run:** `orodc agents rules`
- This command shows general coding guidelines and CMS-specific coding rules

# INSTALLATION GUIDES
**For installation guides, run:** `orodc agents installation`
- This command shows common installation steps and CMS-specific installation steps
- It automatically combines AGENTS_INSTALLATION_common.md and AGENTS_INSTALLATION_{cms-type}.md
```

### Why References Instead of Full Content?

1. **Token Limits** - AI models have token limits; including all files would exceed them
2. **On-Demand Access** - Agents can access specific documentation when needed
3. **Modularity** - Documentation can be updated independently
4. **Flexibility** - Different agents can access different parts as needed

## Adding New CMS Support

To add support for a new CMS:

1. **Create CMS-specific files:**
   ```
   libexec/orodc/agents/
   ├── AGENTS_{cms-type}.md
   ├── AGENTS_CODING_RULES_{cms-type}.md
   └── AGENTS_INSTALLATION_{cms-type}.md
   ```

2. **Update `agents.sh`:**
   - Add CMS type to available types list in help output
   - Ensure CMS type normalization (if needed)

3. **Update system prompt generation:**
   - Files are automatically detected and included
   - No changes needed if following naming convention

4. **Test:**
   ```bash
   orodc agents {cms-type}
   orodc agents installation {cms-type}
   orodc agents rules {cms-type}
   ```

## Best Practices

### For Documentation Authors

1. **Self-contained files:** If your CMS-specific file includes all necessary information, don't reference common files
2. **Referencing files:** If your file builds on common steps, clearly reference them:
   - "Complete steps 1-4 from `orodc agents installation` (common part):"
   - "See `orodc agents rules` for general guidelines"

3. **Use commands, not file paths:** Always reference `orodc agents` commands, not file paths:
   - ✅ `orodc agents installation`
   - ❌ `AGENTS_INSTALLATION_common.md`

### For AI Agents

1. **Use `orodc agents` commands** to access documentation
2. **Check CMS type** before accessing CMS-specific documentation
3. **Follow installation guides** step-by-step when creating new projects
4. **Reference coding rules** when writing code

### 🔴 CRITICAL: CMS Installation Rule

**MANDATORY:** If user requests to **install**, **setup**, **deploy**, or **create** a CMS project (Magento, Oro, Symfony, Laravel, etc.), you **MUST**:

1. **FIRST**: Execute `orodc agents installation` (or `orodc agents installation <cms-type>`) to get the complete installation guide
2. **THEN**: Follow the installation guide **step-by-step** without skipping any steps
3. **NEVER** attempt installation without reading the guide first
4. **NEVER** skip steps marked as CRITICAL, REQUIRED, or 🔴
5. **ALWAYS** execute steps in the exact order specified in the guide

**Why this matters:**
- Installation guides contain critical steps that are easy to miss (e.g., OpenSearch configuration, static content deployment)
- Skipping steps can result in broken functionality (e.g., frontend without styles, search not working)
- Each CMS has specific requirements that are documented in the installation guide
- The guide includes proper order of operations (e.g., DI compile → cache → static content)

**Example workflow:**
```
User: "Install Magento"
Agent: [Executes] orodc agents installation magento
Agent: [Reads guide, then follows steps 1-11 in order]
```

**Common mistakes to avoid:**
- ❌ Starting installation without reading the guide
- ❌ Skipping "optional" steps that are actually required
- ❌ Changing the order of steps
- ❌ Assuming steps are already done without verifying

---

# ⚠️ Known Issues

## Docker Compose v5.0.0 + `--progress=plain` causes panic

**Problem:** Docker Compose v5.0.0 has a bug where using `--progress=plain` flag with `docker compose build` or `docker compose up` causes a Go runtime panic:

```
panic: runtime error: slice bounds out of range [1:0]
...
github.com/docker/compose/v5/pkg/compose.(*composeService).doBuildBake
```

**Impact:** Build commands fail silently when run with spinner (output redirected), showing "completed" but containers are not created.

**Workaround:** Do NOT use `--progress=plain` flag with Docker Compose v5.x. The flag was intended to disable TTY progress bars for proper spinner handling, but it triggers the bake panic.

**Status:** Bug in Docker Compose. Avoid `--progress=plain` until fixed upstream.

**Detection:** If `orodc up -d` shows "completed" but `orodc ps` shows no containers, run with `DEBUG=1 orodc up -d` to see the full error.

---

**Remember: Commit locally, ask before push!**
