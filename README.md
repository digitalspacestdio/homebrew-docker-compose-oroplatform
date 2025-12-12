# 🚀 OroCommerce / OroCrm / OroPlatform / MarelloCommerce - Docker Compose Environment (OroDC)

![Docker architecture](docs/docker-architecture-small.png)

**Modern CLI tool to run ORO applications locally or on a server.** Designed specifically for local development environments with enterprise-grade performance and developer experience.

[![Version](https://img.shields.io/badge/Version-0.12.5-brightgreen.svg)](https://github.com/digitalspacestdio/homebrew-docker-compose-oroplatform/releases)
[![Homebrew](https://img.shields.io/badge/Homebrew-Available-orange.svg)](https://brew.sh/)
[![Docker](https://img.shields.io/badge/Docker-Required-blue.svg)](https://www.docker.com/)
[![macOS](https://img.shields.io/badge/macOS-Supported-green.svg)](https://www.apple.com/macos/)
[![Linux](https://img.shields.io/badge/Linux-Supported-green.svg)](https://www.linux.org/)
[![Windows WSL2](https://img.shields.io/badge/Windows%20WSL2-Supported-green.svg)](https://docs.microsoft.com/en-us/windows/wsl/)

[![Test Installations](https://github.com/digitalspacestdio/homebrew-docker-compose-oroplatform/actions/workflows/test-oro-installations.yml/badge.svg)](https://github.com/digitalspacestdio/homebrew-docker-compose-oroplatform/actions/workflows/test-oro-installations.yml)
[![Build Docker Images](https://github.com/digitalspacestdio/homebrew-docker-compose-oroplatform/actions/workflows/build-docker-php-node-symfony.yml/badge.svg)](https://github.com/digitalspacestdio/homebrew-docker-compose-oroplatform/actions/workflows/build-docker-php-node-symfony.yml)

## 📋 Table of Contents

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
- [🧪 Testing](#-testing)
  - [Test Environment Setup](#test-environment-setup)
  - [Running Tests](#running-tests)
  - [Available Test Commands](#available-test-commands)
- [🔧 Development Commands](#-development-commands)
- [🔌 Reverse Proxy Management](#-reverse-proxy-management)
- [🌐 Multiple Hosts Configuration](#-multiple-hosts-configuration)
- [🌐 Dynamic Multisite Support via URL Paths](#-dynamic-multisite-support-via-url-paths)
- [⚙️ Environment Variables](#️-environment-variables)
- [🐳 Custom Docker Images](#-custom-docker-images)
- [🐛 XDEBUG Configuration](#-xdebug-configuration)
- [🔄 Working with Existing Projects](#-working-with-existing-projects)
- [🆘 Troubleshooting](#-troubleshooting)

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

# Start the environment
orodc up -d

# Install application (only once)
orodc install

# Connect via SSH
orodc ssh

# Stop the environment
orodc down
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

# Symfony/Oro Console commands
orodc bin/console cache:clear
orodc bin/console oro:user:create
```

## 🧪 Testing

### Test Environment Setup

**CRITICAL**: Test environment is completely separate from your main application:

```bash
# Navigate to your Oro application directory
cd ~/orocommerce

# ⚠️ REQUIRED: Set up test environment (one-time setup)
orodc tests install
```

### Running Tests

**ALL tests MUST use `orodc tests` prefix:**

#### Unit Tests
```bash
orodc tests bin/phpunit --testsuite=unit
orodc tests bin/phpunit --testsuite=unit --filter=UserTest
orodc tests bin/phpunit src/Oro/Bundle/UserBundle/Tests/Unit/Entity/UserTest.php
```

#### Functional Tests
```bash
orodc tests bin/phpunit --testsuite=functional
orodc tests bin/phpunit --testsuite=functional --filter=ApiTest
```

#### Behat Tests
```bash
orodc tests bin/behat --suite=OroUserBundle
orodc tests bin/behat --suite=OroCustomerBundle
orodc tests bin/behat features/user.feature
orodc tests bin/behat --available-suites
```

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
# Composer commands
orodc composer install
orodc composer update
orodc composer require package/name

# Database operations
orodc importdb database.sql.gz       # Import database
orodc exportdb                       # Export database
orodc platformupdate                 # Update platform
orodc updateurl                      # Update URLs

# Asset management
orodc bin/console oro:assets:build default -w  # Watch mode
orodc bin/console cache:clear                  # Clear cache

# Other tools
orodc database-cli                   # Direct database access
orodc ssh                           # SSH into container

# Proxy management
orodc proxy up -d                    # Start Traefik reverse proxy
orodc proxy install-certs            # Install CA certificates to system
orodc proxy down                     # Stop proxy (keeps volumes)
orodc proxy purge                    # Remove proxy and volumes
```

### 🔌 Reverse Proxy Management

OroDC includes built-in commands to manage Traefik reverse proxy inside Docker. This is useful for **macOS** and **WSL2 + Docker Desktop** users (where Docker runs in a VM).

**Proxy Commands:**

```bash
# Start Traefik proxy
orodc proxy up -d                    # Start in detached mode
orodc proxy up                       # Start with logs (foreground)

# Install CA certificates (optional, for HTTPS)
orodc proxy install-certs            # Auto-installs to system trust store

# Stop proxy
orodc proxy down                     # Stop proxy (keeps volumes)

# Remove proxy completely
orodc proxy purge                    # Remove proxy and all volumes

# With DEBUG logging
DEBUG=1 orodc proxy up -d
```

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
# Start with specific profiles
orodc --profile=consumer up -d
orodc --profile=php-cli --profile=database-cli up -d

# Consumer/Worker examples
orodc --profile=consumer bin/console oro:message-queue:consume
orodc --profile=consumer platformupdate
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

#### Method 1: Environment Variable
```bash
export DC_ORO_EXTRA_HOSTS="api,admin,shop"
orodc up -d
```

#### Method 2: .env.orodc File
```bash
echo 'DC_ORO_EXTRA_HOSTS=api,admin,shop' >> .env.orodc
orodc up -d
```

#### Method 3: Project-specific Configuration
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

## ⚙️ Environment Variables

### 🔧 Complete Environment Variables Reference

#### 🏗️ Project Configuration
```bash
# Project identity
DC_ORO_NAME=unnamed                # Project name (default: unnamed)
DC_ORO_PORT_PREFIX=302             # Port prefix (302 → 30280, 30243, etc.)

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
DC_ORO_DATABASE_USER=app           # Database user
DC_ORO_DATABASE_PASSWORD=app       # Database password  
DC_ORO_DATABASE_DBNAME=app         # Database name
DC_ORO_DATABASE_SCHEMA=postgres    # Database type (postgres/mysql)

# Connection URI (auto-generated)
DC_ORO_DATABASE_URI=postgres://app:app@database:5432/app
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
```bash
# Mail settings
ORO_MAILER_DRIVER=smtp             # Mail driver
ORO_MAILER_HOST=mail               # Mail host
ORO_MAILER_PORT=1025               # Mail port

# Security
ORO_SECRET=ThisTokenIsNotSoSecretChangeIt  # Application secret

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

# MailHog (email testing)
DC_ORO_MAILHOG_IMAGE=mymailhog
DC_ORO_MAILHOG_VERSION=latest

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

#### 🎯 Enable XDEBUG with Profile-Specific Control
For debugging in CLI and FPM containers, but disable in consumer workers:

```bash
XDEBUG_MODE=debug XDEBUG_MODE_CONSUMER=off orodc --profile=consumer up -d
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
cd ~/my-oro-project

# Complete project recreation (single command)
orodc --profile=consumer purge && \
orodc importdb ~/backup.sql.gz && \
orodc platformupdate && \
orodc bin/console oro:user:update --user-password=12345678 admin && \
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

# Check logs
orodc logs [service-name]

# Debug mode
DEBUG=1 orodc [command]
```

### 🔍 Debug Mode

```bash
# Enable debug output for any command
DEBUG=1 orodc up -d
DEBUG=1 orodc install
DEBUG=1 orodc bin/console cache:clear
```

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
