# Oro Platform Installation Guide

**Complete step-by-step guide for creating a new Oro Platform project from scratch.**

---

## ⚠️ CRITICAL WARNINGS - READ BEFORE STARTING

**🔴 MANDATORY: Read this entire guide before starting installation!**

**🚨 UNIVERSAL RULES APPLY** (see `orodc agents installation` common part):
1. **Demo data**: If user requests demo data → use `--sample-data=y` in oro:install (Step 4)
2. **Frontend build**: Step 5 is MANDATORY (assets build)
3. **Step order**: Steps MUST be executed in order
4. **Never skip CRITICAL steps**: Steps marked 🔴 must always be executed
5. **🚨 NEVER SKIP STEPS - EVEN IF THEY SEEM ALREADY DONE**:
   - **CRITICAL**: You MUST execute ALL steps from the checklist, even if you think they are already completed
   - **DO NOT** skip steps because "containers are already running" or "files already exist" or "status shows running"
   - **DO NOT** make assumptions about what is already done - execute every step as written in the guide
   - **User permission required**: If you want to skip ANY step, you MUST ask user for explicit permission: "Step X says to do Y, but it seems already done. Should I skip it or execute it anyway?"

**Oro-specific critical steps:**
- **Step 4**: oro:install with `--sample-data=y` → if user requests demo data
- **Step 5**: Assets Build → ALWAYS REQUIRED (frontend build)

---

## Installation Checklist

**Use this checklist to track installation progress. Check off each step as you complete it.**

### Prerequisites Checklist

- [ ] Navigate to empty project directory
- [ ] Run `orodc init` manually in terminal (MUST be done by user BEFORE using agent)
- [ ] Run `orodc up -d`
- [ ] Verify containers are running with `orodc ps`

### Installation Steps Checklist

- [ ] Step 1: Verify directory is empty
- [ ] Step 2: Create Oro project (git clone or composer create-project)
- [ ] Step 3: Install dependencies (composer install)
- [ ] **Step 4: Install Oro Platform** - **🔴 Use `--sample-data=y` if user requests demo data**
- [ ] **Step 5: Build assets (frontend)** - **🔴 CRITICAL, ALWAYS REQUIRED**
- [ ] Step 6: Clear and warm up cache
- [ ] **Step 7: Ensure containers are running** - **🔴 REQUIRED - NEVER SKIP THIS STEP** (`orodc up -d` and `orodc ps`)

### Final Verification Checklist

- [ ] All containers are running (`orodc ps` shows "Running" status)
- [ ] Frontend is accessible: `https://{project_name}.docker.local`
- [ ] Admin panel is accessible: `https://{project_name}.docker.local/admin`
- [ ] Admin credentials are saved (generated during installation)
- [ ] **If demo data was requested**: Products and sample data are visible in admin

---

## Prerequisites

**🔴 REQUIRED**: Complete steps 1-4 from `orodc agents installation` (common part) BEFORE starting Oro installation:

1. **Navigate to empty project directory**
   ```bash
   cd /path/to/project/directory
   ```

2. **Run `orodc init` manually in terminal** (MUST be done by user BEFORE using agent)
   ```bash
   orodc init
   ```
   This configures the Docker environment (database, search engine, cache, etc.)

3. **Start Docker containers**
   ```bash
   orodc up -d
   ```
   **IMPORTANT**: Containers MUST be running before proceeding with project creation.

4. **Verify containers are running**
   ```bash
   orodc ps
   ```
   All containers should show "Running" status before proceeding.

**🚨 CRITICAL**: Do NOT proceed with Oro installation until all prerequisites are completed and containers are running.

## Installation Steps

**🔴 IMPORTANT: Execute steps in this exact order!**

**Quick reference for critical steps:**
- **Step 1**: Verify directory is empty
- **Step 2**: Create Oro project (git clone or composer create-project)
- **Step 3**: Install dependencies (composer install)
- **Step 4**: Install Oro Platform (use `--sample-data=y` if user requested demo data)
- **Step 5**: Build assets (CRITICAL - frontend will not work without this)
- **Step 6**: Clear and warm up cache
- **Step 7**: Ensure containers are running (final verification)

### Step 1: Verify Directory is Empty

**REQUIRED**: Ensure directory is empty (or contains only `.git`):

```bash
orodc exec ls -la
# Should show only .git (if version control) or be empty
```

**IMPORTANT**: Project creation commands MUST be run in an empty directory.

### Step 2: Create Oro Project

**REQUIRED**: Create the Oro project codebase. Choose one of the following methods:

**Why this is needed**: This step downloads/clones the Oro Platform application code into your project directory.

#### Method 1: Clone from GitHub (Recommended)

Oro projects can be cloned from GitHub repositories. This method supports both Community and Enterprise editions.

