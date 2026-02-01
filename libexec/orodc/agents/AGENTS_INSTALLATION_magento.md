# Magento 2 Installation Guide

**Complete guide for creating a new Magento 2 project from scratch.**

## Installation Checklist

**Use this checklist to track installation progress. Check off each step as you complete it.**

### Prerequisites Checklist

- [ ] Navigate to empty project directory
- [ ] Run `orodc init` manually in terminal (MUST be done by user BEFORE using agent)
- [ ] Run `orodc up -d`
- [ ] Verify containers are running with `orodc ps`

### Installation Steps Checklist

- [ ] Step 1: Verify directory is empty
- [ ] Step 2: Extract environment variables (REQUIRED before installation commands)
- [ ] Step 3: Create Magento project (composer create-project)
- [ ] Step 4: Install Magento via CLI (with admin credentials from user)
- [ ] Step 5: Deploy static content (build frontend) - **CRITICAL, DO NOT SKIP**
- [ ] Step 6: Compile Dependency Injection
- [ ] Step 7: Clear cache
- [ ] Step 8: Disable Two-Factor Authentication (development)
- [ ] Step 9: Ensure containers are running (`orodc up -d` and `orodc ps`)

### Final Verification Checklist

- [ ] All containers are running (`orodc ps` shows "Running" status)
- [ ] Frontend is accessible: `https://{project_name}.docker.local`
- [ ] Admin panel is accessible: `https://{project_name}.docker.local/admin`
- [ ] Admin credentials are saved (ask user if needed)

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

### Step 2: Extract Environment Variables

**REQUIRED**: Before running installation commands, extract environment variables needed for Magento configuration:

```bash
# Primary command: Get all OroDC service connection variables
orodc exec env | grep ORO_

# Or get all environment variables
orodc exec env

# Filter by specific service:
orodc exec env | grep -i database
orodc exec env | grep -i search
```

**IMPORTANT**: 
- **MUST be done BEFORE Step 4 (Magento installation)** - you'll need these variables for `setup:install` command
- Save these variables or keep them accessible
- Key variables you'll need for Magento installation:
  - `DOCKER_BASE_URL` - Application base URL
  - `ORO_DB_HOST` - Database host (usually "database")
  - `ORO_DB_NAME` - Database name
  - `ORO_DB_USER` - Database user
  - `ORO_DB_PASSWORD` - Database password
  - Search engine host (usually "search") and port (usually 9200)

### Step 3: Create Magento Project

**IMPORTANT**: Composer create-project installs **Community Edition (CE)** only.

Choose one of the following:

**Option A: Mage-OS (Open Source, Recommended)**
```bash
orodc exec composer create-project --repository-url=https://repo.mage-os.org/ mage-os/project-community-edition .
```
*Installs Community Edition (CE) - open source version*

**Option B: Magento 2 Official Community Edition**
```bash
orodc exec composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition .
```
*Installs Community Edition (CE). Requires Magento authentication keys for official repository*

**For Enterprise Edition**: Enterprise Edition requires access to private Magento Commerce repository (`magento/project-enterprise-edition`) and cannot be installed via public composer create-project. Use git clone from your Enterprise repository or contact Magento support for Enterprise installation instructions.

### Step 4: Install Magento via CLI

**REQUIRED**: Install Magento using setup:install command:

**IMPORTANT**: Before running installation, ask user for:
- Admin first name
- Admin last name
- Admin email
- Admin username
- Admin password

Then run installation with user-provided credentials:

```bash
orodc exec bin/magento setup:install \
  --base-url="${DOCKER_BASE_URL}" \
  --base-url-secure="${DOCKER_BASE_URL}" \
  --db-host="${ORO_DB_HOST:-database}" \
  --db-name="${ORO_DB_NAME:-app_db}" \
  --db-user="${ORO_DB_USER:-app_db_user}" \
  --db-password="${ORO_DB_PASSWORD:-app_db_pass}" \
  --admin-firstname="<USER_PROVIDED_FIRSTNAME>" \
  --admin-lastname="<USER_PROVIDED_LASTNAME>" \
  --admin-email="<USER_PROVIDED_EMAIL>" \
  --admin-user="<USER_PROVIDED_USERNAME>" \
  --admin-password="<USER_PROVIDED_PASSWORD>" \
  --backend-frontname=admin \
  --language=en_US \
  --currency=USD \
  --timezone=America/New_York \
  --use-rewrites=1 \
  --use-secure=1 \
  --use-secure-admin=1 \
  --search-engine=opensearch \
  --opensearch-host=search \
  --opensearch-port=9200
```

