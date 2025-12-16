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

This document contains ONLY instructions for AI agents working with homebrew-docker-compose-oroplatform.

**For project documentation, workflows, and commands:** See [DEVELOPMENT.md](DEVELOPMENT.md)
**For project context and architecture:** See [openspec/project.md](openspec/project.md)

---

# 🔴🔴🔴 **CRITICAL: "NEW BRANCH" ALWAYS MEANS FROM UPSTREAM!**

## ⚠️ **AFTER CREATING ANY BRANCH - ALWAYS CHECK MERGE CONFLICTS!**

**After creating and pushing ANY new branch:**

1. **ALWAYS verify it can auto-merge into master:**
   ```bash
   git fetch origin
   # Check if branch needs rebase
   git merge-base origin/master HEAD
   ```

2. **If branch is NOT cleanly based on latest master:**
   ```bash
   # Immediately rebase on master
   git rebase origin/master
   # Resolve conflicts
   git push origin <branch-name> --force-with-lease
   ```

3. **WHY THIS MATTERS:**
   - User sees "Can't automatically merge" on GitHub
   - User has to manually ask to fix it EVERY TIME
   - Wastes time and creates friction
   - **PREVENT THIS** by ensuring clean rebase before final push

**RULE:** Never leave a branch with merge conflicts. Always test merge-ability.

---

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

# 🔴 **CRITICAL: NEVER MODIFY USER FILES WITHOUT PERMISSION!**

## ⚡ **MANDATORY RULE: RESPECT USER ENVIRONMENT BOUNDARIES!**

**🚨 NEVER MODIFY FILES OUTSIDE PROJECT WITHOUT EXPLICIT USER PERMISSION:**