**Option A: OroCommerce**
```bash
orodc exec git clone --single-branch --branch 6.1.4 https://github.com/oroinc/orocommerce-application.git .
```
*Clones OroCommerce 6.1.4 from GitHub*

**Option B: OroPlatform**
```bash
orodc exec git clone --single-branch --branch 6.1 https://github.com/oroinc/platform-application.git .
```
*Clones OroPlatform 6.1 from GitHub*

**Option C: MarelloCommerce**
```bash
# Clone from Marello repository (check latest branch)
orodc exec git clone --single-branch --branch <version> <marello-repo-url> .
```
*Clones MarelloCommerce from repository (check latest version)*

**Note**: Git clone method allows you to specify exact version/branch and works for both CE and Enterprise editions.

#### Method 2: Create via Composer (CE Edition Only)

**IMPORTANT**: Composer create-project installs **Community Edition (CE)** only. For Enterprise Edition, use git clone method.

**OroCommerce CE:**
```bash
orodc exec composer create-project oro/commerce-application .
```

**OroPlatform CE:**
```bash
orodc exec composer create-project oro/platform-application .
```

**For Enterprise Edition**: Enterprise versions require access to private Oro repositories and cannot be installed via public composer create-project. Use git clone from your Enterprise repository or contact Oro support for Enterprise installation instructions.

**After project creation**: The project directory should contain Oro application files (app/, bin/, vendor/, etc.)

### Step 3: Install Dependencies

**REQUIRED**: Install PHP dependencies via Composer.

**Why this is needed**: Oro Platform requires PHP packages (dependencies) to be installed before installation. This step downloads and installs all required packages defined in `composer.json`.

**How to install**:

```bash
orodc exec composer install
```

**What this does**:
- Downloads all PHP dependencies defined in `composer.json`
- Installs packages into `vendor/` directory
- May take several minutes depending on internet speed and number of dependencies

**Important Notes**:
- This step must be done AFTER project creation (Step 2) and BEFORE Oro installation (Step 4)
- If `composer install` fails, check internet connection and composer authentication (if using private repositories)
- For Enterprise Edition, ensure you have access to private Oro repositories

### Step 4: Install Oro Platform

**🔴 REQUIRED**: Run Oro installation command. This step sets up the database, installs the application, and creates the admin account.

**🔴 CRITICAL - DEMO DATA DECISION:**
- **If user asks for "demo data", "sample data", "with demo", "test products"** → use `--sample-data=y`
- **If user does NOT mention demo data** → use `--sample-data=n`
- **🚨 DO NOT FORGET to set the correct --sample-data flag based on user request!**
- **🚨 DO NOT ask user about demo data** - use the flag based on what user requested in their original request

**Why this is needed**: This command initializes the Oro Platform application, creates database schema, installs initial data, and sets up the admin account.

**IMPORTANT**: Before running installation:
- **NEVER** ask user to provide admin credentials
- **ALWAYS** offer to generate admin credentials automatically:
  - Name: "Admin"
  - Surname: "User"
  - Email: "admin@{project_name}.local"
  - Username: "admin"
  - Password: Generate secure random password (12+ characters)
- Present generated credentials to user BEFORE using them, allowing user to modify if needed

Then run installation with generated credentials:

**With demo data (if user requested):**
```bash
orodc exec bin/console oro:install \
  --env=prod \
  --timeout=1800 \
  --language=en \
  --formatting-code=en_US \
  --organization-name="Acme Inc." \
  --user-name="admin" \
  --user-email="admin@{project_name}.local" \
  --user-firstname="Admin" \
  --user-lastname="User" \
  --user-password="<GENERATED_SECURE_PASSWORD>" \
  --application-url="https://{project_name}.docker.local/" \
  --sample-data=y
```

**Without demo data (if user did NOT request demo):**
```bash
orodc exec bin/console oro:install \
  --env=prod \
  --timeout=1800 \
  --language=en \
  --formatting-code=en_US \
  --organization-name="Acme Inc." \
  --user-name="admin" \
  --user-email="admin@{project_name}.local" \
  --user-firstname="Admin" \
  --user-lastname="User" \
  --user-password="<GENERATED_SECURE_PASSWORD>" \
  --application-url="https://{project_name}.docker.local/" \
  --sample-data=n
```

**Parameters explanation:**
- `--env=prod` - Production environment
- `--timeout=1800` - Installation timeout (30 minutes)
- `--language=en` - Default language
- `--formatting-code=en_US` - Locale for formatting
- `--organization-name` - Organization name (can be customized)
- `--user-name` - Admin username (generated: "admin")
- `--user-email` - Admin email (generated: "admin@{project_name}.local")
- `--user-firstname` - Admin first name (generated: "Admin")
- `--user-lastname` - Admin last name (generated: "User")
- `--user-password` - Admin password (generated secure password)
- `--application-url` - Application base URL
- `--sample-data=y|n` - **🔴 CRITICAL**: `y` = install demo data (if user requested), `n` = no demo data

