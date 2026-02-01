# Oro Platform Installation Guide

**Complete guide for creating a new Oro Platform project from scratch.**

---

## ⚠️ CRITICAL WARNINGS - READ BEFORE STARTING

**🔴 ALL steps in this guide are REQUIRED unless explicitly marked optional.**

**🚨 UNIVERSAL RULES APPLY** (see `orodc agents installation` common part):
1. **Demo data**: If user requests demo data → use `--sample-data=y` in oro:install (Step 4)
2. **Frontend build**: Step 5 is MANDATORY (assets build)
3. **Step order**: Steps MUST be executed in order
4. **Never skip CRITICAL steps**: Steps marked 🔴 must always be executed

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

### Final Verification Checklist

- [ ] All containers are running (`orodc ps` shows "Running" status)
- [ ] Frontend is accessible: `https://{project_name}.docker.local`
- [ ] Admin panel is accessible: `https://{project_name}.docker.local/admin`
- [ ] Admin credentials are saved (generated during installation)
- [ ] **If demo data was requested**: Products and sample data are visible in admin

---

## Prerequisites

- Complete steps 1-4 from `orodc agents installation` (common part):
  - Navigate to empty project directory
  - Run `orodc init` manually in terminal (MUST be done by user BEFORE using agent)
  - Run `orodc up -d`
  - Verify containers are running with `orodc ps`

## Installation Steps

### Step 1: Verify Directory is Empty

**REQUIRED**: Ensure directory is empty (or contains only `.git`):

```bash
orodc exec ls -la
# Should show only .git (if version control) or be empty
```

**IMPORTANT**: Project creation commands MUST be run in an empty directory.

### Step 2: Create Oro Project

Choose one of the following methods:

#### Method 1: Clone from GitHub (Recommended)

Oro projects can be cloned from GitHub repositories:

**Option A: OroCommerce**
```bash
orodc exec git clone --single-branch --branch 6.1.4 https://github.com/oroinc/orocommerce-application.git .
```

**Option B: OroPlatform**
```bash
orodc exec git clone --single-branch --branch 6.1 https://github.com/oroinc/platform-application.git .
```

**Option C: MarelloCommerce**
```bash
# Clone from Marello repository (check latest branch)
orodc exec git clone --single-branch --branch <version> <marello-repo-url> .
```

#### Method 2: Create via Composer (CE Edition Only)

**IMPORTANT**: Composer create-project installs **Community Edition (CE)** only.

**OroCommerce CE:**
```bash
orodc exec composer create-project oro/commerce-application .
```

**OroPlatform CE:**
```bash
orodc exec composer create-project oro/platform-application .
```

**For Enterprise Edition**: Enterprise versions require access to private Oro repositories and cannot be installed via public composer create-project. Use git clone from your Enterprise repository or contact Oro support for Enterprise installation instructions.

### Step 3: Install Dependencies

Install PHP dependencies via Composer:

```bash
orodc exec composer install
```

### Step 4: Install Oro Platform

**REQUIRED**: Run Oro installation command.

**🔴 CRITICAL - DEMO DATA DECISION:**
- **If user asks for "demo data", "sample data", "with demo"** → use `--sample-data=y`
- **If user does NOT mention demo data** → use `--sample-data=n`
- **🚨 DO NOT FORGET to set the correct --sample-data flag based on user request!**

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

**🚨 WARNING: Skipping this step will result in:**
- Broken frontend with no CSS styles
- Missing JavaScript functionality
- White pages or unstyled content

**YOU MUST EXECUTE THIS STEP:**

```bash
orodc exec bin/console oro:assets:build default -w
```

**Note**: The `-w` flag enables "watch" mode. For one-time build without watch mode, use:
```bash
orodc exec bin/console oro:assets:build
```

### Step 6: Clear and Warm Up Cache

```bash
orodc exec bin/console cache:clear
orodc exec bin/console cache:warmup
```

## Verification

- **Frontend**: `https://{project_name}.docker.local`
- **Admin Panel**: `https://{project_name}.docker.local/admin`
- **Admin Credentials**: Credentials were generated during installation in Step 4 via `orodc exec bin/console oro:install` (if user modified them, they should have been noted)

## Important Notes

### 🔴 UNIVERSAL RULES Reminder (see `orodc agents installation` common part):

1. **Demo data (Step 4)**: If user requests demo data → use `--sample-data=y`
2. **Frontend build (Step 5)**: ALWAYS execute - frontend will not work without it
3. **Step order**: install → assets build → cache clear/warmup
4. **Never skip CRITICAL**: Steps marked 🔴 must always be executed

### Oro-Specific Notes:

- **Installation methods**: Oro projects can be cloned from GitHub or created via composer (CE only)
- **CE vs Enterprise**: `composer create-project` installs Community Edition (CE) only. For Enterprise Edition, use git clone from Enterprise repository or contact Oro support
- **Installation command**: Use `orodc exec bin/console oro:install` with all required parameters (see Step 4 for full example)
- **Demo data rule**: Use `--sample-data=y` when user explicitly requests demo data (phrases like "with demo", "sample data", "test products")
- **Assets building**: ALWAYS build assets after installation - this is MANDATORY, not optional
- **See full guide**: Reference `docs/ORO.md` for complete setup guide and troubleshooting
