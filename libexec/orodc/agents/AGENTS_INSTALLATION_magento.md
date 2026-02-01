# Magento 2 Installation Guide

**Complete guide for creating a new Magento 2 project from scratch.**

---

## ⚠️ CRITICAL WARNINGS - READ BEFORE STARTING

**🔴 ALL steps in this guide are REQUIRED unless explicitly marked optional.**

**🚨 UNIVERSAL RULES APPLY** (see `orodc agents installation` common part):
1. **Demo data**: If user requests demo data → execute Step 6 (Sample Data)
2. **Frontend build**: Step 9 is MANDATORY (static content deployment)
3. **Step order**: Steps MUST be executed in order (DI compile → cache → static content)
4. **Never skip CRITICAL steps**: Steps marked 🔴 must always be executed

**Magento-specific critical steps:**
- **Step 6**: Sample Data → REQUIRED if user requests demo data
- **Step 9**: Static Content Deploy → ALWAYS REQUIRED (frontend build)

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
- [ ] Step 2: Extract environment variables (REQUIRED before installation commands)
- [ ] Step 3: Create Magento project (composer create-project)
- [ ] Step 4: Configure OpenSearch for Magento 2 (if using OpenSearch)
- [ ] Step 5: Install Magento via CLI (with auto-generated admin credentials)
- [ ] **Step 6: Install Sample Data (demo data)** - **🔴 REQUIRED if user requests demo data**
- [ ] Step 7: Compile Dependency Injection
- [ ] Step 8: Clear cache (warm up cache)
- [ ] **Step 9: Deploy static content (build frontend)** - **🔴 CRITICAL, ALWAYS REQUIRED**
- [ ] Step 10: Disable Two-Factor Authentication (development)
- [ ] Step 11: Ensure containers are running (`orodc up -d` and `orodc ps`)

### Final Verification Checklist

- [ ] All containers are running (`orodc ps` shows "Running" status)
- [ ] Frontend is accessible: `https://{project_name}.docker.local`
- [ ] Admin panel is accessible: `https://{project_name}.docker.local/admin`
- [ ] Admin credentials are saved (generated during installation)
- [ ] **If demo data was requested**: Products and categories are visible in admin and frontend

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

### Step 4: Configure OpenSearch for Magento 2 (If Using OpenSearch)

**REQUIRED IF USING OPENSEARCH**: Before installing Magento, configure OpenSearch to enable `indices.id_field_data.enabled` setting. This is required for Magento 2 product search to work correctly with OpenSearch 2.0+.

**Why this is needed**: OpenSearch 2.0+ disables fielddata access for `_id` field by default for performance and security reasons. Magento 2 requires this setting to be enabled for proper product indexing and search.

**How to configure**:

**Recommended method** (using orodc exec):
```bash
# Ensure containers are running first
orodc up -d

# Wait for OpenSearch to be ready, then configure:
orodc exec curl -X PUT "http://search:9200/_cluster/settings" \
  -H 'Content-Type: application/json' \
  -d '{
    "persistent": {
      "indices.id_field_data.enabled": true
    }
  }'
```

**Alternative method** (if curl is not available in PHP container):
```bash
# From host machine (if port 9200 is exposed):
curl -X PUT "http://localhost:9200/_cluster/settings" \
  -H 'Content-Type: application/json' \
  -d '{
    "persistent": {
      "indices.id_field_data.enabled": true
    }
  }'
```

**Verify the setting was applied**:
```bash
orodc exec curl -s "http://search:9200/_cluster/settings?include_defaults=true&flat_settings=true" | grep id_field_data
# Should show: "indices.id_field_data.enabled":"true"
```

**Note**: 
- This step is only needed if you're using OpenSearch (not Elasticsearch)
- The setting persists across container restarts
- You only need to do this once per OpenSearch cluster
- If you're using Elasticsearch, skip this step

### Step 5: Install Magento via CLI

**REQUIRED**: Install Magento using setup:install command:

**IMPORTANT**: Before running installation:
- **NEVER** ask user to provide admin credentials
- **ALWAYS** offer to generate admin credentials automatically:
  - Admin first name: "Admin"
  - Admin last name: "User"
  - Admin email: "admin@{project_name}.local"
  - Admin username: "admin"
  - Admin password: Generate secure random password (12+ characters)
- Present generated credentials to user BEFORE using them, allowing user to modify if needed

Then run installation with generated credentials:

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

### Step 6: Install Sample Data (Demo Data)

**🔴 REQUIRED IF USER REQUESTS DEMO DATA**

This step adds sample products, categories, CMS pages, and other demo content to the store.

