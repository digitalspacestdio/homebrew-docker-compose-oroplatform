<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

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

```bash
shellcheck script.sh
bash -n script.sh
```

No Bash changes without shellcheck.

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

## 8. Version Update Required

Update `Formula/docker-compose-oroplatform.rb` before committing changes to `compose/` or `bin/`.

## 9. Reinstall After Changes

```bash
brew reinstall digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform
```

After modifying `libexec/` or `compose/` files.

## 10. Start Analysis with Router

Always check `bin/orodc` first before analyzing individual scripts.

---

# OroDC Quick Reference

## Commands Auto-Detection

```bash
# ✅ CORRECT - auto-detects PHP
orodc --version
orodc bin/console cache:clear

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

**Remember: Commit locally, ask before push!**
