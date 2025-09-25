# 🚀 OroCommerce / OroPlatform Docker Environment (OroDC)

![Docker architecture](docs/docker-architecture-small.png)

**Modern CLI tool to run ORO applications locally or on a server.** Designed specifically for local development environments with enterprise-grade performance and developer experience.

[![Version](https://img.shields.io/badge/Version-0.9.0-brightgreen.svg)](https://github.com/digitalspacestdio/homebrew-docker-compose-oroplatform/releases)
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
- [📖 Usage](#-usage)
- [🧪 Testing](#-testing)
  - [Test Environment Setup](#test-environment-setup)
  - [Running Tests](#running-tests)
  - [Available Test Commands](#available-test-commands)
- [🔧 Development Commands](#-development-commands)
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
```

### 🎯 Docker Compose Profiles

```bash
# Start with specific profiles
orodc --profile=consumer up -d
orodc --profile=php-cli --profile=database-cli up -d

# Consumer/Worker examples
orodc --profile=consumer bin/console oro:message-queue:consume
orodc --profile=consumer platformupdate
```

## ⚙️ Environment Variables

### 🔧 Complete Environment Variables Reference

#### 🏗️ Project Configuration
```bash
# Project identity
DC_ORO_NAME=unnamed                # Project name (default: unnamed)
DC_ORO_PORT_PREFIX=302             # Port prefix (302 → 30280, 30243, etc.)

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