**Note**: Replace `<USER_PROVIDED_*>` placeholders with actual values provided by user.

### Step 5: Deploy Static Content (Build Frontend)

**CRITICAL - REQUIRED**: Deploy static content (build frontend) after installation. **DO NOT SKIP THIS STEP** - frontend will not work without it:

**CRITICAL**: You MUST specify locale(s) explicitly - using `setup:static-content:deploy -f` WITHOUT locale parameters will NOT deploy CSS styles correctly. Pages will appear without styles.

**REQUIRED**: Always specify at least one locale:

```bash
# Deploy static content with explicit locale (en_US is default, REQUIRED)
orodc exec bin/magento setup:static-content:deploy en_US -f

# Or deploy for multiple locales:
orodc exec bin/magento setup:static-content:deploy en_US ru_RU -f

# To deploy ALL locales, first get list of all installed locales:
orodc exec bin/magento info:language:list

# Then deploy for all locales (replace with actual locales from the list):
orodc exec bin/magento setup:static-content:deploy en_US de_DE fr_FR es_ES ru_RU -f
```

**How to get all installed locales:**
```bash
# Method 1: List all installed languages/locales
orodc exec bin/magento info:language:list

# Method 2: Check database for configured locales
orodc exec bin/magento db:query "SELECT DISTINCT value FROM core_config_data WHERE path LIKE 'general/locale%'"

# Method 3: Check installed language packs in app/i18n/
orodc exec ls -la app/i18n/
```

**Why locale is REQUIRED:**
- **Note**: In older Magento 2 versions (2.3 and earlier), `setup:static-content:deploy -f` without locale parameters would automatically deploy all locales and themes
- **In newer Magento 2 versions** (2.4+), this behavior changed - you MUST specify locale(s) explicitly
- Running `setup:static-content:deploy -f` WITHOUT locale parameters will NOT compile CSS styles properly in newer versions
- Pages will appear without styles if locale is not specified
- The `-f` flag only forces regeneration but doesn't ensure CSS compilation without locale
- Always specify at least one locale (e.g., `en_US`) to ensure styles are deployed correctly

**IMPORTANT**: This step builds the frontend assets including CSS styles. Without proper locale specification, styles will not display correctly.

### Step 6: Compile Dependency Injection

**REQUIRED**: Compile DI after installation:

```bash
orodc exec bin/magento setup:di:compile
```

### Step 7: Clear Cache

```bash
orodc exec bin/magento cache:flush
```

### Step 8: Disable Two-Factor Authentication (Development)

**Recommended for development**: Disable 2FA to avoid login issues:

```bash
orodc exec bin/magento module:disable Magento_TwoFactorAuth
orodc exec bin/magento setup:upgrade
orodc exec bin/magento cache:flush
```

### Step 9: Ensure Containers Are Running

**REQUIRED**: Verify and ensure all containers are running:

```bash
orodc up -d
orodc ps
```

**IMPORTANT**: 
- Run `orodc up -d` to ensure all containers are started
- Verify with `orodc ps` that all containers show "Running" status
- This is the final step before accessing the application

## Verification

**After completing all installation steps, verify:**

- [ ] **Frontend**: `https://{project_name}.docker.local` - should display Magento storefront
- [ ] **Admin Panel**: `https://{project_name}.docker.local/admin` - should display admin login page
- [ ] **Admin Credentials**: Ask user for admin username and password (credentials were set during installation in Step 4)
- [ ] **Containers**: Run `orodc ps` - all containers should show "Running" status

## Important Notes

- **CE vs Enterprise**: `composer create-project` installs Community Edition (CE) only. For Enterprise Edition, use git clone from Enterprise repository or contact Magento support
- **All steps are required**: Installation, static content deployment (frontend build), DI compilation, cache clearing, and final container check
- **Frontend build is critical**: Step 5 (static content deployment) MUST be executed - frontend will not work without it
- **Final step required**: Always run `orodc up -d` at the end (Step 9) to ensure containers are running before accessing the application
- **Use environment variables**: Always use variables from `orodc exec env | grep ORO_` for configuration (shows all OroDC service connection variables)
- **Containers must be running**: Ensure `orodc ps` shows all containers running before installation and after final step
- **See full guide**: Reference `docs/MAGENTO.md` for complete setup guide and troubleshooting