**CRITICAL RULES:**
- **If user asks for "demo data", "sample data", "test products", "with demo"** → YOU MUST EXECUTE THIS STEP
- **If user does NOT mention demo data** → Skip this step and proceed to Step 7
- Sample data installation MUST be done AFTER Magento installation (Step 5) but BEFORE DI compilation (Step 7)

**🚨 DO NOT FORGET THIS STEP WHEN USER REQUESTS DEMO DATA!**

**To install sample data:**

```bash
# Step 6.1: Deploy sample data modules
orodc exec bin/magento sampledata:deploy

# Step 6.2: Install sample data (this will automatically run when upgrading)
orodc exec bin/magento setup:upgrade

# Step 6.3: Clear cache after sample data installation
orodc exec bin/magento cache:flush
```

**What sample data includes:**
- Sample products (catalog items)
- Sample categories
- Sample CMS pages and blocks
- Sample sales data
- Sample customer data (in some versions)

**Alternative method (via Composer):**
If `sampledata:deploy` command is not available, you can add sample data packages directly to `composer.json`:

```bash
# Add sample data packages to composer.json (requires manual editing)
# Then run:
orodc exec composer update
orodc exec bin/magento setup:upgrade
orodc exec bin/magento cache:flush
```

**Note**: Sample data packages include:
- `magento/module-catalog-sample-data`
- `magento/module-configurable-sample-data`
- `magento/module-cms-sample-data`
- `magento/module-sales-sample-data`
- And other sample data modules

### Step 7: Compile Dependency Injection

**REQUIRED**: Compile DI after installation (and after sample data if installed):

```bash
orodc exec bin/magento setup:di:compile
```

### Step 8: Clear Cache (Warm Up Cache)

**REQUIRED**: Clear and warm up cache after DI compilation:

```bash
orodc exec bin/magento cache:flush
```

**IMPORTANT**: Cache must be cleared after DI compilation and before static content deployment.

### Step 9: Deploy Static Content (Build Frontend)

**🔴 CRITICAL - ALWAYS REQUIRED - DO NOT SKIP**

Deploy static content (build frontend) after installation. **This step is MANDATORY** - frontend will not work without it!

**🚨 WARNING: Skipping this step will result in:**
- Broken frontend with no CSS styles
- Missing JavaScript functionality
- White pages or unstyled content

**YOU MUST EXECUTE THIS STEP:**

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

**IMPORTANT**:
- This step builds the frontend assets including CSS styles. Without proper locale specification, styles will not display correctly.
- **CRITICAL**: Static content deployment MUST be done AFTER DI compilation and cache clearing (Steps 7-8), not before.

### Step 10: Disable Two-Factor Authentication (Development)

**Recommended for development**: Disable 2FA to avoid login issues:

```bash
orodc exec bin/magento module:disable Magento_TwoFactorAuth
orodc exec bin/magento setup:upgrade
orodc exec bin/magento cache:flush
```

### Step 11: Ensure Containers Are Running

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
- [ ] **Admin Credentials**: Credentials were generated during installation in Step 5 (if user modified them, they should have been noted)
- [ ] **Containers**: Run `orodc ps` - all containers should show "Running" status

## Important Notes

### 🔴 UNIVERSAL RULES Reminder (see `orodc agents installation` common part):

1. **Demo data (Step 6)**: If user requests demo data → execute Step 6
2. **Frontend build (Step 9)**: ALWAYS execute - frontend will not work without it
3. **Step order**: Steps 7 → 8 → 9 MUST be in this exact order
4. **Never skip CRITICAL**: Steps marked 🔴 must always be executed

### Magento-Specific Notes:

- **CE vs Enterprise**: `composer create-project` installs Community Edition (CE) only. For Enterprise Edition, use git clone from Enterprise repository or contact Magento support
- **All steps are required**: Installation, DI compilation, cache clearing, static content deployment (frontend build), and final container check
- **OpenSearch configuration**: Step 4 (OpenSearch configuration) is REQUIRED if using OpenSearch 2.0+ with Magento 2
- **Sample data rule**: Step 6 should be executed when user explicitly requests demo data (phrases like "with demo", "sample data", "test products")
- **Correct order is critical**: DI compilation (Step 7) and cache clearing (Step 8) MUST be done BEFORE static content deployment (Step 9)
- **Frontend build is critical**: Step 9 (static content deployment) MUST be executed - frontend will not work without it
- **Final step required**: Always run `orodc up -d` at the end (Step 11) to ensure containers are running before accessing the application
- **Use environment variables**: Always use variables from `orodc exec env | grep ORO_` for configuration (shows all OroDC service connection variables)
- **Containers must be running**: Ensure `orodc ps` shows all containers running before installation and after final step
- **See full guide**: Reference `docs/MAGENTO.md` for complete setup guide and troubleshooting
