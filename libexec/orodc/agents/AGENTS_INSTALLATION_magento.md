# Magento 2 Installation Guide

**Complete guide for creating a new Magento 2 project from scratch.**

## Prerequisites

- Complete steps 1-4 from `AGENTS_INSTALLATION_common.md`:
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

### Step 2: Create Magento Project

Choose one of the following:

**Option A: Mage-OS (Open Source, Recommended)**
```bash
orodc exec composer create-project --repository-url=https://repo.mage-os.org/ mage-os/project-community-edition .
```

**Option B: Magento 2 Official**
```bash
orodc exec composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition .
```
*Note: Requires Magento authentication keys for official repository*

### Step 3: Get Environment Variables

Get database and service connection details:

```bash
# Primary command: Get all OroDC service connection variables
orodc exec env | grep ORO_

# Or filter by specific service:
orodc exec env | grep -i database
orodc exec env | grep -i search
```

Key variables you'll need:
- `DOCKER_BASE_URL` - Application base URL
- `ORO_DB_HOST` - Database host (usually "database")
- `ORO_DB_NAME` - Database name
- `ORO_DB_USER` - Database user
- `ORO_DB_PASSWORD` - Database password
- Search engine host (usually "search") and port (usually 9200)

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

### Step 5: Deploy Static Content

**REQUIRED**: Deploy static content after installation:

```bash
orodc exec bin/magento setup:static-content:deploy -f
```

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

## Verification

- **Frontend**: `https://{project_name}.docker.local`
- **Admin Panel**: `https://{project_name}.docker.local/admin`
- **Admin Credentials**: Ask user for admin username and password (credentials were set during installation in Step 4)

## Important Notes

- **All steps are required**: Installation, static content deployment, DI compilation, and cache clearing
- **Use environment variables**: Always use variables from `orodc exec env | grep ORO_` for configuration (shows all OroDC service connection variables)
- **Containers must be running**: Ensure `orodc ps` shows all containers running before installation
- **See full guide**: Reference `docs/MAGENTO.md` for complete setup guide and troubleshooting