**⛔ FORBIDDEN WITHOUT PERMISSION:**
- ❌ User home directory files (~/.zshrc, ~/.bashrc, ~/.profile)
- ❌ User config files outside project (~/.config/*, ~/.env, etc.)
- ❌ Project-specific user files (project/.env.orodc, project/config.local.yml)
- ❌ System files (/etc/*)
- ❌ Any file outside current git repository

**✅ ALLOWED WITHOUT ASKING:**
- ✅ Files within current git repository (tracked by git)
- ✅ Temporary files in project directory for demonstration
- ✅ Files explicitly mentioned by user as targets

**💡 WHEN USER NEEDS EXTERNAL FILE CHANGES:**
- 🗣️ Show the commands user should run
- 📋 Provide instructions to copy-paste
- ⚠️ Explain what changes are needed and why
- 🚫 NEVER execute the changes yourself

**EXAMPLE - CORRECT APPROACH:**
```bash
# ❌ WRONG: Modifying user file directly
echo "export VAR=value" >> ~/.zshrc

# ✅ CORRECT: Show user what to add
# User should add to ~/.zshrc:
# export VAR=value
```

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

# 🚫 **CRITICAL: NEVER PUSH DIRECTLY TO MASTER/MAIN!**

**⛔ ABSOLUTELY FORBIDDEN:**
```bash
# NEVER DO THIS! NEVER!
git checkout master
git merge some-branch
git push origin master     # ❌ FORBIDDEN!
```

**✅ ALWAYS USE PULL REQUESTS:**
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

---

# 🔴 **CRITICAL: NEW CHANGES AFTER PUSH**

**⛔ NEVER add new changes to already pushed branches!**

If you've already pushed a branch and want to add MORE changes:

**✅ CORRECT:**
```bash
# 1. Update from upstream first
git fetch --all
git checkout master
git pull main master
git push origin master

# 2. Create NEW branch for additional changes
git checkout -b fix/additional-improvements
# Make new changes
git commit -m "Additional improvements"
git push -u origin fix/additional-improvements
```

**❌ WRONG:**
```bash
git checkout existing-pushed-branch
# make changes
git commit -m "more changes" 
git push  # ❌ This creates messy history!
```

**Exception:** Only add to pushed branches if explicitly fixing issues in the SAME Pull Request discussion.

---

# 🚨 **CRITICAL: WHEN USER SAYS "I MERGED"**

**⚡ IMMEDIATE ACTION REQUIRED:**
When user says **"я смерджил"** (I merged) or **"смерджил"** or **"merged"**:

**✅ CORRECT workflow:**
```bash
# 1. Sync with upstream
git fetch --all
git checkout master
git pull main master
git push origin master

# 2. Create NEW branch for new work
git checkout -b feature/next-improvements
```

**❌ WRONG: Continue in merged branch**
```bash
git commit -m "more changes"  # ❌ NEVER after merge!
```

---

# 🔴 **IMPORTANT: WHEN USER SAYS "VERSION"**

**💡 90% of the time this refers to the Homebrew Formula version!**

When the user mentions:
- "про версию" (about version)
- "обновляй версию" (update version)
- "версию" (version)
- "version"

**Default Action:** Update version in `Formula/docker-compose-oroplatform.rb`

**File location:** `Formula/docker-compose-oroplatform.rb`
**Line to update:** `version "X.Y.Z"`

**Only 10% of cases** might refer to:
- Docker image versions
- PHP/Node versions
- Dependency versions

**When in doubt, ASK:** "Do you mean the Homebrew formula version?"

---

## 🔴 **IMPORTANT: When User Says "Version" or "About Version"**

**💡 90% of the time this refers to the Homebrew Formula version!**

When the user mentions:
- "про версию" (about version)
- "обновляй версию" (update version)
- "версию" (version)
- "version"

**Default Action:** Update the version in `Formula/docker-compose-oroplatform.rb`

**File location:** `Formula/docker-compose-oroplatform.rb`
**Line to update:** `version "X.Y.Z"`

**Only 10% of cases** might refer to:
- Docker image versions
- PHP/Node versions
- Dependency versions

**When in doubt, ASK:** "Do you mean the Homebrew formula version?"

# 📦 **FORMULA VERSIONING**

```ruby
# Before (in Formula/docker-compose-oroplatform.rb)
version "0.8.6"

# After - Bug fix (patch)
version "0.8.7"

# After - New feature (minor)
version "0.9.0"

# After - Breaking change (major)
version "1.0.0"
```

### ⚠️ **CRITICAL: Version Update is Mandatory!**

- **ALWAYS** update version before committing changes to `compose/` or `bin/`
- **NEVER** commit without version increment when modifying core functionality
- Version updates ensure proper Homebrew package management

---

# 🎯 **BRANCH NAMING RULES**

- `feature/short-description` - new features
- `fix/issue-description` - bug fixes  
- `update/component-name` - version/config updates
- `docs/topic` - documentation
- `refactor/component` - refactoring

### 💡 Examples:
- `update/oro-workflow-versions`
- `fix/yaml-syntax-errors`  
- `feature/php-auto-detection`
- `docs/installation-guide`

---

## 🔴 **IMPORTANT: When User Says "Version" or "About Version"**

**💡 90% of the time this refers to the Homebrew Formula version!**

When the user mentions:
- "про версию" (about version)
- "обновляй версию" (update version)
- "версию" (version)
- "version"

**Default Action:** Update the version in `Formula/docker-compose-oroplatform.rb`

**File location:** `Formula/docker-compose-oroplatform.rb`
**Line to update:** `version "X.Y.Z"`

**Only 10% of cases** might refer to:
- Docker image versions
- PHP/Node versions
- Dependency versions

**When in doubt, ASK:** "Do you mean the Homebrew formula version?"

---

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

# 📋 **AI AGENT RESPONSE GUIDELINES**

## Always Include:
- Complete workflows, not isolated commands
- OS-specific considerations
- Performance implications
- Error context when troubleshooting

## Never Suggest:
- `cli` prefix for PHP commands (OroDC auto-detects)
- `default` mode on macOS (extremely slow)
- Commands without setup context
- Incomplete workflows
- `[[ -n "${DEBUG:-}" ]]` syntax (breaks with `set -e`)
- Emojis in terminal commands or output
- Shell syntax that isn't zsh compatible

## Ask User For:
- Operating system
- Current sync mode
- Error messages
- Output of `orodc ps`

## When User Needs Help:
- **Commands/workflows**: Refer to [DEVELOPMENT.md](DEVELOPMENT.md)
- **Architecture/context**: Refer to [openspec/project.md](openspec/project.md)
- **Testing methods**: Refer to [LOCAL-TESTING.md](LOCAL-TESTING.md)
- **Test environment**: Suggest using `~/oroplatform` test project

## Repository Management (CRITICAL):
- **ALWAYS** merge/pull ONLY from remote repositories (origin, main, upstream)
- **NEVER** suggest merging local branches unless explicitly requested
- Default workflow: `git pull --rebase origin master` or `git rebase master` after updating from remote
- When updating branches: always sync with remote first, then rebase feature branches
- Exception: Only merge local branches if user explicitly asks

## Fork vs Upstream Remotes (CRITICAL):
- **origin = your fork** (where you push branches)
- **main = upstream repository** (where PR base branches live)
- **Upstream base branch name is `master`** (remote ref: `main/master`)

**If GitHub PR says "Can’t automatically merge":** you must test against **upstream base**, not your fork:

```bash
# Update remotes
git fetch origin
git fetch main

# On your PR branch:
git checkout <your-pr-branch>
git merge --no-ff --no-commit main/master   # reproduce real PR conflicts locally

# Resolve conflicts, then:
git add -A
git commit
git push origin <your-pr-branch>
```

**Rule:** Checking `origin/master` or `origin/main` is NOT sufficient for mergeability into upstream. Always check `main/master`.

---

# 🔧 **PROJECT-SPECIFIC RULES**

## OroDC Command Detection
OroDC **automatically detects** PHP commands:

```bash
# ✅ CORRECT - OroDC auto-detects
orodc --version          # → cli php --version
orodc bin/console cache:clear
orodc script.php

# ❌ WRONG - Redundant cli prefix
orodc cli php --version
```

## Shell Compatibility (CRITICAL)
**All commands MUST be zsh compatible:**

```bash
# ✅ CORRECT - Works in bash and zsh
echo "DC_ORO_MODE=mutagen" >> .env.orodc

# ❌ WRONG - Quote escaping issues in zsh
echo 'DC_ORO_MODE="mutagen"' >> .env.orodc
```

## Terminal Output Rules
- **NEVER use emojis** in commands/output
- **NEVER use Unicode symbols**
- Use plain ASCII: `[OK]`, `[ERROR]`, `[INFO]`

```bash
# ✅ CORRECT
echo "[OK] Installation completed"

# ❌ WRONG  
echo "✅ Installation completed"
```

## Sync Mode Recommendations
| OS | Mode | Never Suggest |
|----|------|--------------|
| Linux/WSL2 | `default` | - |
| macOS | `mutagen` | NEVER suggest `default` |
| Remote | `ssh` | - |

## When User Needs Test Environment
- Suggest `~/oroplatform` test project
- If doesn't exist, offer to clone community OroPlatform
- Always prefer `~/oroplatform` for consistent testing
- Refer to [LOCAL-TESTING.md](LOCAL-TESTING.md) for detailed methods

---

# 📚 **DOCUMENTATION REFERENCES**

**For AI agents (this file):**
- Git workflow rules
- Response guidelines
- Critical constraints

**For users and development info:**
- [DEVELOPMENT.md](DEVELOPMENT.md) - Commands, workflows, troubleshooting
- [openspec/project.md](openspec/project.md) - Architecture, context, tech stack
- [LOCAL-TESTING.md](LOCAL-TESTING.md) - Testing methods and procedures

**Always refer users to appropriate documentation instead of repeating content in responses.**

---

**Remember: Branch first, version first, commit later! Never push to master!** 📦🌳
