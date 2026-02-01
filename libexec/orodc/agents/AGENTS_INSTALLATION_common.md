# Common Installation Guide

**This guide describes how to create a new OroDC project from scratch (empty directory).**

---

## ⚠️ UNIVERSAL INSTALLATION RULES (Apply to ALL CMS Types)

**🔴 These rules apply to EVERY CMS installation (Magento, Oro, Symfony, Laravel, etc.):**

### 1. Demo/Sample Data Rule
- **If user requests "demo data", "sample data", "test products", "with demo"** → YOU MUST install demo data
- Each CMS has its own method for demo data installation - check CMS-specific guide
- **DO NOT skip demo data when user explicitly requests it**

### 2. Frontend/Assets Build Rule
- **Most CMSes require a frontend build step** - this compiles CSS, JavaScript, and other assets
- **This step is usually CRITICAL** - frontend will not work without it
- Common names: "static content deployment" (Magento), "assets build" (Oro), "npm run build" (modern frameworks)
- **DO NOT skip frontend build steps**

### 3. Cache Operations Rule
- **Always clear and warm up cache after installation**
- Most CMSes have cache:clear or similar commands
- Cache operations should be done AFTER installation and frontend build

### 4. Step Order Rule
- **Follow the EXACT order specified in the CMS-specific installation guide**
- Wrong order can cause failures (e.g., building frontend before installing dependencies)
- If unsure, read the full guide first, then execute in order

### 5. Never Skip CRITICAL Steps Rule
- **Steps marked as CRITICAL, REQUIRED, or 🔴 must ALWAYS be executed**
- These steps are essential for the application to work
- Skipping them will result in broken functionality

---

## Prerequisites

- OroDC must be installed: `brew install digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform`
- Docker must be running
- Empty project directory (or directory with only `.git` if using version control)
- **IMPORTANT**: User must run `orodc init` manually in terminal BEFORE using `orodc codex` agent

## Step-by-Step Installation Process

### 1. Navigate to Project Directory

```bash
cd /path/to/project/directory
```

### 2. Initialize OroDC Environment

**REQUIRED**: Run `orodc init` to configure the OroDC Docker environment:

```bash
orodc init
```

**IMPORTANT**: 
- `orodc init` must be executed by user manually in terminal BEFORE launching `orodc codex`
- `orodc init` is NOT interactive - it requires user to run it manually
- This command will:
  - Detect PHP, Node.js, Composer versions
  - Configure database (PostgreSQL/MySQL)
  - Configure search engine (Elasticsearch/OpenSearch)
  - Configure cache (Redis/Valkey/KeyDB)
  - Configure RabbitMQ
  - Optionally set CMS type

**Important**: This configures the Docker environment, NOT the project codebase itself.

### 3. Start Docker Containers

**REQUIRED**: Start containers before creating project codebase:

```bash
orodc up -d
```

**IMPORTANT**: 
- Nothing starts automatically - you MUST run `orodc up -d` explicitly
- Run `orodc agents common` for detailed explanation of environment workflow

### 4. Verify Containers Are Running

Check container status:

```bash
orodc ps
```

All containers should show "Running" status before proceeding.

### 5. Verify Directory is Empty

**REQUIRED**: Check that directory is empty (or contains only `.git` if using version control):

```bash
# Check directory contents
ls -la
# Should show only .git (if version control) or be empty
```

**IMPORTANT**: Project creation commands (`orodc exec composer create-project` or `orodc exec git clone`) MUST be run in an empty directory.

### 6. Create Project Codebase

**This step is CMS-specific** - run `orodc agents installation` to see detailed instructions for your CMS type.

**To get CMS-specific installation guide:**
```bash
# Auto-detect CMS type and show appropriate guide
orodc agents installation

# Or specify CMS type explicitly
orodc agents installation <cms-type>
```

**IMPORTANT**: 
- Always use `orodc exec` prefix for all commands that create project files
- For composer projects: use `orodc exec composer create-project`
- For git clones: use `orodc exec git clone`
- **Follow ALL steps from the CMS-specific installation guide**
- **Apply UNIVERSAL RULES** (see top of this document):
  - Install demo data if user requested
  - Complete frontend/assets build step
  - Clear/warm cache after installation
  - Follow exact step order from guide

### 7. Verify Installation

After project creation:
- Check application URL: `https://{project_name}.docker.local`
- Verify containers are still running: `orodc ps`
- Check application logs if needed: `orodc compose logs`

## Important Notes

### 🔴 CRITICAL - Universal Rules Reminder:

These rules apply to **ALL CMS installations** - always follow them:
1. **Demo data**: Install if user requested ("demo", "sample data", "test products")
2. **Frontend build**: Complete frontend/assets build step (CRITICAL for most CMSes)
3. **Cache operations**: Clear/warm cache after installation
4. **Step order**: Follow exact order from CMS-specific guide
5. **Never skip CRITICAL steps**: Steps marked CRITICAL/REQUIRED must be executed

### General Notes:

- **Environment vs Project**: `orodc init` initializes the Docker environment, not the project codebase
- **Containers must be running**: Always run `orodc up -d` before creating project codebase
- **Check status**: Use `orodc ps` to verify containers are running before executing commands
- **Environment variables**: Use `orodc exec env | grep ORO_` to get all OroDC service connection variables (database, cache, search, message queue, etc.)
- **CMS-specific guide**: Always run `orodc agents installation` for complete CMS-specific instructions

## Admin Account Creation

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

## Troubleshooting

- **Containers not starting**: Check Docker is running, check logs with `orodc compose logs`
- **Port conflicts**: Check if ports are already in use, modify in `.env.orodc` if needed
- **Permission issues**: Ensure Docker has proper permissions
