# 📦 Magento 2 Setup Guide

Complete setup guide for Magento 2 using OroDC with Mage-OS repository.

## Quick Start

```bash
# 1. Install OroDC
brew install digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform

# 2. Create empty project directory
mkdir ~/mageos
cd ~/mageos

# 3. Initialize OroDC environment with required parameters
orodc init

# 4. Start containers
orodc up -d

# 5. Create Magento project using Mage-OS repository
orodc exec composer create-project --repository-url=https://repo.mage-os.org/ mage-os/project-community-edition .

# 6. Install Magento via CLI
orodc exec bin/magento setup:install \
  --base-url="${DOCKER_BASE_URL}" \
  --base-url-secure="${DOCKER_BASE_URL}" \
  --db-host="${ORO_DB_HOST:-database}" \
  --db-name="${ORO_DB_NAME:-app_db}" \
  --db-user="${ORO_DB_USER:-app_db_user}" \
  --db-password="${ORO_DB_PASSWORD:-app_db_pass}" \
  --admin-firstname=Admin \
  --admin-lastname=User \
  --admin-email=admin@example.com \
  --admin-user=admin \
  --admin-password=Admin123456 \
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

# 7. Deploy static content (MUST specify locale - -f alone will NOT deploy CSS styles)
orodc exec bin/magento setup:static-content:deploy en_US -f

# 8. Compile DI
orodc exec bin/magento setup:di:compile

# 9. Clear cache
orodc exec bin/magento cache:flush

# 10. Disable Two-Factor Authentication (2FA) for development
orodc exec bin/magento module:disable Magento_TwoFactorAuth
orodc exec bin/magento setup:upgrade
orodc exec bin/magento cache:flush

# Access your Magento installation
# Frontend: https://mageos.docker.local
# Admin: https://mageos.docker.local/admin
# Admin credentials: admin / Admin123456
```

**Note:** If you see "You need to configure Two-Factor Authorization" message after login, disable 2FA using the command above.

## Common Commands

### Static Content Deployment

**CRITICAL**: You MUST specify locale(s) explicitly - using `setup:static-content:deploy -f` WITHOUT locale parameters will NOT deploy CSS styles correctly. Pages will appear without styles.

**REQUIRED**: Always specify at least one locale:

```bash
# Deploy for specific locale (en_US is default, REQUIRED)
orodc exec bin/magento setup:static-content:deploy en_US -f

# Deploy for multiple locales
orodc exec bin/magento setup:static-content:deploy en_US ru_RU -f

# To deploy ALL locales, first get list of all installed locales:
orodc exec bin/magento info:language:list

# Then deploy for all locales (replace with actual locales from the list):
orodc exec bin/magento setup:static-content:deploy en_US de_DE fr_FR es_ES ru_RU -f
```

**How to get all installed locales:**
```bash
# Method 1: List all installed languages/locales (RECOMMENDED)
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

### Compile Dependency Injection
```bash
orodc exec bin/magento setup:di:compile
```

### Cache Management
```bash
orodc exec bin/magento cache:clean
orodc exec bin/magento cache:flush
```

### Index Management
```bash
orodc exec bin/magento indexer:reindex
```

### Enable Developer Mode
```bash
orodc exec bin/magento deploy:mode:set developer
```

### Disable Two-Factor Authentication (2FA)

For Magento Open Source / MageOS (without Adobe IMS):
```bash
orodc exec bin/magento module:disable Magento_TwoFactorAuth
orodc exec bin/magento setup:upgrade
orodc exec bin/magento cache:flush
```

For Magento Commerce/Adobe Commerce (with Adobe IMS):
```bash
orodc exec bin/magento module:disable Magento_AdminAdobeImsTwoFactorAuth Magento_TwoFactorAuth
orodc exec bin/magento setup:upgrade
orodc exec bin/magento cache:flush
```

## Access Information

- **Frontend**: `https://mageos.docker.local` (or `http://localhost:30280`)
- **Admin Panel**: `https://mageos.docker.local/admin`
- **Default Admin Credentials**: `admin` / `Admin123456`

## Troubleshooting

### Two-Factor Authentication Error
If you see "You need to configure Two-Factor Authorization" message after login, disable 2FA using the commands above.

### Static Content Not Updating / Styles Missing
Clear cache and redeploy static content with explicit locale:
```bash
orodc exec bin/magento cache:flush
orodc exec bin/magento setup:static-content:deploy en_US -f
```

**If styles are still missing:**
- **CRITICAL**: Always specify locale: `setup:static-content:deploy en_US -f` (NOT just `-f`)
- Remove pub/static and redeploy: `orodc exec rm -rf pub/static/* && orodc exec bin/magento setup:static-content:deploy en_US -f`
- Check file permissions: `orodc exec chmod -R 777 pub/static var`
- Clear browser cache or use incognito mode
- Verify theme is set correctly: `orodc exec bin/magento config:show design/theme/theme_id`

### Database Connection Issues
Verify database configuration:
```bash
orodc psql -c "SELECT version();"
```

For more information, see the main [README.md](../README.md) and [DEVELOPMENT.md](../DEVELOPMENT.md).
