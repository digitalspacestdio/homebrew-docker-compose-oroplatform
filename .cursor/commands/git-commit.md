---
name: /git-commit
id: git-commit
category: Git
description: Create a commit following project rules - update version, check branch, and commit with proper message.
---

**CRITICAL RULES:**
1. **NEVER commit to master/main** - Always work in feature/fix/update/docs/refactor branches
2. **MANDATORY**: Before creating ANY branch, sync with remote main first:
   ```bash
   git fetch --all
   git checkout master
   git pull main master    # Pull from upstream (main remote)
   git push origin master  # Update your fork
   ```
3. **MANDATORY**: All branches MUST be created from synced master/main:
   ```bash
   git checkout -b feature/descriptive-name
   # or fix/, update/, docs/, refactor/
   ```
4. **MANDATORY**: Update version in `Formula/docker-compose-oroplatform.rb` BEFORE committing
5. Use descriptive commit messages
6. Follow semantic versioning rules

**Steps:**
1. **Check current branch:**
   ```bash
   git branch --show-current
   ```
   - If on `master` or `main`: STOP and inform user - must create branch first (after syncing with remote main)
   - If branch name doesn't match pattern `feature/`, `fix/`, `update/`, `docs/`, `refactor/`: Warn user
   - If branch was created without syncing with remote main: Warn user and suggest recreating branch

2. **Update version in Formula (MANDATORY):**
   ```bash
   # Read current version from Formula/docker-compose-oroplatform.rb
   # Determine version bump type based on changes:
   # - Patch (X.Y.Z -> X.Y.Z+1): Bug fixes, typos, minor config changes
   # - Minor (X.Y.Z -> X.Y+1.0): New features, backwards compatible changes
   # - Major (X.Y.Z -> X+1.0.0): Breaking changes, major refactoring
   ```
   - Edit `Formula/docker-compose-oroplatform.rb`
   - Increment version according to semantic versioning
   - Show version change: `0.14.2 -> 0.14.3` (example)

3. **Stage changes:**
   ```bash
   git add .
   ```

4. **Create commit:**
   ```bash
   git commit -m "descriptive commit message"
   ```
   - Use clear, descriptive messages
   - Reference issue/ticket if applicable
   - Follow conventional commits format when possible (feat:, fix:, docs:, etc.)

5. **Verify commit:**
   ```bash
   git log -1 --stat
   ```
   - Confirm version was updated
   - Confirm all expected changes are included

**Version Bumping Guidelines:**
- **Patch** (0.14.2 → 0.14.3): Bug fixes, typos, minor config updates, documentation fixes
- **Minor** (0.14.2 → 0.15.0): New features, new capabilities, backwards compatible enhancements
- **Major** (0.14.2 → 1.0.0): Breaking changes, major refactoring, incompatible API changes

**Commit Message Examples:**
- `fix: resolve DNS resolution issue in containers`
- `feat: add DNS server configuration for all containers`
- `docs: update installation instructions`
- `update: bump PHP version to 8.4`
- `refactor: simplify docker-compose configuration`

**After Commit:**
- If user wants to push: Use `git push -u origin <branch-name>`
- Remind user to create Pull Request via GitHub (never push to master/main)

