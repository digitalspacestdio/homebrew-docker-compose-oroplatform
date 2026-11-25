# 🚀 OroCommerce / OroPlatform Setup Guide

Complete setup guide for ORO Platform applications (OroCommerce, OroCRM, OroPlatform, MarelloCommerce) using OroDC.

## Quick Start

### OroCommerce

```bash
# 1. Install OroDC
brew install digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform

# 2. Clone OroCommerce repository
git clone --single-branch --branch 6.1.4 https://github.com/oroinc/orocommerce-application.git ~/orocommerce
cd ~/orocommerce

# 3. Install and start (one command!)
orodc install && orodc up -d

# Alternative: Full installation command with custom parameters
orodc exec bin/console oro:install \
  --env=prod \
  --timeout=1800 \
  --language=en \
  --formatting-code=en_US \
  --organization-name="Acme Inc." \
  --user-name="admin" \
  --user-email="admin@orocommerce.local" \
  --user-firstname="Admin" \
  --user-lastname="User" \
  --user-password="\$ecretPassw0rd" \
  --application-url="https://orocommerce.docker.local/" \
  --sample-data=y

# 4. Verify installation
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:30280
# 2xx (200, 201, etc.) = OK, 3xx (301, 302, etc.) = Redirect (also OK)

# 5. Access your application
# Frontend: https://orocommerce.docker.local
# Admin: https://orocommerce.docker.local/admin
# Default credentials: admin / 12345678
```

### OroPlatform

```bash
# 1. Install OroDC
brew install digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform

# 2. Clone OroPlatform repository
git clone --single-branch --branch 6.1 https://github.com/oroinc/platform-application.git ~/oroplatform
cd ~/oroplatform

# 3. Install and start
orodc install && orodc up -d

# Alternative: Full installation command with custom parameters
orodc exec bin/console oro:install \
  --env=prod \
  --timeout=1800 \
  --language=en \
  --formatting-code=en_US \
  --organization-name="Acme Inc." \
  --user-name="admin" \
  --user-email="admin@oroplatform.local" \
  --user-firstname="Admin" \
  --user-lastname="User" \
  --user-password="\$ecretPassw0rd" \
  --application-url="https://oroplatform.docker.local/" \
  --sample-data=y

# 4. Access your application
# Admin: https://oroplatform.docker.local/admin
# Default credentials: admin / 12345678
```

## Common Commands

### Cache Management
```bash
orodc bin/console cache:clear
```

### Assets Building
```bash
orodc bin/console oro:assets:build default -w
```

### Database Operations
```bash
# List databases
orodc psql -l

# Execute SQL
orodc psql -c "SELECT version();"

# Export database
orodc database export backup.sql

# Import database
orodc database import backup.sql

# Import with domain replacement (interactive)
orodc database import backup.sql
# Prompts: Replace domain names? [y/N]
#         Enter source domain: www.example.com
#         Enter target domain [myproject.docker.local]: (press Enter for default)
# Domains are saved for future imports

# Import with domain replacement (non-interactive)
orodc database import backup.sql --from-domain=www.example.com --to-domain=myproject.docker.local
```

### Search Reindex
```bash
# Reindex both backend and website search
orodc search reindex
```

### Platform Update
```bash
orodc platform-update
```

## Testing

**BEFORE running ANY tests:**
1. ✅ **MUST** run `orodc tests install` (independent setup)
2. ✅ **MUST** use `orodc tests` prefix for ALL test commands
3. ❌ **NEVER** run tests directly (e.g., `bin/phpunit`, `./bin/behat`)

### Setup Test Environment
```bash
cd ~/orocommerce
orodc tests install
```

### Unit Tests
```bash
orodc tests bin/phpunit --testsuite=unit
orodc tests bin/phpunit --testsuite=unit --filter=UserTest
orodc tests bin/phpunit src/Oro/Bundle/UserBundle/Tests/Unit/Entity/UserTest.php
```

### Functional Tests
```bash
orodc tests bin/phpunit --testsuite=functional
orodc tests bin/phpunit --testsuite=functional --filter=ApiTest
```

### Behat Tests
Behat runs against a production-like application in the `behat_test` environment, so it has its own
database (`<db>_behat`), installed once with `orodc tests behat-install`. Rerun `behat-install` after
configuration changes: it rebuilds the `behat_test` cache. `orodc tests purge` drops both test databases.

```bash
orodc tests behat-install
orodc tests behat --available-suites
orodc tests behat --suite=OroUserBundle
orodc tests bin/behat vendor/oro/platform/src/Oro/Bundle/UserBundle/Tests/Behat/Features/user_back_office_login.feature
```

Behat commands run in the `test-behat-cli` service with Oro's `chromedriver` profile (headless Chromium
flags that work in containers) unless you pass `--profile`. The browser runs in `test-selenium`
(chromedriver on port 9515, amd64 and arm64), and the application is served by `test-fpm`/`test-nginx`
at `http://test-nginx`. The application must not force HTTPS in the `behat_test` environment, because
`test-nginx` serves plain HTTP.

### Test Coverage
```bash
orodc tests bin/phpunit --testsuite=unit --coverage-html coverage/
orodc tests bin/phpunit --coverage-text
```

### Test Environment Management
```bash
orodc tests ps                    # Check test environment status
orodc tests logs                  # View test logs
orodc tests up -d                 # Start test services
orodc tests down                  # Stop test services
orodc tests purge                 # Clean test environment
```

### Test Database
```bash
orodc tests psql                         # Access test database
orodc tests psql -c "SELECT version();"  # Run SQL commands
```

## Access Information

### OroCommerce
- **Frontend**: `https://orocommerce.docker.local` (or `http://localhost:30280`)
- **Admin Panel**: `https://orocommerce.docker.local/admin`
- **Default Admin Credentials**: `admin` / `12345678`

### OroPlatform
- **Admin Panel**: `https://oroplatform.docker.local/admin`
- **Default Admin Credentials**: `admin` / `12345678`

## Smart PHP Commands

OroDC automatically detects PHP commands:

```bash
# ✅ CORRECT - OroDC auto-detects
orodc --version                    # Check PHP version
orodc -r 'echo "Hello OroDC!";'   # Run PHP code directly
orodc bin/console cache:clear      # Run Symfony console commands

# ❌ WRONG - Redundant cli prefix
orodc cli php --version
```

## Troubleshooting

### Installation Issues
If installation fails, check logs:
```bash
orodc compose logs
```

### Database Connection Issues
Verify database is running:
```bash
orodc ps
orodc psql -c "SELECT version();"
```

### Cache Issues
Clear all caches:
```bash
orodc cache clear
orodc bin/console cache:clear
```

For more information, see the main [README.md](../README.md) and [DEVELOPMENT.md](../DEVELOPMENT.md).
