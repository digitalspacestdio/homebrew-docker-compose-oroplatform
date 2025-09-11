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
- [🛠️ Installation](#️-installation)
  - [Prerequisites](#prerequisites)
  - [Install OroDC](#install-orodc)
- [🏗️ Application Setup](#️-application-setup)
  - [OroCommerce](#orocommerce)
  - [OroPlatform](#oroplatform)
  - [OroCRM](#orocrm)
- [🧪 Testing](#-testing)
  - [Test Environment Setup](#test-environment-setup)
  - [Running Tests](#running-tests)
  - [Available Test Commands](#available-test-commands)
- [🎯 Smart Commands](#-smart-commands)
- [🔧 Configuration](#-configuration)
- [🆘 Troubleshooting](#-troubleshooting)
- [📚 Documentation](#-documentation)

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

### 🔧 Core Configuration

```bash
# Project settings
DC_ORO_NAME=myproject              # Project name
DC_ORO_PORT_PREFIX=302             # Port prefix (302 → 30280)

# PHP/Node versions
DC_ORO_PHP_VERSION=8.3             # PHP version
DC_ORO_NODE_VERSION=20             # Node.js version

# Sync mode
DC_ORO_MODE=mutagen                # Sync mode (default/mutagen/ssh)

# Database
DC_ORO_DATABASE_SCHEMA=postgres    # Database type
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