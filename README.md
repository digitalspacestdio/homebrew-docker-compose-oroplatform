# 🚀 OroCommerce / OroCrm / OroPlatform / MarelloCommerce / Magento / Any PHP CMS - Docker Compose Environment (OroDC)

![Docker architecture](docs/docker-architecture-small.png)

**Modern CLI tool to run PHP applications locally or on a server.** Designed specifically for local development environments with enterprise-grade performance and developer experience. Supports ORO Platform applications (OroCommerce, OroCRM, OroPlatform, MarelloCommerce), Magento, and any PHP-based CMS or framework.

[![Version](https://img.shields.io/badge/Version-1.2.0-brightgreen.svg)](https://github.com/digitalspacestdio/homebrew-docker-compose-oroplatform/releases)
[![Homebrew](https://img.shields.io/badge/Homebrew-Available-orange.svg)](https://brew.sh/)
[![Docker](https://img.shields.io/badge/Docker-Required-blue.svg)](https://www.docker.com/)
[![macOS](https://img.shields.io/badge/macOS-Supported-green.svg)](https://www.apple.com/macos/)
[![Linux](https://img.shields.io/badge/Linux-Supported-green.svg)](https://www.linux.org/)
[![Windows WSL2](https://img.shields.io/badge/Windows%20WSL2-Supported-green.svg)](https://docs.microsoft.com/en-us/windows/wsl/)

[![Test Installations](https://github.com/digitalspacestdio/homebrew-docker-compose-oroplatform/actions/workflows/test-oro-installations.yml/badge.svg)](https://github.com/digitalspacestdio/homebrew-docker-compose-oroplatform/actions/workflows/test-oro-installations.yml)
[![Build Docker Images](https://github.com/digitalspacestdio/homebrew-docker-compose-oroplatform/actions/workflows/build-docker-php-node-symfony.yml/badge.svg)](https://github.com/digitalspacestdio/homebrew-docker-compose-oroplatform/actions/workflows/build-docker-php-node-symfony.yml)

## 📋 Table of Contents

- [📚 Documentation](#-documentation)
- [✨ Key Features](#-key-features)
- [🚀 Quick Start](#-quick-start)
- [⚠️ Critical Testing Requirements](#️-critical-testing-requirements)
- [🎯 Smart PHP Integration](#-smart-php-integration)
- [🗄️ Smart Database Integration](#️-smart-database-integration)
- [💻 Supported Systems](#-supported-systems)
- [📦 Installation](#-installation)
- [🌐 Infrastructure Setup (Traefik + Dnsmasq + SSL)](#-infrastructure-setup-traefik--dnsmasq--ssl)
  - [Prerequisites](#prerequisites)
  - [Platform-Specific Configuration](#platform-specific-configuration)
  - [SSL Certificate Setup](#ssl-certificate-setup)
  - [Verification](#verification)
  - [Troubleshooting Infrastructure](#troubleshooting-infrastructure)
- [📖 Usage](#-usage)
  - [🚀 Basic Commands](#-basic-commands)
  - [📦 Command Structure](#-command-structure)
  - [🎮 Interactive Menu](#-interactive-menu)
  - [🎯 Smart PHP Commands & Flags](#-smart-php-commands--flags)
- [🧪 Testing](#-testing)
  - [Test Environment Setup](#test-environment-setup)
  - [Running Tests](#running-tests)
  - [Available Test Commands](#available-test-commands)
- [🔧 Development Commands](#-development-commands)
- [🤖 AI Assistant Integration](#-ai-assistant-integration)
- [🔌 Reverse Proxy Management](#-reverse-proxy-management)
- [🌐 Multiple Hosts Configuration](#-multiple-hosts-configuration)
  - [📝 Configuration Methods](#-configuration-methods)
  - [🔗 Application URL Configuration](#-application-url-configuration)
- [🌐 Dynamic Multisite Support via URL Paths](#-dynamic-multisite-support-via-url-paths)
- [⚙️ Environment Variables](#️-environment-variables)
- [🐳 Custom Docker Images](#-custom-docker-images)
- [🐛 XDEBUG Configuration](#-xdebug-configuration)
- [🔄 Working with Existing Projects](#-working-with-existing-projects)
- [🆘 Troubleshooting](#-troubleshooting)

---

## 📚 Documentation

**Application-specific guides:**
- **[docs/ORO.md](docs/ORO.md)** - Complete setup guide for OroCommerce, OroCRM, OroPlatform, MarelloCommerce
- **[docs/MAGENTO.md](docs/MAGENTO.md)** - Complete setup guide for Magento 2 (Mage-OS)

**For developers and contributors:**
- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Development guide with workflows, commands, and troubleshooting
- **[LOCAL-TESTING.md](LOCAL-TESTING.md)** - Comprehensive testing methods and procedures
- **[AGENTS.md](AGENTS.md)** - AI agent guidelines for working with this project
- **[openspec/project.md](openspec/project.md)** - Project architecture and technical context

---

## ✨ Key Features

- 🔥 **Minimal Dependencies**: No application changes required, works out of the box
- 🎯 **Smart PHP Detection**: Auto-redirect PHP commands to CLI container
- 🗄️ **Smart Database Access**: Direct psql/mysql commands with auto-configuration
- 🐳 **Full Docker Integration**: Complete containerized development environment
- 🔧 **Zero Configuration**: Works out of the box with sensible defaults
- 🎨 **Beautiful CLI**: Colored output and informative messages
- 🔄 **Hot Reload**: Live code synchronization with Mutagen/Rsync
- 🛡️ **Production-Like**: Same environment for dev, staging, and production

## 🚀 Quick Start

```bash
# Install OroDC
brew install digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform

# Clone and setup OroCommerce
git clone --single-branch --branch 6.1.4 https://github.com/oroinc/orocommerce-application.git ~/orocommerce
cd ~/orocommerce

# Install and start (one command!)
orodc install && orodc up -d

# Verify installation
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:30280
# 2xx (200, 201, etc.) = OK, 3xx (301, 302, etc.) = Redirect (also OK)

# Open your application
open http://localhost:30280/

# 🌐 Optional: Install Traefik + Dnsmasq for domain-based access
# See "Infrastructure Setup" section for *.docker.local domains with SSL
# brew tap digitalspacestdio/ngdev
# brew install digitalspace-traefik digitalspace-dnsmasq digitalspace-local-ca

# 🎯 Smart PHP Commands & Database Access
orodc help                         # Get full documentation
orodc --version                    # Check PHP version
orodc -r 'echo "Hello OroDC!";'    # Run PHP code directly
orodc psql -l                      # List databases directly
orodc psql -c "SELECT version();"  # Execute SQL commands
orodc tests bin/phpunit --testsuite=unit # Run PHPUnit tests
orodc tests bin/behat --available-suites # Run Behat behavior tests
```

## 🎯 Supported Applications

OroDC supports **any PHP-based application**, including:

- **ORO Platform**: OroCommerce, OroCRM, OroPlatform, MarelloCommerce - [📖 Complete Guide](docs/ORO.md)
- **Magento**: Magento 2.x (Open Source, Commerce) - [📖 Complete Guide](docs/MAGENTO.md)
- **Symfony**: Any Symfony-based application
- **Laravel**: Laravel applications
- **WordPress**: WordPress sites
- **Drupal**: Drupal CMS
- **Any PHP CMS**: Generic PHP applications

### 📦 Magento 2 Quick Start

```bash
# 1. Install OroDC
brew install digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform

# 2. Create empty project directory
mkdir ~/mageos && cd ~/mageos

# 3. Initialize and start
orodc init && orodc up -d

# 4. Create Magento project (Mage-OS)
orodc composer create-project --repository-url=https://repo.mage-os.org/ mage-os/project-community-edition .

# 5. Install Magento
orodc bin/magento setup:install \
  --base-url="${DOCKER_BASE_URL}" \
  --base-url-secure="${DOCKER_BASE_URL}" \
  --db-host="${ORO_DB_HOST:-database}" \
  --db-name="${ORO_DB_NAME:-app_db}" \
  --db-user="${ORO_DB_USER:-app_db_user}" \
  --db-password="${ORO_DB_PASSWORD:-app_db_pass}" \
  --admin-user=admin --admin-password=Admin123456 \
  --admin-email=admin@example.com --admin-firstname=Admin --admin-lastname=User \
  --backend-frontname=admin --language=en_US --currency=USD --timezone=America/New_York \
  --use-rewrites=1 --use-secure=1 --use-secure-admin=1 \
  --search-engine=opensearch --opensearch-host=search --opensearch-port=9200

# Access: https://mageos.docker.local/admin (admin / Admin123456)
```

📖 **For complete Magento setup guide, see [docs/MAGENTO.md](docs/MAGENTO.md)**

### 🚀 OroCommerce / OroPlatform Quick Start

```bash
# 1. Install OroDC
brew install digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform

# 2. Clone and setup OroCommerce
git clone --single-branch --branch 6.1.4 https://github.com/oroinc/orocommerce-application.git ~/orocommerce
cd ~/orocommerce

# 3. Install and start
orodc install && orodc up -d

# Alternative: Full installation command with custom parameters
orodc bin/console oro:install \
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

# Access: https://orocommerce.docker.local/admin (admin / 12345678)
```

📖 **For complete ORO Platform setup guide, see [docs/ORO.md](docs/ORO.md)**

## ⚠️ Critical Testing Requirements

**BEFORE running ANY tests:**
1. ✅ **MUST** run `orodc tests install` (independent setup)
2. ✅ **MUST** use `orodc tests` prefix for ALL test commands
3. ❌ **NEVER** run tests directly (e.g., `bin/phpunit`, `./bin/behat`)

**Example:**
```bash
# ✅ CORRECT
orodc tests install                       # Setup test environment
orodc tests bin/phpunit --testsuite=unit  # Run tests

# ❌ WRONG  
orodc bin/phpunit --testsuite=unit        # Don't do this
```

**Important Notes:**
- Test environment is **completely independent** from application installation
- You can run `orodc tests install` even without installing the main application
- Tests run in isolated containers separate from the main application

## 🎯 Smart PHP Integration

OroDC automatically detects and redirects PHP commands to the CLI container:

```bash
# All these work automatically - no need to specify 'cli'!
orodc -v                      # → cli php -v
orodc --version               # → cli php --version  
orodc script.php              # → cli php script.php
orodc -r 'phpinfo()'          # → cli php -r 'phpinfo()'
orodc bin/console cache:clear # → cli bin/console cache:clear

# Traditional way still works
orodc cli php -v           # Still supported
```

## 🗄️ Smart Database Integration

OroDC provides direct database access with automatic connection configuration:

```bash
# PostgreSQL commands (auto-configured with connection details)
orodc psql                          # Interactive PostgreSQL shell
orodc psql -l                       # List all databases
orodc psql -c "SELECT version();"   # Execute single SQL command
orodc psql -c "DROP DATABASE IF EXISTS test_db;"  # DDL operations
orodc psql -f backup.sql            # Execute SQL file

# MySQL commands (auto-configured with connection details)  
orodc mysql                         # Interactive MySQL shell
orodc mysql -e "SHOW DATABASES;"    # Execute single MySQL command
orodc mysql -e "USE oro_db; SHOW TABLES;"  # Multiple commands

# All database credentials are automatically configured!
# No need to specify host, port, username, or password
```

### Database Import with Domain Replacement

The `orodc database import` command supports automatic domain replacement in SQL dumps:

**Interactive Import Process:**

1. **Confirmation**: You'll be warned about database deletion and asked to confirm
2. **Domain Replacement**: Optionally replace domain names in the dump:
   - Source domain (e.g., `www.example.com`)
   - Target domain (defaults to `{project-name}.docker.local`)
   - Domains are automatically saved for future imports

**Domain Memory:**

- Previously used domains are saved to `~/.orodc/{project-name}/.env.orodc`
- On subsequent imports, saved domains are suggested as defaults
- Simply press Enter to use the saved values
- Settings are stored globally (never in project directory)

**Command-Line Options:**

```bash
# Import with domain replacement via flags
orodc database import dump.sql.gz --from-domain=www.example.com --to-domain=myproject.docker.local

# Interactive import (prompts for domains)
orodc database import dump.sql.gz

# Import from var/backup/ folder (interactive selection)
orodc database import
```

**Progress Display:**

- For PostgreSQL and MySQL: Shows progress bar using `pv` (pipe viewer) if available
- For custom containers without `pv`: Uses spinner for progress indication
- To enable `pv` progress: rebuild the database image for your database type

## 💻 Supported Systems

- **macOS**: Native Docker Desktop support with Mutagen sync
- **Linux**: Native Docker with default sync mode
- **Windows**: WSL2 with Docker Desktop integration

## 📦 Installation

### Via Homebrew (Recommended)

```bash
# Install OroDC
brew install digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform

# Verify installation
orodc help
```

## 🌐 Infrastructure Setup (Traefik + Dnsmasq + SSL)

OroDC uses **Traefik** as a reverse proxy and **Dnsmasq** for local DNS resolution, allowing you to access projects via `*.docker.local` domains with automatic SSL certificates.

### Prerequisites

You need to install Traefik and Dnsmasq from [homebrew-ngdev](https://github.com/digitalspacestdio/homebrew-ngdev):

```bash
# Add ngdev tap
brew tap digitalspacestdio/ngdev

# Install required infrastructure
brew install digitalspace-traefik digitalspace-dnsmasq digitalspace-local-ca

# Install allutils (helper scripts)
brew install digitalspace-allutils
```

### Platform-Specific Configuration

#### 🐧 Linux / WSL2 (Native Docker)

On Linux and WSL2 **without** Docker Desktop, Traefik runs natively on the host and connects directly to Docker containers.

**1. Enable Docker provider in Traefik:**

```bash
# Copy Traefik config
cp $(brew --prefix)/etc/traefik/traefik.toml $(brew --prefix)/etc/traefik/traefik.override.toml

# Edit traefik.override.toml and uncomment Docker provider section:
# [providers.docker]
#   endpoint = "unix:///var/run/docker.sock"
#   exposedByDefault = false
```

**2. Start services:**

```bash
# Start Dnsmasq
digitalspace-dnsmasq-start

# Start Traefik (will use traefik.override.toml if exists)
digitalspace-traefik-start

# Verify services are running
digitalspace-supctl status
```

**Architecture:** `Browser → Traefik (host) → Nginx (container)`

#### 🍎 macOS / 🪟 WSL2 + Docker Desktop

On macOS and WSL2 **with** Docker Desktop, Docker runs in a VM, so you need a **two-stage Traefik setup**:
- **Traefik (host)** - receives requests from browser
- **Traefik (docker)** - runs inside Docker, routes to containers

**1. Install Traefik (host):**

```bash
# Install and start host Traefik
brew install digitalspace-traefik
digitalspace-dnsmasq-start
digitalspace-traefik-start
```

**2. Enable Docker proxy config:**

```bash
# Create Traefik config for Docker proxy
digitalspace-traefik-enable-docker-proxy
```

This creates a configuration that proxies `*.docker.local` requests from host Traefik to Docker Traefik.

**3. Start Traefik inside Docker:**

Use the built-in OroDC command to manage Traefik proxy:

```bash
# Start Traefik proxy (detached mode)
orodc proxy up -d

# Install CA certificates to system trust store (optional)
orodc proxy install-certs

# Stop proxy (keeps volumes)
orodc proxy down

# Remove proxy and volumes
orodc proxy purge
```

**Configuration:** See [docker-compose-proxy.yml](compose/docker-compose-proxy.yml) in the repository for the complete Traefik configuration.

**Architecture:** `Browser → Traefik (host) → Traefik (docker) → Nginx (container)`

### SSL Certificate Setup

Install the self-signed root certificate to avoid browser security warnings.

#### 🚀 Automatic Installation (Recommended for Docker Proxy)

If you're using OroDC's built-in Traefik proxy (`orodc proxy up -d`), use the automatic installer:

```bash
# Start proxy and install certificates automatically
orodc proxy up -d
orodc proxy install-certs
```

This command automatically:
- ✅ Detects your OS (macOS, Linux, WSL2)
- ✅ Installs CA certificate to system trust store
- ✅ Configures NSS database for Chrome/Node.js (if certutil available)
- ✅ Provides Windows instructions for WSL2 users

#### 📋 Manual Installation (For Traefik on Host)

If you're using `digitalspace-traefik` on the host system:

##### macOS

```bash
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain \
  $(brew --prefix)/etc/openssl/localCA/root_ca.crt
```

##### Linux (Debian/Ubuntu/WSL2)

```bash
# Install certificate
sudo mkdir -p /usr/local/share/ca-certificates/extra
sudo cp $(brew --prefix)/etc/openssl/localCA/root_ca.crt /usr/local/share/ca-certificates/extra/
sudo update-ca-certificates

# For Chrome/Chromium (NSS database)
sudo apt install libnss3-tools
mkdir -p $HOME/.pki/nssdb
certutil -d $HOME/.pki/nssdb -N
certutil -d sql:$HOME/.pki/nssdb -A -t "C,," -n "Local Development" \
  -i $(brew --prefix)/etc/openssl/localCA/root_ca.crt
```

##### Linux (Fedora/RHEL/WSL2)

```bash
# Convert to PEM
openssl x509 -in $(brew --prefix)/etc/openssl/localCA/root_ca.crt \
  -out /tmp/root_ca.pem -outform PEM

# Install certificate
sudo mv /tmp/root_ca.pem /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust
```

##### Windows (Host OS for WSL2)

For browsers on Windows host to trust the certificate:

**Option 1: Using Windows Explorer (GUI)**

```bash
# From WSL2: Copy certificate to Windows
cp /home/linuxbrew/.linuxbrew/etc/openssl/localCA/root_ca.crt /mnt/c/Users/$USER/Downloads/
```

Then on Windows:
1. Open File Explorer → `C:\Users\YourUsername\Downloads\`
2. Right-click `root_ca.crt` → **Install Certificate**
3. Select **Local Machine** (requires Administrator) → **Next**
4. Select **Place all certificates in the following store** → **Browse**
5. Choose **Trusted Root Certification Authorities** → **OK**
6. Click **Next** → **Finish**
7. Accept the security warning
8. **Restart all browsers** for changes to take effect

**Option 2: Using PowerShell (Administrator)**

```bash
# From WSL2: Copy certificate to Windows temp
cp /home/linuxbrew/.linuxbrew/etc/openssl/localCA/root_ca.crt /mnt/c/Temp/root_ca.crt
```

Then open **PowerShell as Administrator** on Windows:

```powershell
# Import certificate to Trusted Root store
Import-Certificate -FilePath "C:\Temp\root_ca.crt" -CertStoreLocation Cert:\LocalMachine\Root

# Verify installation
Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object {$_.Subject -like "*Local Development*"}
```

**Important Notes:**
- You must install on **Windows Host** for Windows browsers
- WSL2 certificate installation only affects browsers **inside** WSL2
- After installation, **restart all browsers** completely

### Verification

After setup, verify infrastructure is working:

```bash
# Check services status
digitalspace-supctl status

# Should show:
# - traefik: RUNNING
# - dnsmasq: RUNNING

# Test DNS resolution
nslookup test.docker.local
# Should resolve to 127.0.0.1

# Test Traefik
curl -I http://localhost:8880
# Should return Traefik response
```

### Troubleshooting Infrastructure

**DNS not resolving:**
```bash
# Restart Dnsmasq
digitalspace-dnsmasq-restart

# Check DNS server
scutil --dns | grep nameserver  # macOS
cat /etc/resolv.conf            # Linux
```

**Traefik not routing:**
```bash
# Check Traefik logs
tail -f $(brew --prefix)/var/log/traefik.log

# Restart Traefik
digitalspace-traefik-restart

# On macOS/Docker Desktop - check Docker Traefik
docker logs traefik_docker_local
```

**Certificate warnings:**
- Re-run certificate installation steps
- Restart your browser completely
- Clear browser SSL cache

## 📖 Usage

### 🚀 Basic Commands

```bash
# Get help and documentation
orodc help                   # Show full documentation (README)
orodc man                    # Alternative help command
orodc version                # Show OroDC version

# Interactive menu (runs automatically when no arguments)
orodc                        # Launch interactive menu

# Environment management
orodc init                   # Initialize new environment
orodc list                   # List and switch between environments

# Start the environment
orodc up -d

# Install application (only once)
orodc install

# Configuration
orodc conf domains           # Manage domains interactively
orodc conf url               # Configure application URL interactively

# Connect via SSH
orodc ssh

# Stop the environment
orodc down
```

### 📦 Command Structure

OroDC uses a modular command structure with convenient aliases:

#### Docker Compose Commands

```bash
# Full syntax (explicit)
orodc compose up -d              # Start services
orodc compose down               # Stop services
orodc compose ps                 # List services
orodc compose logs -f            # Follow logs
orodc compose build              # Build images

# Convenient aliases (recommended)
orodc start                      # Same as: orodc compose up -d
orodc up                         # Same as: orodc compose up
orodc down                       # Same as: orodc compose down
orodc ps                         # Same as: orodc compose ps
orodc logs                       # Same as: orodc compose logs
orodc stop                       # Same as: orodc compose stop
orodc restart                    # Same as: orodc compose restart
```

#### Database Commands

```bash
# Full syntax
orodc database mysql             # MySQL CLI
orodc database psql              # PostgreSQL CLI
orodc database import            # Import database (with domain replacement)
orodc database export            # Export database
orodc database cli               # Database CLI bash

# Convenient aliases (recommended)
orodc mysql                      # Same as: orodc database mysql
orodc psql                       # Same as: orodc database psql
orodc cli                        # Same as: orodc database cli
```

#### Other Command Groups

```bash
# Installation
orodc install                    # Install with demo data
orodc install without demo       # Install without demo data

# Alternative: Full installation command (Oro Platform)
orodc bin/console oro:install \
  --env=prod \
  --timeout=1800 \
  --language=en \
  --formatting-code=en_US \
  --organization-name="Acme Inc." \
  --user-name="admin" \
  --user-email="admin@{project_name}.local" \
  --user-firstname="Admin" \
  --user-lastname="User" \
  --user-password="\$ecretPassw0rd" \
  --application-url="https://{project_name}.docker.local/" \
  --sample-data=y                # Use --sample-data=n for installation without demo data

# Environment management
orodc init                       # Initialize environment
orodc status                     # Show project status (initialization, CMS type, codebase)
orodc list                       # List all environments (interactive)
orodc list table                 # List environments as table (non-interactive)
orodc list json                  # List environments as JSON (non-interactive)

# Configuration
orodc conf domains               # Manage domains (interactive)
orodc conf domains list          # List domains (non-interactive)
orodc conf domains add <domain>  # Add domain (non-interactive)
orodc conf domains remove <domain> # Remove domain (non-interactive)
orodc conf domains set <list>    # Set domains list (non-interactive)
orodc conf url                   # Configure URL (interactive)
orodc conf url <url>             # Set URL (non-interactive)

# Cache management
orodc cache clear                # Clear cache
orodc cache warmup               # Warm up cache

# Platform operations
orodc platform-update            # Update platform

# AI Assistant Integration
orodc agents                     # Access AI agent documentation and prompts
orodc agents installation        # Show installation guide (common + CMS-specific)
orodc agents rules               # Show coding rules (common + CMS-specific)
orodc agents common              # Show common instructions
orodc agents <cms-type>          # Show CMS-specific instructions (oro, magento, etc.)
orodc codex                      # Launch Codex CLI with OroDC context
orodc gemini                     # Launch Gemini CLI with OroDC context
orodc cursor                     # Launch Cursor AI with OroDC context

# Cleanup and maintenance
orodc purge                      # Complete cleanup
orodc config-refresh             # Refresh configuration

# Development tools
orodc ssh                        # SSH into container
orodc php <args>                 # Run PHP commands
orodc composer <cmd>             # Run Composer
```

### 🎮 Interactive Menu

OroDC provides an interactive menu for easy access to all commands:

```bash
# Launch interactive menu (runs automatically when no arguments provided)
orodc

# Or explicitly
orodc menu
```

**Menu Options:**
- **Environment Management:**
  - List all environments
  - Initialize environment
  - Start/Stop/Delete environment
  - Image build

- **Configuration:**
  - Add/Manage domains
  - Configure application URL

- **Database:**
  - Export database
  - Import database

- **Maintenance:**
  - Clear cache
  - Platform update
  - Run doctor (show ps)
  - Connect via SSH/CLI

- **Proxy:**
  - Start/Stop proxy

- **Installation:**
  - Install with/without demo data

**Universal Commands:**
All menu options correspond to CLI commands, working in both interactive and non-interactive modes:

```bash
# Interactive mode (shows prompts)
orodc list                       # Interactive environment selection
orodc conf domains               # Interactive domain management
orodc conf url                   # Interactive URL configuration

# Non-interactive mode (for scripts)
orodc list table                 # Table output
orodc list json                  # JSON output
orodc conf domains add api       # Add domain directly
orodc conf domains remove api    # Remove domain directly
orodc conf url https://example.com # Set URL directly
```

**Exit Codes:**
All commands return proper exit codes:
- `0` - Success
- `1` - Error
- `2` - Special case (e.g., environment switch in `list` command)

Exit codes are displayed in interactive menu and can be used in scripts:
```bash
if orodc conf domains add api; then
  echo "Domain added successfully"
else
  echo "Failed to add domain (exit code: $?)"
fi
```

### 🎯 Smart PHP Commands & Flags

OroDC automatically detects PHP commands and flags:

```bash
# PHP version and info
orodc --version              # Check PHP version
orodc -v                     # Short version
orodc -m                     # Show loaded modules
orodc -i                     # Show PHP info

# Execute PHP code directly
orodc -r 'echo "Hello World!";'
orodc -r 'var_dump(get_loaded_extensions());'

# Run PHP scripts directly
orodc script.php
orodc -l syntax-check.php

# Console commands (Symfony/Oro/Laravel)
orodc bin/console cache:clear        # Symfony/Oro
orodc php artisan cache:clear        # Laravel
orodc bin/magento cache:clean        # Magento
```

## 🧪 Testing

### Test Environment Setup

**CRITICAL**: Test environment is completely separate from your main application:

```bash
# Navigate to your application directory
cd ~/myproject

# ⚠️ REQUIRED: Set up test environment (one-time setup)
orodc tests install
```

### Running Tests

**ALL tests MUST use `orodc tests` prefix:**

#### Unit Tests
```bash
orodc tests bin/phpunit --testsuite=unit
orodc tests bin/phpunit --testsuite=unit --filter=UserTest
orodc tests bin/phpunit tests/Unit/Entity/UserTest.php
```

#### Functional Tests
```bash
orodc tests bin/phpunit --testsuite=functional
orodc tests bin/phpunit --testsuite=functional --filter=ApiTest
```

#### Behat Tests
```bash
orodc tests bin/behat --available-suites        # List available suites
orodc tests bin/behat --suite=default           # Run default suite
orodc tests bin/behat features/user.feature     # Run specific feature
```

> 📖 **CMS-specific test examples**: See [docs/ORO.md](docs/ORO.md) for Oro Platform testing (OroUserBundle, OroCustomerBundle, etc.)

### Available Test Commands

#### Test Coverage
```bash
# Generate coverage report
orodc tests bin/phpunit --testsuite=unit --coverage-html coverage/
orodc tests bin/phpunit --coverage-text
```

#### Custom Test Configuration
```bash
# Run with specific configuration
orodc tests bin/phpunit -c phpunit.xml.dist
orodc tests bin/phpunit --bootstrap tests/bootstrap.php
```

#### Test Environment Management
```bash
# Check test environment status
orodc tests ps

# View test logs
orodc tests logs
orodc tests logs cli

# Start/stop test services
orodc tests up -d
orodc tests down

# Reset test environment
orodc tests down
orodc tests install  # Reinstall test environment

# Clean test environment
orodc tests purge
```

#### Test Database Operations
```bash
# Access test database
orodc tests psql

# Run test database commands
orodc tests psql -c "SELECT version();"
orodc tests psql -l  # List databases
```

### 🔧 Development Commands

```bash
# Composer commands (automatically run with --no-interaction)
orodc composer install
orodc composer update
orodc composer require package/name

# Database operations
orodc importdb database.sql.gz       # Import database (with domain replacement)
orodc exportdb                       # Export database
orodc platformupdate                 # Update platform
orodc updateurl                      # Update URLs

# Asset management & cache
orodc bin/console cache:clear                  # Symfony/Oro
orodc bin/magento cache:clean                  # Magento
orodc npm run build                            # Generic frontend

# Other tools
orodc database-cli                   # Direct database access
orodc ssh                           # SSH into container

# Proxy management
orodc proxy up -d                    # Start Traefik reverse proxy
orodc proxy install-certs            # Install CA certificates to system
orodc proxy down                     # Stop proxy (keeps volumes)
orodc proxy purge                    # Remove proxy and volumes
```

### 🤖 AI Assistant Integration

OroDC provides seamless integration with AI coding assistants (Codex, Gemini, Cursor) and a dedicated command for accessing agent documentation.

#### 📚 Agent Documentation: `orodc agents`

The `orodc agents` command provides access to AI agent documentation, installation guides, and coding rules:

```bash
# Show installation guide (common + CMS-specific)
orodc agents installation

# Show coding rules (common + CMS-specific)
orodc agents rules

# Show common instructions
orodc agents common

# Show CMS-specific instructions
orodc agents oro              # Oro Platform
orodc agents magento          # Magento
orodc agents laravel          # Laravel
orodc agents symfony          # Symfony
```

**Available CMS types:** `oro`, `magento`, `laravel`, `symfony`, `wintercms`, `php-generic`

**Smart Common Detection:**
- CMS-specific files that reference common parts automatically include common content
- Self-contained CMS files are shown without redundant common content
- Auto-detects CMS type if not specified

**Use Cases:**
- **Installing a new project?** → Run `orodc agents installation` first
- **Need coding guidelines?** → Run `orodc agents rules` for complete standards
- **CMS-specific commands?** → Run `orodc agents <cms-type>` for framework-specific instructions

#### 🚀 AI Proxy Commands: `orodc codex`, `orodc gemini`, `orodc cursor`

Launch AI coding assistants with OroDC context automatically configured:

```bash
# Launch Codex CLI with OroDC context
orodc codex

# Launch Gemini CLI with OroDC context
orodc gemini

# Launch Cursor AI with OroDC context
orodc cursor
```

**What These Commands Do:**

1. **Detect CMS type** from project files or `.env.orodc`
2. **Copy agent files** to `~/.orodc/{project_name}/`
3. **Generate system prompt** with:
   - Common instructions (from `AGENTS_common.md`)
   - References to CMS-specific instructions via `orodc agents` commands
   - Project context (name, URL, directory)
   - Environment information
4. **Launch AI agent** with the generated system prompt

**CMS Type Detection:**

Automatically detects CMS type:
- **Oro Platform**: Detects `oro/platform`, `oro/commerce`, `oro/crm`, etc. in `composer.json`
- **Magento**: Detects `magento/product-*` packages or Magento-specific files
- **Symfony**: Detects `symfony/symfony` or `symfony/framework-bundle`
- **Laravel**: Detects `laravel/framework`
- **PHP Generic**: Default for other PHP projects

**Configuration:**

You can explicitly set CMS type in `.env.orodc`:
```bash
DC_ORO_CMS_TYPE=oro          # Force Oro Platform
DC_ORO_CMS_TYPE=magento      # Force Magento
DC_ORO_CMS_TYPE=symfony      # Force Symfony
DC_ORO_CMS_TYPE=laravel      # Force Laravel
DC_ORO_CMS_TYPE=php-generic  # Force generic PHP
```

**Features:**

- ✅ Auto-detects CMS type from project files
- ✅ Provides OroDC documentation context to AI agents
- ✅ Constrains AI agents to use only OroDC commands
- ✅ CMS-aware system prompts for better assistance
- ✅ Works with or without explicit CMS type configuration
- ✅ On-demand documentation access via `orodc agents` commands

**Example:**

```bash
# In an OroCommerce project
cd ~/orocommerce

# Get installation guide
orodc agents installation

# Launch AI assistant with context
orodc codex
# AI assistant receives:
# - CMS type: oro
# - OroDC documentation context
# - Instructions to use orodc commands
# - References to `orodc agents` for detailed docs

# Ask AI questions about your OroDC project
# AI will suggest orodc commands instead of direct Docker commands
```

**Installation:**

AI CLI tools must be installed separately:
- **Codex CLI**: Check [Codex CLI documentation](https://github.com/context7/codex-cli) for installation
- **Gemini CLI**: Check Gemini CLI documentation for installation
- **Cursor**: Usually pre-installed with Cursor IDE

### 🔌 Reverse Proxy Management

OroDC includes built-in commands to manage Traefik reverse proxy inside Docker. This is useful for **macOS** and **WSL2 + Docker Desktop** users (where Docker runs in a VM).

**Proxy Commands:**

```bash
# Start Traefik proxy
orodc proxy up -d                    # Start in detached mode (interactive prompts)
orodc proxy up                       # Start with logs (foreground)

# Non-interactive mode (CI/CD, scripts) - uses defaults
echo "" | orodc proxy up -d          # Auto-uses: 127.0.0.1, port 1080

# Skip prompts with environment variables
export TRAEFIK_BIND_ADDRESS=127.0.0.1
export DC_PROXY_SOCKS5_PORT=1080
orodc proxy up -d

# Install CA certificates (optional, for HTTPS)
orodc proxy install-certs            # Auto-installs to system trust store

# Stop proxy
orodc proxy down                     # Stop proxy (keeps volumes)

# Remove proxy completely
orodc proxy purge                    # Remove proxy and all volumes

# With DEBUG logging
DEBUG=1 orodc proxy up -d
```

**Non-Interactive Defaults:**
- Bind address: `127.0.0.1` (or `0.0.0.0` if WSL2/Lima VM detected)
- SOCKS5 port: `1080`

**Features:**
- 🎯 Dashboard: <http://localhost:8880/traefik/dashboard/>
- 🌐 Auto-routes all `*.docker.local` domains to OroDC containers
- 🔒 Built-in SSL/TLS with self-signed certificates
- 🧪 SOCKS5 proxy on `127.0.0.1:1080` for direct container access
- 💾 Persistent certificate storage in Docker volumes
- 🏥 Built-in health monitoring

**Ports:**
- HTTP: `8880` (host) → `80` (proxy)
- HTTPS: `8443` (host) → `443` (proxy)
- SOCKS5: `1080` (localhost only)

**HTTPS Support:**
After starting the proxy, install CA certificates to avoid browser warnings:

```bash
orodc proxy install-certs
```

This automatically:
- Exports CA certificate from proxy container
- Installs to system trust store (macOS/Linux/WSL2)
- Configures NSS database for Chrome/Node.js
- Provides Windows installation instructions (for WSL2)

**Configuration:** See [docker-compose-proxy.yml](compose/docker-compose-proxy.yml) for complete Traefik configuration.

**Note:** For native Traefik installation (Linux), see [Infrastructure Setup](#-infrastructure-setup-traefik--dnsmasq--ssl) section.

### 🎯 Docker Compose Profiles

```bash
# Enable XHProf profiling (xhgui + mongodb)
orodc --profile=xhprof up -d
```

### 🔄 Consumer/Workers

Consumer is **auto-started for Oro projects**. For other CMS, run manually:

```bash
orodc bin/console messenger:consume           # Symfony
orodc bin/magento queue:consumers:start       # Magento
```

## 🌐 Multiple Hosts Configuration

OroDC supports multiple hostnames for your application, perfect for multisite setups, API endpoints, or different access points.

> **⚠️ Prerequisites:** Custom domains (like `*.docker.local`) require [Traefik + Dnsmasq infrastructure](#-infrastructure-setup-traefik--dnsmasq--ssl) to be installed and running. Without it, you can only access via `localhost` with port numbers.

### 🚀 Quick Examples

```bash
# Single additional host
export DC_ORO_EXTRA_HOSTS="api"
orodc up -d
# Access: myproject.docker.local + api.docker.local

# Multiple hosts (comma-separated)
export DC_ORO_EXTRA_HOSTS="api,admin,shop"
orodc up -d
# Access: myproject.docker.local + api.docker.local + admin.docker.local + shop.docker.local

# Mixed short and full hostnames
export DC_ORO_EXTRA_HOSTS="api,admin.myproject.local,external.example.com"
orodc up -d
# Access: myproject.docker.local + api.docker.local + admin.myproject.local + external.example.com
```

### 🎯 Smart Hostname Processing

OroDC automatically processes hostnames for maximum convenience:

- **Short names** (single words) → automatically get `.docker.local` suffix
- **Full hostnames** (with dots) → used as-is
- **Whitespace** → automatically trimmed
- **Empty entries** → automatically ignored

### 📝 Configuration Methods

#### Method 1: Interactive Command (Recommended)
```bash
# Interactive mode - shows current domains and allows adding/removing
orodc conf domains

# Or use the interactive menu
orodc
# Select: 7) Add/Manage domains
```

#### Method 2: Non-Interactive Commands
```bash
# List current domains
orodc conf domains list

# Add domain
orodc conf domains add api
orodc conf domains add admin
orodc conf domains add shop

# Remove domain
orodc conf domains remove api

# Set multiple domains at once
orodc conf domains set "api,admin,shop"

# Then restart environment
orodc up -d
```

#### Method 3: Environment Variable
```bash
export DC_ORO_EXTRA_HOSTS="api,admin,shop"
orodc up -d
```

#### Method 4: .env.orodc File
```bash
echo 'DC_ORO_EXTRA_HOSTS=api,admin,shop' >> .env.orodc
orodc up -d
```

#### Method 5: Project-specific Configuration
```bash
# In your project directory
echo 'DC_ORO_EXTRA_HOSTS=api,admin,shop.local' > .env.orodc
orodc up -d
```

### 🌟 Use Cases

#### API & Admin Separation
```bash
# Separate API and admin interfaces
DC_ORO_EXTRA_HOSTS="api,admin"
# Access:
# - Main site: myproject.docker.local
# - API: api.docker.local  
# - Admin: admin.docker.local
```

#### Multisite E-commerce
```bash
# Multiple storefronts
DC_ORO_EXTRA_HOSTS="shop1,shop2,wholesale"
# Access:
# - Main: myproject.docker.local
# - Shop 1: shop1.docker.local
# - Shop 2: shop2.docker.local  
# - Wholesale: wholesale.docker.local
```

#### Development & Staging
```bash
# Different environments on same instance
DC_ORO_EXTRA_HOSTS="dev,staging,demo"
# Access:
# - Production-like: myproject.docker.local
# - Development: dev.docker.local
# - Staging: staging.docker.local
# - Demo: demo.docker.local
```

### 🔧 Technical Details

- **Traefik Integration**: Automatically generates `Host()` rules for all hostnames
- **Load Balancing**: All hosts point to the same application instance
- **SSL/TLS**: Works with existing SSL certificate configuration
- **Performance**: No performance impact - handled at routing level

### 🆘 Troubleshooting

```bash
# Check generated Traefik rule
echo $DC_ORO_TRAEFIK_RULE

# Debug hostname processing
DEBUG=1 orodc up -d

# Reset configuration
unset DC_ORO_EXTRA_HOSTS
orodc down && orodc up -d
```

### 🔗 Application URL Configuration

OroDC allows you to configure the application URL for proper routing and access:

```bash
# Interactive mode (recommended)
orodc conf url

# Or use the interactive menu
orodc
# Select: 8) Configure application URL
```

**Non-Interactive Mode:**
```bash
# Show current URL
orodc conf url

# Set new URL
orodc conf url https://myproject.local
orodc conf url http://localhost:30280

# URL must start with http:// or https://
```

**Configuration Methods:**
```bash
# Method 1: Interactive command
orodc conf url

# Method 2: Environment variable
export DC_ORO_URL=https://myproject.local
orodc up -d

# Method 3: .env.orodc file
echo 'DC_ORO_URL=https://myproject.local' >> .env.orodc
orodc up -d
```

**Default URL:**
- If not configured, defaults to: `https://${DC_ORO_NAME}.docker.local`
- Example: If `DC_ORO_NAME=myproject`, default URL is `https://myproject.docker.local`

## ⚙️ Environment Variables

### 🔧 Complete Environment Variables Reference

#### 🏗️ Project Configuration
```bash
# Project identity
DC_ORO_NAME=unnamed                # Project name (default: unnamed)
DC_ORO_PORT_PREFIX=302             # Port prefix (302 → 30280, 30243, etc.)

# Application URL
DC_ORO_URL=https://myproject.docker.local  # Application URL (default: https://${DC_ORO_NAME}.docker.local)

# Multiple hosts configuration
DC_ORO_EXTRA_HOSTS=api,admin,shop  # Additional hostnames (comma-separated)

# Application directory
DC_ORO_APPDIR=/var/www             # Application directory in container
```

#### 🐳 PHP & Runtime Configuration  
```bash
# PHP settings
DC_ORO_PHP_VERSION=8.4             # PHP version (7.4, 8.1, 8.2, 8.3, 8.4, 8.5)
DC_ORO_NODE_VERSION=22             # Node.js version (18, 20, 22)
DC_ORO_COMPOSER_VERSION=2          # Composer version (1, 2)
DC_ORO_PHP_DIST=alpine             # Base distribution (alpine)

# PHP user settings
DC_ORO_PHP_USER_NAME=developer     # PHP user name
DC_ORO_PHP_USER_GROUP=developer    # PHP user group
DC_ORO_PHP_UID=1000                # PHP user UID
DC_ORO_PHP_GID=1000                # PHP user GID
DC_ORO_USER_NAME=developer         # Runtime user name
```

#### 🗄️ Database Configuration
```bash
# PostgreSQL settings (default database)
DC_ORO_DATABASE_HOST=database      # Database host
DC_ORO_DATABASE_PORT=5432          # Database port
DC_ORO_DATABASE_USER=app_db_user   # Database user
DC_ORO_DATABASE_PASSWORD=app_db_pass # Database password  
DC_ORO_DATABASE_DBNAME=app_db      # Database name
DC_ORO_DATABASE_SCHEMA=postgres    # Database type (postgres/mysql)

# Connection URI (auto-generated)
DC_ORO_DATABASE_URI=postgres://app_db_user:app_db_pass@database:5432/app_db
```

#### 🔍 Search & Cache Configuration
```bash
# Elasticsearch settings
DC_ORO_SEARCH_DSN=elastic-search://search:9200
DC_ORO_SEARCH_URI=elastic-search://search:9200

# Redis settings  
DC_ORO_REDIS_URI=redis://redis:6379

# Message Queue settings
DC_ORO_MQ_URI=""                   # Message queue URI (empty = use DB)
```

#### 📧 Mail & Debugging

The mail service (Mailpit) supports both encrypted and unencrypted SMTP connections for testing email functionality locally.

**Mail Service Access:**
- Web UI: `http://localhost:8025` or via Traefik at `https://<project>.docker.local/mailbox`
- SMTP Port 1025: Unencrypted (default, backward compatible)
- SMTP Port 465: Implicit TLS (encrypted from start)
- SMTP Port 587: STARTTLS (encryption negotiated after connection)

**Mail Configuration:**

```bash
# Unencrypted SMTP (default, backward compatible)
ORO_MAILER_DRIVER=smtp
ORO_MAILER_HOST=mail
ORO_MAILER_PORT=1025
ORO_MAILER_ENCRYPTION=""           # Empty or "none" for unencrypted

# STARTTLS (recommended for production-like testing)
ORO_MAILER_DRIVER=smtp
ORO_MAILER_HOST=mail
ORO_MAILER_PORT=587
ORO_MAILER_ENCRYPTION=starttls     # STARTTLS encryption

# Implicit TLS (legacy but secure)
ORO_MAILER_DRIVER=smtp
ORO_MAILER_HOST=mail
ORO_MAILER_PORT=465
ORO_MAILER_ENCRYPTION=tls          # Implicit TLS encryption

# Authentication (not required for local dev)
ORO_MAILER_USER=""                 # Mail username (unused in dev)
ORO_MAILER_PASSWORD=""             # Mail password (unused in dev)
```

**TLS Certificate Management:**
- Certificates are automatically generated on first mail service start
- Self-signed certificates are stored in the `mail-certs` Docker volume
- PHP containers automatically mount certificates read-only at `/certs/mail.crt`
- Certificates persist across container restarts

**Testing Email Sending:**

```bash
# Test unencrypted SMTP (port 1025)
echo "Subject: Test\n\nUnencrypted email" | orodc exec fpm msmtp -t test@example.com

# Test STARTTLS (port 587)
# Set ORO_MAILER_PORT=587 and ORO_MAILER_ENCRYPTION=starttls in .env.orodc
# Then restart containers: orodc restart
echo "Subject: Test STARTTLS\n\nSTARTTLS email" | orodc exec fpm msmtp -t test@example.com

# Test implicit TLS (port 465)
# Set ORO_MAILER_PORT=465 and ORO_MAILER_ENCRYPTION=tls in .env.orodc
# Then restart containers: orodc restart
echo "Subject: Test TLS\n\nTLS email" | orodc exec fpm msmtp -t test@example.com
```

**Troubleshooting:**

- **"certificate verify failed"**: Check that `/certs/mail.crt` exists in PHP containers
- **"connection refused"**: Verify mail service is running: `orodc ps | grep mail`
- **"wrong version number"**: Port/encryption mismatch (e.g., port 1025 with TLS enabled)
- **"encryption is not supported"**: Use port 1025 with `ORO_MAILER_ENCRYPTION=""` or upgrade to mailpit

# Security
ORO_SECRET=ThisTokenIsNotSoSecretChangeIt  # Application secret

# Features
ORO_ENABLE_PRICE_SHARDING=0        # Enable price sharding (0 or 1)

# Composer
DC_ORO_COMPOSER_AUTH=""            # Composer authentication JSON
```

#### 🔌 WebSocket Configuration
```bash
# WebSocket server settings (where WS server listens)
DC_ORO_WEBSOCKET_SERVER_DSN=//0.0.0.0:8080

# WebSocket frontend settings (public URL for browser connections)
DC_ORO_WEBSOCKET_FRONTEND_DSN=//${DC_ORO_NAME}.docker.local/ws

# WebSocket backend settings (internal container communication)
DC_ORO_WEBSOCKET_BACKEND_DSN=tcp://websocket:8080
```

**Notes:**
- `WEBSOCKET_SERVER_DSN`: Internal address where WebSocket server binds (port 8080)
- `WEBSOCKET_FRONTEND_DSN`: Public URL for browser WebSocket connections (uses project domain, auto-detects HTTP/HTTPS)
- `WEBSOCKET_BACKEND_DSN`: TCP address for PHP backend to connect to WebSocket server
- Frontend DSN format: `//hostname/path` - no port means browser auto-detects (80 for HTTP, 443 for HTTPS)
- Default uses `${DC_ORO_NAME}.docker.local/ws` - customize for production domains
- All containers (fpm, cli, consumer, websocket) are configured with these variables
- Nginx and Traefik automatically proxy `/ws` path to WebSocket server on port 8080

**Examples:**
```bash
# Local development (default)
DC_ORO_WEBSOCKET_FRONTEND_DSN=//myproject.docker.local/ws

# Production with custom domain
DC_ORO_WEBSOCKET_FRONTEND_DSN=//example.com/ws

# Subdomain
DC_ORO_WEBSOCKET_FRONTEND_DSN=//app.example.com/ws
```

### 📁 Sync Modes

#### 🐧 `default` Mode (Linux/WSL Default)
- **Best for**: Linux, WSL2
- **Performance**: Excellent
- **Setup**: Zero configuration

```bash
echo "DC_ORO_MODE=default" >> .env.orodc
```

#### 🍎 `mutagen` Mode (macOS Default)
- **Best for**: macOS
- **Performance**: Excellent (avoids slow Docker filesystem)
- **Setup**: Requires Mutagen installation

```bash
echo "DC_ORO_MODE=mutagen" >> .env.orodc
brew install mutagen-io/mutagen/mutagen
```

#### 🔗 `ssh` Mode (Remote/Special Cases)
- **Best for**: Remote Docker, antivirus issues
- **Performance**: Good
- **Setup**: SSH key configuration

```bash
echo "DC_ORO_MODE=ssh" >> .env.orodc
```

## 🐳 Custom Docker Images

### 🏗️ Building PHP+Node.js Images Locally

OroDC provides a built-in command to build PHP+Node.js Docker images locally. This is useful when:
- GitHub Container Registry is unavailable or blocked
- Custom PHP or Node.js versions are required
- Testing Dockerfile changes before CI/CD deployment
- Working in air-gapped or restricted network environments

#### ⚡ Quick Build

```bash
# Build images for current project configuration
orodc image build

# Build without cache (full rebuild)
orodc image build --no-cache
```

#### 📋 How It Works

The `orodc image build` command:

1. **Detects versions** from your project configuration (`.env.orodc` or defaults)
2. **Checks for existing images** locally to avoid unnecessary work
3. **Offers registry pull** (Stage 1): Interactive prompt to pull PHP base image from GitHub Container Registry
4. **Builds if needed** (Stage 1): Builds PHP base image locally if pull declined or failed
5. **Offers registry pull** (Stage 2): Interactive prompt to pull PHP+Node.js final image
6. **Builds if needed** (Stage 2): Builds final image locally if pull declined or failed
7. **Tags locally**: All images are tagged without registry prefix for local use

#### 🌐 Pull from Registry

When an image is not found locally, OroDC will ask if you want to try pulling from GitHub Container Registry:

```
PHP base image not found locally: orodc-php:8.3-alpine
Registry image: ghcr.io/digitalspacestdio/orodc-php:8.3-alpine

Try to pull from registry? (y/N):
```

**Benefits of pulling:**
- ⚡ Much faster than building (30 seconds vs 10 minutes)
- 💾 Saves disk space (no build cache needed)
- 🔄 Gets official pre-built images

**When to build locally:**
- Registry is unavailable or blocked
- Testing custom Dockerfile modifications
- Air-gapped environment without internet access

#### ⚙️ Version Configuration

Configure versions in `.env.orodc`:

```bash
# PHP and Node.js versions
DC_ORO_PHP_VERSION=8.3
DC_ORO_NODE_VERSION=20
DC_ORO_COMPOSER_VERSION=2
DC_ORO_PHP_DIST=alpine
```

Default versions (if not configured):
- PHP: 8.4
- Node.js: 22
- Composer: 2
- Distribution: alpine

#### 🎯 Using Locally Built Images

After building, force OroDC to use local images by adding to `.env.orodc`:

```bash
# Force local images (skip registry pull)
DC_ORO_PHP_REGISTRY=''
```

Then restart your environment:

```bash
orodc down
orodc up -d
```

#### 📦 Built Image Tags

The command builds two images:

1. **PHP Base Image**: `orodc-php:{version}-alpine`
   - Example: `orodc-php:8.3-alpine`
   - Size: ~1GB
   - Build time: 5-10 minutes

2. **PHP+Node.js Final Image**: `orodc-php-node-symfony:{php}-node{node}-composer{composer}-alpine`
   - Example: `orodc-php-node-symfony:8.3-node20-composer2-alpine`
   - Size: ~2GB
   - Build time: 5-10 minutes

#### 🔍 Available Versions

To see available PHP versions:

```bash
ls compose/docker/php/Dockerfile.*.alpine
# Output: Dockerfile.7.3.alpine, Dockerfile.7.4.alpine, etc.
```

Supported PHP versions: 7.3, 7.4, 8.1, 8.2, 8.3, 8.4, 8.5
Supported Node.js versions: 18, 20, 22
Supported Composer versions: 1, 2

#### 💾 Disk Space Requirements

- Minimum required: 5GB free space
- PHP base image: ~1GB
- PHP+Node.js final image: ~2GB
- Build cache: ~1-2GB

#### 🔄 Rebuilding Images

```bash
# Rebuild with cache (faster, reuses unchanged layers)
orodc image build

# Force complete rebuild without cache
orodc image build --no-cache
```

#### 🐛 Troubleshooting

**Build fails with "Dockerfile not found":**
- Check `DC_ORO_PHP_VERSION` in `.env.orodc`
- Run `ls compose/docker/php/Dockerfile.*.alpine` to see available versions

**Build fails with disk space error:**
- Check free space: `df -h`
- Clean Docker cache: `docker system prune -a`
- Remove unused images: `docker image prune -a`

**Build fails with network error:**
- Check internet connectivity
- Try rebuilding with `--no-cache`
- Check Docker daemon is running: `docker ps`

**Built images not used by OroDC:**
- Add `DC_ORO_PHP_REGISTRY=''` to `.env.orodc`
- Restart environment: `orodc down && orodc up -d`

### 🛠️ Building Custom PostgreSQL Image

You can create custom Docker images for any service and use them with OroDC. Here's an example of creating a PostgreSQL image with additional extensions:

#### 📋 Step 1: Create Dockerfile

Create a `Dockerfile` with your custom configuration:

```dockerfile
FROM postgres:17.4
RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends postgresql-17-pgpool2
```

#### 🔨 Step 2: Build Custom Image

Build your custom PostgreSQL image:

```bash
docker build -t mypgsql:17 .
```

#### ⚙️ Step 3: Configure OroDC

Add the custom image configuration to your project's `.env.orodc` file:

```bash
# Use custom PostgreSQL image
DC_ORO_PGSQL_IMAGE=mypgsql
DC_ORO_PGSQL_VERSION=17
```

Or set it in your application's `app/.env.local` file:

```bash
# Custom PostgreSQL configuration
DC_ORO_PGSQL_IMAGE=mypgsql  
DC_ORO_PGSQL_VERSION=17
```

#### 🚀 Step 4: Start with Custom Image

```bash
# Restart OroDC to use the custom image
orodc down
orodc up -d
```

### 🔧 All Available Custom Images

You can customize any service using these environment variables:

#### 🐘 Database Services
```bash
# PostgreSQL (primary database)
DC_ORO_PGSQL_IMAGE=mypgsql
DC_ORO_PGSQL_VERSION=17

# Redis (caching & sessions)  
DC_ORO_REDIS_IMAGE=myredis
DC_ORO_REDIS_VERSION=7.0

# Elasticsearch (search engine)
DC_ORO_ELASTICSEARCH_IMAGE=myelastic
DC_ORO_ELASTICSEARCH_VERSION=8.10.3

# MongoDB (for XHGui profiling)
DC_ORO_MONGODB_IMAGE=mymongo
DC_ORO_MONGODB_VERSION=4.4

# RabbitMQ (message queue)
DC_ORO_RABBITMQ_IMAGE=myrabbitmq
DC_ORO_RABBITMQ_VERSION=3.9-management-alpine
```

#### 🐳 PHP & Application Services
```bash
# PHP base image (affects fpm, cli, consumer, websocket, ssh)
DC_ORO_PHP_BASE_IMAGE=ghcr.io/digitalspacestdio/orodc-php-node-symfony
DC_ORO_PHP_VERSION=8.4              # PHP version (7.4, 8.1, 8.2, 8.3, 8.4, 8.5)
DC_ORO_NODE_VERSION=22              # Node.js version (18, 20, 22)  
DC_ORO_COMPOSER_VERSION=2           # Composer version (1, 2)
DC_ORO_PHP_DIST=alpine              # Base distribution (alpine)
```

#### 🌐 Web & Infrastructure Services
```bash
# Nginx (web server)
DC_ORO_NGINX_IMAGE=mynginx
DC_ORO_NGINX_VERSION=latest

# Mailpit (email testing) - replaced MailHog
DC_ORO_PORT_MAIL_SMTP=1025        # SMTP port (unencrypted)
DC_ORO_PORT_MAIL_SMTPS=30465     # SMTPS port (TLS)
DC_ORO_PORT_MAIL_WEBGUI=8025     # Web UI port

# XHGui (profiling interface)
DC_ORO_XHGUI_IMAGE=myxhgui
DC_ORO_XHGUI_VERSION=0.18.4
```

### 💡 Custom Image Tips

- **Layer Caching**: Build images locally for faster iteration during development
- **Registry**: Push custom images to a registry for team sharing
- **Environment Specific**: Use different custom images for development, staging, and production
- **Documentation**: Document custom image dependencies and build instructions

## 🐛 XDEBUG Configuration

### 🔍 XDEBUG Debugging Modes

OroDC supports flexible XDEBUG configuration for different debugging scenarios:

#### 📋 Enable XDEBUG for PHP-FPM Only
For debugging web requests only:

```bash
XDEBUG_MODE_FPM=debug orodc up -d
```

#### 💻 Enable XDEBUG for CLI Only  
For debugging console commands only:

```bash
XDEBUG_MODE_CLI=debug orodc up -d
```

#### 🌐 Enable XDEBUG Everywhere
For debugging both web requests and console commands:

```bash
XDEBUG_MODE=debug orodc up -d
```

#### 🎯 Enable XDEBUG with Service-Specific Control
For debugging in CLI and FPM containers, but disable in consumer workers:

```bash
XDEBUG_MODE=debug XDEBUG_MODE_CONSUMER=off orodc up -d
```

### 💡 XDEBUG Usage Tips

- **Performance**: Only enable XDEBUG when debugging - it significantly impacts performance
- **IDE Configuration**: Configure your IDE to listen on port 9003 (default XDEBUG 3.x port)
- **Path Mapping**: Map local project path to container path `/var/www/html`
- **Environment Persistence**: XDEBUG settings persist until containers are recreated

### 🔧 Reset XDEBUG Configuration

To disable XDEBUG and return to normal mode:

```bash
# Stop containers and restart without XDEBUG
orodc down
orodc up -d
```

## 🔄 Working with Existing Projects

### Quick Setup from Database Dump

```bash
# Navigate to your project
cd ~/myproject

# Complete project recreation (single command)
orodc purge && \
orodc importdb ~/backup.sql.gz && \
orodc platformupdate && \
orodc updateurl

# Access your application
open http://localhost:30280/
```

### Step-by-Step Setup

```bash
# 1. Start containers
orodc up -d

# 2. Import your database
orodc importdb database.sql.gz

# During import, you'll be prompted to:
# - Confirm database deletion (WARNING: This will DELETE ALL DATA)
# - Optionally replace domain names in the dump
#   - Source domain (e.g., www.example.com)
#   - Target domain (defaults to {project-name}.docker.local)
#   - Domains are saved to ~/.orodc/{project-name}/.env.orodc for future imports

# 3. Update URLs for local development
orodc updateurl

# 4. Update platform
orodc platformupdate

# 5. Access application
open http://localhost:30280/
```

## 🆘 Troubleshooting

### Common Issues

```bash
# Port conflicts
orodc down && orodc up -d
echo "DC_ORO_PORT_PREFIX=301" >> .env.orodc

# macOS performance issues
echo "DC_ORO_MODE=mutagen" >> .env.orodc
brew install mutagen-io/mutagen/mutagen

# Permission issues
orodc purge && orodc install

# Force purge without confirmation (CI/CD)
DC_ORO_PURGE_FORCE=1 orodc purge

# Check logs
orodc logs [service-name]

# Debug mode
DEBUG=1 orodc [command]
```

### ⚠️ Purge Command Safety

The `orodc purge` command requires confirmation before deleting data:

```bash
# Interactive mode (asks for confirmation)
orodc purge
# Output shows warning and prompts: Are you sure? [y/N]

# Non-interactive mode (CI/CD, scripts)
DC_ORO_PURGE_FORCE=1 orodc purge
# Proceeds without asking
```

**What gets deleted:**
- All Docker containers for the project
- All Docker volumes (database data, uploads, cache)
- All project-specific Docker images
- Configuration directory (`~/.orodc/project-name`)

**Data that survives purge:**
- Your application source code
- `.env.orodc` configuration file
- Git repository and commits
```

### 🔇 Clean Output Mode (Default)

By default, `orodc` provides clean, minimal output with a spinner for long-running operations:

```bash
# Clean output with spinner (default)
orodc up -d
# Output:
# ==> Found .php-version with following version: 8.4
# ==> Found .nvmrc with following version: 22
# ==> Building services completed
# ==> Starting services completed
#
# [oroplatform] Application: http://localhost:30180
# [oroplatform] Mailpit: http://localhost:8025
# [oroplatform] Elasticsearch: http://localhost:30192
# [oroplatform] Mq: http://localhost:30172
# [oroplatform] Database: 127.0.0.1:30132
# [oroplatform] SSH: 127.0.0.1:30122
#
# ==> Want to use custom domains and SSL? Start the proxy:
# ==>   orodc proxy up -d
# ==>   orodc proxy install-certs
# ==>
# ==> Then access via: https://oroplatform.docker.local

# With proxy running (orodc proxy up -d)
orodc up -d
# Output:
# ==> Found .php-version with following version: 8.4
# ==> Found .nvmrc with following version: 22
# ==> Building services completed
# ==> Starting services completed
#
# [oroplatform] Application: https://oroplatform.docker.local  (bold green)
#
# [oroplatform] Application: http://localhost:30180
# [oroplatform] Mailpit: http://localhost:8025
# [oroplatform] Elasticsearch: http://localhost:30192
# [oroplatform] Mq: http://localhost:30172
# [oroplatform] Database: 127.0.0.1:30132
# [oroplatform] SSH: 127.0.0.1:30122

orodc down
# Output:
# ==> Stopping services completed

orodc proxy up -d
# Output:
# ==> Starting proxy services completed
# ==> Bind address: 127.0.0.1
# ==> Dashboard:    http://127.0.0.1:8880/traefik/dashboard/
# ...

orodc proxy down
# Output:
# ==> Stopping proxy services completed

orodc purge
# Output:
# ==> Warning: This will permanently delete ALL project data:
# ==>   - All Docker containers for project: oroplatform
# ==>   - All Docker volumes (database, uploads, cache)
# ==>   - All project-specific Docker images
# ==>   - Configuration directory: /home/user/.orodc/oroplatform
#
# Are you sure you want to continue? [y/N]: y
#
# ==> Stopping and removing containers, volumes completed
# ==> Removing 5 project image(s)
# ==> Project images removed
# ==> Removing configuration directory
# ==> Configuration directory removed
#
# ==> Project oroplatform purged successfully
```

**Benefits:**
- Minimal, distraction-free output
- Spinner animation during build/up/down/proxy operations
- Full logs shown ONLY on errors
- Faster visual feedback
- Automatic proxy domain detection - shows `https://*.docker.local` when proxy is running

### 🔍 Debug Mode

For detailed troubleshooting, enable debug output:

```bash
# Enable debug output for any command
DEBUG=1 orodc up -d
DEBUG=1 orodc install
DEBUG=1 orodc bin/console cache:clear
```

**When to use DEBUG mode:**
- Troubleshooting Docker Compose issues
- Investigating build failures
- Understanding environment variable resolution
- Seeing full Docker command execution

### 📝 Verbose Mode

Use `--verbose` or `-v` flags to see Docker Compose output without debug shell tracing:

```bash
# Verbose Docker output without shell debugging
orodc up -d --verbose
orodc compose build --verbose
```

This shows full Docker build/compose output while keeping shell commands clean.

## 🤝 Contributing

We welcome contributions! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- ORO Platform team for the amazing e-commerce platform
- Docker team for containerization technology
- Homebrew team for package management
- Mutagen team for file synchronization
