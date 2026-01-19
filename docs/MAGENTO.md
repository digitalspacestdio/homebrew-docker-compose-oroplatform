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

# 7. Deploy static content
orodc exec bin/magento setup:static-content:deploy -f

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
```bash
orodc exec bin/magento setup:static-content:deploy -f
```

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

### Static Content Not Updating
Clear cache and redeploy static content:
```bash
orodc exec bin/magento cache:flush
orodc exec bin/magento setup:static-content:deploy -f
```

### Database Connection Issues
Verify database configuration:
```bash
orodc psql -c "SELECT version();"
```

For more information, see the main [README.md](../README.md) and [DEVELOPMENT.md](../DEVELOPMENT.md).