This command will:
- Set up database
- Install application
- Configure environment
- Set up initial data with generated admin account
- **Install demo data (if --sample-data=y)**

### Step 5: Build Assets (Frontend)

**🔴 CRITICAL - ALWAYS REQUIRED - DO NOT SKIP**

Build frontend assets. **This step is MANDATORY** - frontend will not work without it!

**Why this is needed**: Oro Platform requires frontend assets (CSS, JavaScript) to be compiled and built before the frontend can work correctly. This step compiles and builds all frontend assets.

**🚨 WARNING: Skipping this step will result in:**
- Broken frontend with no CSS styles
- Missing JavaScript functionality
- White pages or unstyled content
- Admin panel may not work correctly

**When to build**: This step MUST be done AFTER Oro installation (Step 4) and BEFORE accessing the frontend.

**YOU MUST EXECUTE THIS STEP:**

**Recommended (with watch mode for development):**
```bash
orodc exec bin/console oro:assets:build default -w
```
*The `-w` flag enables "watch" mode, which rebuilds assets automatically when files change (useful for development)*

**Alternative (one-time build without watch mode):**
```bash
orodc exec bin/console oro:assets:build
```
*Use this for production builds or when you don't need automatic rebuilding*

**Important Notes**:
- This step may take several minutes depending on the number of assets
- Watch mode (`-w`) keeps the process running - you can stop it with Ctrl+C after initial build
- For production, use one-time build without watch mode
- **DO NOT skip this step** - frontend will not work without it

### Step 6: Clear and Warm Up Cache

**REQUIRED**: Clear and warm up cache after assets build.

**Why this is needed**: After building assets and installing Oro, the cache may contain stale data. Clearing and warming up cache ensures all new assets and configurations are properly loaded.

**How to clear and warm up cache**:

```bash
# Clear all cache
orodc exec bin/console cache:clear

# Warm up cache (preload frequently used data)
orodc exec bin/console cache:warmup
```

**What these commands do**:
- `cache:clear` - Removes all cached data (config, routes, etc.)
- `cache:warmup` - Preloads frequently used data into cache for better performance

**Important Notes**:
- This step must be done AFTER assets build (Step 5) and BEFORE accessing the application
- Cache operations ensure that all new assets and configurations are properly loaded
- Skipping this step may result in outdated cache showing old data

### Step 7: Ensure Containers Are Running

**🔴 REQUIRED - NEVER SKIP THIS STEP**: Verify and ensure all containers are running:

```bash
orodc up -d
orodc ps
```

**🚨 CRITICAL RULES**:
- **MUST execute both commands**: Run `orodc up -d` AND `orodc ps` - do NOT skip even if containers seem running
- **DO NOT skip because status shows running**: Even if `orodc status` shows containers running, you MUST execute Step 7 as written
- **DO NOT make assumptions**: Do not assume containers are running - execute the commands to verify and ensure they are running
- **This is a verification step**: This step ensures containers are running AND verifies their status - skipping it can cause issues
- **User permission required**: If you want to skip this step, you MUST ask user: "Step 7 says to run `orodc up -d` and `orodc ps`, but containers seem running. Should I skip it or execute it anyway?"
- This is the final step before accessing the application - it must be executed to ensure everything is ready

## Verification

- **Frontend**: `https://{project_name}.docker.local`
- **Admin Panel**: `https://{project_name}.docker.local/admin`
- **Admin Credentials**: Credentials were generated during installation in Step 4 via `orodc exec bin/console oro:install` (if user modified them, they should have been noted)

## Important Notes

### 🔴 UNIVERSAL RULES Reminder (see `orodc agents installation` common part):

1. **Demo data (Step 4)**: If user requests demo data → use `--sample-data=y`
2. **Frontend build (Step 5)**: ALWAYS execute - frontend will not work without it
3. **Step order**: install → assets build → cache clear/warmup → verify containers
4. **Never skip CRITICAL**: Steps marked 🔴 must always be executed
5. **Final step required**: Always run `orodc up -d` and `orodc ps` at the end (Step 7) to ensure containers are running before accessing the application

### Oro-Specific Notes:

- **Installation methods**: Oro projects can be cloned from GitHub or created via composer (CE only)
- **CE vs Enterprise**: `composer create-project` installs Community Edition (CE) only. For Enterprise Edition, use git clone from Enterprise repository or contact Oro support
- **Installation command**: Use `orodc exec bin/console oro:install` with all required parameters (see Step 4 for full example)
- **Demo data rule**: Use `--sample-data=y` when user explicitly requests demo data (phrases like "with demo", "sample data", "test products")
- **Assets building**: ALWAYS build assets after installation - this is MANDATORY, not optional
- **See full guide**: Reference `docs/ORO.md` for complete setup guide and troubleshooting
