# Common OroDC Project Instructions

**This file contains common instructions applicable to all OroDC projects.**

**Key Commands:**
- PHP commands: `orodc exec php <command>`
- Composer: `orodc exec composer <command>`
- Custom scripts: `orodc exec <script-path>`

**Common Tasks:**
- Install dependencies: `orodc exec composer install`
- Update dependencies: `orodc exec composer update`
- Run PHP scripts: `orodc exec php <script.php>`

**Project Structure:**
- Project code is in: `${DC_ORO_APPDIR:-project directory}`
- Configuration files: `.env.orodc` (local) or `~/.orodc/{project_name}/.env.orodc` (global)
- Docker configuration: `${DC_ORO_CONFIG_DIR}`

**Environment Variables:**
- **Primary command**: Use `orodc exec env | grep ORO_` to get all OroDC service connection variables
  - This command shows all environment variables with `ORO_` prefix containing service access credentials
  - Variables include: database, cache, search, message queue, and other service connection details
- Use `orodc exec env` to see all environment variables inside containers
- Variables contain service connection details (database, cache, search, etc.)
- Trust these variables - they reflect actual configured services

**Environment Workflow:**
- `orodc init` is a one-time setup done by user to configure environment (Docker configuration)
  - User runs `orodc init` once to set up PHP version, database, cache, search engine, etc.
  - This creates configuration files but does NOT start containers
- After environment is configured, containers must be started with `orodc up -d` before any work
  - Without running containers, application and services (database, cache, search, etc.) will not work
  - Only CLI commands may work without containers, but application functionality requires running containers
  - Application URLs, database connections, and all services need containers to be running

**Project Status:**
- **FIRST COMMAND**: Always run `orodc status` at the beginning to understand project state
  - Shows initialization status, CMS type, and codebase presence
  - Does NOT require containers to be running (read-only command)
  - Use `orodc status` to quickly understand project state before starting work

**Checking Project Files:**
- **IMPORTANT**: Checking if project files exist does NOT require containers to be running
- Use standard file system commands (NOT `orodc exec`):
  - `ls -la` or `ls` - list directory contents
  - `test -f composer.json` - check if file exists
  - `find . -maxdepth 1 -type f` - find files in current directory
  - `[ -f composer.json ]` - bash file existence check
- These commands work directly on the host filesystem, no containers needed
- Only use `orodc exec` when you need to run commands INSIDE containers (after containers are running)

**Container Management:**
- Check container status: `orodc ps` (check if containers are running)
- Start containers: `orodc up -d` (ONLY run if containers are not running AND you need to work with the project)
- Stop containers: `orodc down`
- View logs: `orodc compose logs`

**When to run `orodc up -d`:**
- **ONLY** when:
  1. Project codebase already exists (files are present)
  2. AND containers are not running (check with `orodc ps`)
  3. AND you need to execute commands inside containers (`orodc exec`, `orodc cli`, etc.)
  4. OR you need to access application URLs or services (database, cache, etc.)
- **DO NOT** run `orodc up -d` just to check if project files exist - use file system commands instead
- **DO NOT** run `orodc up -d` before understanding project status - first run `orodc status` and check files

**Coding Rules:**
- Run `orodc agents rules` to see general coding guidelines and CMS-specific coding rules

**Installation Guides:**
- **🔴 CRITICAL**: Before starting ANY new project installation, run the installation guide:
  ```bash
  orodc agents installation
  ```
- This command auto-detects CMS type and shows the appropriate installation guide
- Or specify CMS type explicitly: `orodc agents installation <cms-type>`
- **IMPORTANT**: If project directory is empty, ALWAYS read and follow ALL steps from installation guide
- **🚨 DO NOT skip any steps marked as CRITICAL or REQUIRED in the installation guide**

**Universal Installation Rules (apply to ALL CMS types):**
1. **Demo/Sample Data**: If user requests "demo data", "sample data", or "test products" → you MUST install demo data using CMS-specific method
2. **Frontend/Assets Build**: Most CMSes require a frontend build step (static content, assets, webpack, etc.) - this is usually CRITICAL and must NOT be skipped
3. **Cache Operations**: Always clear/warm cache after installation
4. **Step Order**: Follow the exact order specified in the installation guide
5. **Never Skip CRITICAL Steps**: Steps marked as CRITICAL or REQUIRED must always be executed

**Temporary Files:**
- **CRITICAL**: All temporary files MUST be created ONLY in `/tmp/` directory
- NEVER create temporary files in the project directory
- Temporary files include: logs, dumps, test outputs, intermediate files, etc.
- Only create files in project directory if they are part of the actual project codebase

**Admin Account Creation:**
- **CRITICAL**: When installation requires admin account data (name, surname, email, username, password), NEVER ask user to provide this information
- **ALWAYS** offer to generate admin credentials automatically instead of requesting them from user
- Generate realistic but secure credentials:
  - Name: "Admin" or "Administrator"
  - Surname: "User" or "Account"
  - Email: "admin@{project_name}.local" or "admin@example.com"
  - Username: "admin" or "administrator"
  - Password: Generate secure random password (12+ characters, mix of letters, numbers, symbols)
- Present generated credentials to user BEFORE using them, allowing user to modify if needed
- Example: "I can generate admin credentials for you. Would you like me to proceed with: Name: Admin, Surname: User, Email: admin@{project_name}.local, Username: admin, Password: [generated secure password]?"
