
# 🚀 ORO Platform Docker Compose (OroDC)

![Docker architecture](docs/docker-architecture-small.png)

**Modern CLI tool to run ORO applications locally or on a server.** Designed specifically for local development environments with enterprise-grade performance and developer experience.

[![Homebrew](https://img.shields.io/badge/Homebrew-Available-orange.svg)](https://brew.sh/)
[![Docker](https://img.shields.io/badge/Docker-Required-blue.svg)](https://www.docker.com/)
[![macOS](https://img.shields.io/badge/macOS-Supported-green.svg)](https://www.apple.com/macos/)
[![Linux](https://img.shields.io/badge/Linux-Supported-green.svg)](https://www.linux.org/)
[![Windows WSL2](https://img.shields.io/badge/Windows%20WSL2-Supported-green.svg)](https://docs.microsoft.com/en-us/windows/wsl/)

## ✨ Key Features

- 🔥 **Lightning Fast**: Optimized port resolution (~1 second vs 5-10 seconds)
- 🎯 **Smart PHP Detection**: Auto-redirect PHP commands to CLI container
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

# Open your application
open http://localhost:30280/

# 🎯 New! Smart PHP Commands & Testing
orodc --version                    # Check PHP version
orodc -r 'echo "Hello OroDC!";'    # Run PHP code directly
orodc bin/phpunit --testsuite=unit # Run PHPUnit tests
orodc bin/behat --available-suites # Run Behat behavior tests
```

## 🎯 Smart PHP Integration

OroDC now automatically detects and redirects PHP commands to the CLI container:

```bash
# All these work automatically - no need to specify 'cli'!
orodc -v                    # → cli php -v
orodc --version            # → cli php --version  
orodc script.php           # → cli php script.php
orodc -r 'phpinfo()'       # → cli php -r 'phpinfo()'
orodc bin/console cache:clear  # → cli bin/console cache:clear

# Traditional way still works
orodc cli php -v           # Still supported
```

## 🎨 Frontend Development

OroDC provides seamless frontend asset building and watch mode for efficient development:

```bash
# Install assets with relative symlinks (recommended for development)
orodc bin/console oro:assets:install --relative-symlink

# Build assets in watch mode for live development
orodc bin/console oro:assets:build default -w

# Build assets for production (without watch)
orodc bin/console oro:assets:build default

# Clear asset cache when needed
orodc bin/console cache:clear --env=prod
```

### Watch Mode Benefits
- **Live Reload**: Automatically rebuilds assets when source files change
- **Fast Development**: No need to manually rebuild after each change  
- **Real-time Preview**: See changes immediately in browser
- **Efficient Workflow**: Focus on coding, not build processes

## 💻 Supported Systems
- **macOS** (Intel & Apple Silicon)
- **Linux** (AMD64, ARM64)  
- **Windows** (via WSL2, AMD64)

## Pre-requirements

### Docker
- **MacOS**: [Install Docker for Mac](https://docs.docker.com/desktop/mac/install/)
- **Linux** (Ubuntu and others):
  - [Install Docker Engine](https://docs.docker.com/engine/install/ubuntu/)
  - [Install Docker Compose](https://docs.docker.com/compose/install/compose-plugin/)
- **Windows**: [Follow this guide](https://docs.docker.com/desktop/windows/wsl/)

### Homebrew (MacOS/Linux/Windows)
- [Install Homebrew](https://brew.sh/)

### Configure COMPOSER Credentials (optional)
If no local Composer setup exists, export the following variable or add it to `.bashrc` or `.zshrc`:

```bash
export DC_ORO_COMPOSER_AUTH='{ "http-basic": { "repo.example.com": { "username": "xxxxxxxx", "password": "yyyyyyyy" } }, "github-oauth": { "github.com": "xxxxxxxx" }, "gitlab-token": { "example.org": "xxxxxxxx" } }'
```

Or automatically export existing auth config:

```bash
echo "export COMPOSER_AUTH='"$(cat $(php -d display_errors=0 $(which composer) config --no-interaction --global home 2>/dev/null)/auth.json | jq -c .)"'"
```

## 📦 Installation

### Via Homebrew (Recommended)

```bash
# Install OroDC
brew install digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform

# Now available as both commands:
orodc --help                    # Short alias (recommended)
docker-compose-oroplatform --help  # Full name
```

### Verify Installation

```bash
orodc --help
# Should show OroDC help and available commands
```

## About OroDC Architecture

**OroDC** helps quickly set up a ready-to-use local environment for OroPlatform, OroCRM, or OroCommerce projects.
Developers, QA engineers, and frontend teams can work inside a fully functional system similar to production servers.

You don’t need to install PHP, Node.js, PostgreSQL, Redis, or other services manually. OroDC handles everything inside Docker containers.

### How It Works
1. Creates configuration files.
2. Builds and starts multiple Docker containers.
3. Stores your project code inside a Docker Volume.
4. Mounts the volume into PHP, SSH, Nginx, WebSocket, Consumer containers.
5. Runs Nginx for serving the application via HTTP.
6. Connects your local machine to the environment using SSH, Rsync, or Mutagen.

You can connect to the environment using PHPStorm, VSCode Remote Development, or SSH directly.

### What Services Are Included
- **SSH Server**
- **PHP-FPM**
- **Nginx** (HTTP only)
- **PostgreSQL** (default) *(MySQL is available but not recommended)*
- **Redis**
- **RabbitMQ**
- **Elasticsearch**
- **WebSocket Server**
- **Background Consumer Worker**

All services run in their **own** containers but communicate inside a Docker network.

### Where Your Code Lives

The project code is stored inside a **Docker Volume** and shared across all necessary containers.
Updates are delivered via **Rsync** or **Mutagen** (optional).

### Why It Is Useful
- Fast setup
- Clean local machine
- Safe for experiments
- Same environment for everyone
- Works with PHPStorm and VSCode Remote Development

## How to Start From Scratch

### Step-by-Step Guide

1. **Install Docker** on your machine:
   - MacOS: [Install Docker for Mac](https://docs.docker.com/desktop/mac/install/)
   - Linux: [Install Docker Engine](https://docs.docker.com/engine/install/ubuntu/)
   - Windows (WSL2): [Install Docker Desktop](https://docs.docker.com/desktop/windows/wsl/)

1. **Install Homebrew** (recommended):
   - [Follow this guide](https://brew.sh/)
1. **Install OroDC**:
   ```bash
   brew install digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform
   ```
1. **Clone your Oro project**:
   ```bash
   git clone --single-branch --branch 6.1.4 https://github.com/oroinc/orocommerce-application.git ~/orocommerce
   ```
1. **Navigate to the product directory**:
   ```bash
   cd ~/orocommerce
   ```
1. **Install Oro application with sample data**:
   ```bash
   orodc install
   ```
1. **Launch the environment**:
   ```bash
   orodc up -d
   ```
1. **Open your application**:
   ```
   http://localhost:30280/
   ```
1. **Develop using your favorite IDE (PHPStorm or VSCode Remote Development)**

## 📖 Usage

### 🚀 Basic Commands

```bash
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

OroDC automatically detects PHP flags and redirects them to the PHP CLI container:

```bash
# PHP version and info
orodc -v                   # Check PHP version (short)
orodc --version            # PHP version (detailed)
orodc -m                   # List PHP modules
orodc -i                   # PHP configuration info
orodc --help               # PHP CLI help

# Execute PHP code directly
orodc -r 'echo "Hello PHP!";'           # Run inline PHP code
orodc -r 'phpinfo();'                   # Show PHP info
orodc -l script.php                     # Syntax check PHP file

# Run PHP scripts directly
orodc script.php           # Execute PHP file
orodc test.php arg1 arg2   # With arguments

# Symfony/Oro Console commands
orodc bin/console list                   # List all commands
orodc bin/console cache:clear            # Clear cache
orodc bin/console oro:platform:update    # Update platform
```

### 🧪 Testing with PHPUnit

OroDC provides seamless PHPUnit integration for running tests:

#### 🚀 Quick Start Guide for New Developers

**Never run OroPlatform tests before? Follow these steps:**

```bash
# 1. First, discover what's available
orodc tests bin/phpunit --list-suites          # Shows: unit, functional, selenium
orodc tests bin/behat --available-suites       # Shows: OroUserBundle, OroProductBundle, etc.

# 2. Start with fast unit tests (no database required)
orodc tests bin/phpunit --testsuite=unit --stop-on-failure  # Run all unit tests (~74K tests)

# 3. Test a specific bundle you're interested in
orodc tests bin/phpunit vendor/oro/platform/src/Oro/Bundle/UserBundle/Tests/Unit/  # ~432 tests in 0.3s

# 4. For functional tests, you need test database first
orodc tests install                             # Install test database (one time, ~5 minutes)
orodc tests bin/phpunit --testsuite=functional # Run functional tests (slower)

# 5. For browser tests with Behat
orodc tests bin/behat --suite=OroUserBundle --dry-run  # See scenarios without running
orodc tests bin/behat --suite=OroUserBundle            # Run actual browser tests
```

#### ⚡ Quick Start - Unit Tests

Run unit tests in one command:
```bash
orodc tests bin/phpunit --testsuite=unit # Run all unit tests (74,816+ tests)
```

No setup required! Unit tests run directly against the main application without needing a separate test database.

**For functional tests (require test database setup):**
```bash
orodc tests install                            # Install test database (one time)
orodc tests bin/phpunit --testsuite=functional # Run functional tests
orodc tests bin/phpunit                        # Run all tests (unit + functional)
```

#### 🚀 Universal Test Commands

**New Universal Command System**

`orodc tests` now works as a universal command executor - any command you pass will run inside the isolated `test-cli` container with the test environment configured:

```bash
# Universal test commands (all run in test-cli container)
orodc tests bin/phpunit --testsuite=unit    # Run unit tests  
orodc tests bin/phpunit --testsuite=functional # Run functional tests
orodc tests bin/phpunit                      # Run all tests
orodc tests bin/behat --available-suites    # List Behat test suites
orodc tests bin/behat --suite=OroUserBundle # Run specific Behat suite

# Development commands in test environment
orodc tests --version                        # PHP version in test container
orodc tests composer install                 # Install dependencies
orodc tests bin/console cache:clear --env=test # Clear test cache
orodc tests php -m                          # List PHP modules

# Any command works!
orodc tests <any-command>                   # Runs in isolated test environment
```

#### 🔍 Exploring the Test Environment

**New to OroPlatform testing? Start here to discover what's available:**

```bash
# Discover available test suites
orodc tests bin/phpunit --list-suites          # List all PHPUnit test suites (unit, functional, selenium)

# Discover available Behat test suites (bundles)  
orodc tests bin/behat --available-suites       # List all Behat test suites (50+ bundles)

# Get help and available options
orodc tests bin/phpunit --help                 # PHPUnit help and all options
orodc tests bin/behat --help                   # Behat help and all options

# Check versions and environment
orodc tests --version                          # PHP version in test environment
orodc tests bin/phpunit --version             # PHPUnit version
orodc tests bin/behat --version               # Behat version

# Explore test structure
orodc tests find vendor/oro/platform/src/Oro/Bundle/UserBundle/Tests -name "*Test.php" | head -5  # Find PHPUnit tests
orodc tests find vendor/oro/platform/src/Oro/Bundle/UserBundle/Tests -name "*.feature" | head -5  # Find Behat features
```

#### 📋 Basic Testing Commands

```bash
# PHPUnit commands
orodc tests bin/phpunit --version              # Check PHPUnit version
orodc tests bin/phpunit --list-suites          # List available test suites

# Run different test suites
orodc tests bin/phpunit --testsuite=unit       # Run unit tests (74,816+ tests)
orodc tests bin/phpunit --testsuite=functional # Run functional tests
orodc tests bin/phpunit --testsuite=selenium   # Run Selenium tests

# Advanced testing options
orodc tests bin/phpunit --stop-on-failure      # Stop on first failure
orodc tests bin/phpunit --verbose              # Verbose output
orodc tests bin/phpunit --filter=TestName      # Run specific test
orodc tests bin/phpunit path/to/TestFile.php   # Run specific test file

# Testing specific bundles (recommended approach)
orodc tests bin/phpunit vendor/oro/platform/src/Oro/Bundle/UserBundle/Tests/Unit/      # Unit tests for OroUserBundle (432 tests)
orodc tests bin/phpunit vendor/oro/platform/src/Oro/Bundle/UserBundle/Tests/Functional/ # Functional tests for OroUserBundle  
orodc tests bin/phpunit vendor/oro/platform/src/Oro/Bundle/UserBundle/Tests/           # All OroUserBundle tests
orodc tests bin/phpunit vendor/oro/product/src/Oro/Bundle/ProductBundle/Tests/Unit/    # Unit tests for OroProductBundle
orodc tests bin/phpunit vendor/oro/customer-portal/src/Oro/Bundle/CustomerBundle/Tests/Unit/ # Unit tests for OroCustomerBundle

# Alternative: Using filters (less reliable)
orodc tests bin/phpunit --testsuite=unit --filter="UserBundle"  # Unit tests containing "UserBundle" in name

# Testing specific test classes
orodc tests bin/phpunit --filter=UserManagerTest                # All UserManagerTest classes
orodc tests bin/phpunit --filter=UserControllerTest             # All UserControllerTest classes

# Coverage and reporting
orodc tests bin/phpunit --coverage-html=coverage/  # Generate HTML coverage
orodc tests bin/phpunit --testdox                  # Human-readable output
```

#### 🔧 Setting Up Functional Tests

Functional tests require a separate test database. Here's how to set it up:

**1. Test database management:**
```bash
# Install test database (creates DB + installs Oro)
orodc tests install

# Purge test database (clean up)
orodc tests purge

# Manual setup (alternative)
docker exec -i orocommerce_database psql -U oro_db_user oro_db -c "CREATE DATABASE b2b_crm_dev_test;"
orodc bin/console --env=test oro:install --sample-data=n --timeout=0
```

**2. Quick test commands:**
```bash
# Quick test commands (using universal orodc tests)
orodc tests bin/phpunit --testsuite=unit       # Run unit tests
orodc tests bin/phpunit --testsuite=functional # Run functional tests  
orodc tests bin/phpunit                         # Run all tests

# Other useful test commands
orodc tests bin/phpunit --list-suites          # List available test suites
orodc tests bin/behat --available-suites       # List Behat test suites
```

**3. Advanced functional testing:**
```bash
# Run all functional tests
orodc bin/phpunit --testsuite=functional

# Run specific functional test
orodc bin/phpunit --testsuite=functional --filter="CalendarNameTest"

# Run functional tests with verbose output
orodc bin/phpunit --testsuite=functional --verbose

# Run functional tests for specific bundle
orodc bin/phpunit --testsuite=functional --filter="CalendarBundle"
```

**4. Performance comparison:**
- **Unit tests**: ~665 tests in 1.5 seconds ⚡
- **Functional tests**: ~194 tests in 3+ minutes 🐌
- **Total test suite**: 74,816+ unit tests available

#### 🎯 Test Environment Configuration

The test environment uses these key files:
- `.env-app.test` - Test environment variables
- `phpunit.xml.dist` - PHPUnit configuration
- Test database: `b2b_crm_dev_test` (PostgreSQL)

#### 💡 Testing Best Practices

```bash
# Always run unit tests first (faster feedback)
orodc bin/phpunit --testsuite=unit --stop-on-failure

# Run functional tests for specific areas
orodc bin/phpunit --testsuite=functional --filter="ProductBundle"

# Use testdox for readable output
orodc bin/phpunit --testsuite=unit --testdox

# Generate coverage reports
orodc bin/phpunit --testsuite=unit --coverage-html=var/coverage
```

### 🎭 Behat (Behavior-Driven Development) Tests

OroPlatform includes Behat for behavior-driven testing with real user scenarios:

#### 📋 Available Behat Commands

```bash
# Check available test suites
orodc bin/behat --available-suites

# List available step definitions (expressions only)
orodc bin/behat --definitions=l

# Show step definitions with extended info
orodc bin/behat --definitions=i

# Find specific step definitions
orodc bin/behat --definitions="click"

# Run dry-run to see test scenarios without executing
orodc bin/behat --suite=OroUserBundle --dry-run

# Run specific test suite (bundle)
orodc tests bin/behat --suite=OroUserBundle          # All OroUserBundle Behat tests
orodc tests bin/behat --suite=OroProductBundle       # All OroProductBundle Behat tests  
orodc tests bin/behat --suite=OroCustomerBundle      # All OroCustomerBundle Behat tests
orodc tests bin/behat --suite=OroOrderBundle         # All OroOrderBundle Behat tests
orodc tests bin/behat --suite=OroCheckoutBundle      # All OroCheckoutBundle Behat tests

# Run specific feature file
orodc tests bin/behat vendor/oro/platform/src/Oro/Bundle/UserBundle/Tests/Behat/Features/

# Run with specific tags
orodc bin/behat --tags="@regression"

# Run tests with verbose output
orodc bin/behat --suite=OroUserBundle --verbose

# Skip database isolators (faster for development)
orodc bin/behat --suite=OroUserBundle --skip-isolators=database

# Stop on first failure
orodc bin/behat --suite=OroUserBundle --stop-on-failure

# Run without browser (API/console tests only)
orodc bin/behat --suite=OroUserBundle --tags="~@javascript"

# Quick test with temporary Selenium (auto-cleanup)
docker run --rm -d --name selenium-temp --network dc_shared_net -p 4444:4444 --shm-size="2g" selenium/standalone-chrome:latest && sleep 5 && orodc bin/behat --suite=OroUserBundle --dry-run; docker kill selenium-temp 2>/dev/null
```

#### 🚀 Quick Start (No Browser Required)

For simple API and console-based tests without Selenium:

```bash
# Run non-JavaScript tests (no browser automation needed)
orodc bin/behat --suite=OroUserBundle --tags="~@javascript" --dry-run

# Check what contexts and elements are available
orodc bin/behat --contexts
orodc bin/behat --elements
```

#### 🎯 Development Testing Examples

**Daily Development Workflow:**
```bash
# Start your development session
orodc up -d                           # Start main application
orodc tests install                  # Install test database and environment (once)

# During development - run tests frequently
orodc tests bin/phpunit --testsuite=unit --stop-on-failure  # Quick unit tests
orodc tests bin/behat --suite=OroUserBundle --dry-run       # Validate Behat scenarios

# Testing specific bundle you're working on
orodc tests bin/phpunit vendor/oro/platform/src/Oro/Bundle/UserBundle/Tests/Unit/  # Unit tests for OroUserBundle (~432 tests)
orodc tests bin/phpunit vendor/oro/platform/src/Oro/Bundle/UserBundle/Tests/Functional/  # Functional tests for OroUserBundle  
orodc tests bin/behat --suite=OroUserBundle                 # All OroUserBundle Behat tests

# Testing specific functionality
orodc tests bin/phpunit --filter=UserManagerTest            # Specific test class
orodc tests bin/phpunit --filter=testCreateUser             # Specific test method
orodc tests bin/behat --suite=OroUserBundle --tags="@smoke" # Smoke tests only

# Before committing - run full test suite
orodc tests bin/phpunit --testsuite=unit                    # All unit tests
orodc tests bin/behat --suite=OroUserBundle                 # Full browser tests

# End of session
orodc tests purge                     # Purge test environment
```

**Debugging Failed Tests:**
```bash
# Run tests with verbose output
orodc tests unit -vvv
orodc bin/behat --suite=OroUserBundle -vvv

# Run specific test methods
orodc bin/phpunit --filter=testSpecificMethod
orodc bin/behat --suite=OroUserBundle --name="specific scenario"

# Check test environment logs
orodc tests status                    # Check test services status
orodc logs test-fpm                   # Just PHP-FPM logs
orodc logs test-nginx                 # Just Nginx logs
```


#### 🔧 Behat Test Suites Available

Common test suites include:
- `OroUserBundle` - User management tests
- `OroCustomerBundle` - Customer functionality tests  
- `OroProductBundle` - Product management tests
- `OroOrderBundle` - Order processing tests
- `OroCheckoutBundle` - Checkout process tests
- `OroShoppingListBundle` - Shopping list tests
- `OroPricingBundle` - Pricing functionality tests
- `OroPaymentBundle` - Payment processing tests

#### 🧪 Test Environment Setup

**OroDC provides a complete isolated test environment with:**
- **Test PHP-FPM**: Configured with `APP_ENV=test` and test database
- **Test Nginx**: Separate web server for test application (port 8080)
- **Test Selenium**: Chrome browser automation for Behat tests
- **Automatic Configuration**: `behat.yml` created automatically

**Quick Start:**
```bash
# 1. Start main services (if not already running)
orodc up -d

# 2. Setup test database
orodc tests setup

# 3. Start test environment
orodc tests setup

# 4. Check test environment status
orodc tests status
# Test application: Available in Docker network (test-nginx)
# Selenium WebDriver: Available in Docker network (test-selenium:4444)
# Note: Test environment runs entirely inside Docker network for isolated testing

# 5. Run Behat tests
orodc bin/behat --available-suites
orodc bin/behat --suite=OroUserBundle --dry-run
```

**Complete Testing Workflow:**
```bash
# Setup and start everything
orodc up -d                           # Start main services
orodc tests install                 # Create and install test database
orodc tests install                # Start isolated test environment

# Run different types of tests
orodc tests unit                      # PHPUnit unit tests
orodc tests functional               # PHPUnit functional tests  
orodc tests all                       # All PHPUnit tests

# Run Behat browser tests
orodc bin/behat --available-suites    # List available test suites
orodc bin/behat --suite=OroUserBundle --dry-run    # Dry run (no browser)
orodc bin/behat --suite=OroUserBundle             # Full browser test

# Test specific features
orodc bin/behat --suite=OroProductBundle --tags="@javascript"
orodc bin/behat --suite=OroCheckoutBundle --stop-on-failure

# Cleanup
orodc tests purge                     # Purge test environment
orodc tests destroy                  # Drop test database (optional)
```

**Test Environment Commands:**
```bash
# Install test environment (creates database and starts services)
orodc tests install

# Purge test environment (removes database and stops services)  
orodc tests purge

# Check test services status
orodc tests status
```

**Automatic Configuration:**

OroDC automatically creates `behat.yml` when you run `orodc up`:

```yaml
# Auto-generated behat.yml
imports:
  - ./vendor/oro/platform/src/Oro/Bundle/TestFrameworkBundle/Resources/config/behat.yml.dist

default: &default
    extensions:
        Behat\MinkExtension:
            base_url: 'http://test-nginx/'  # Test environment URL
            sessions:
                default:
                    selenium2:
                        wd_host: 'http://test-selenium:4444/wd/hub'
        FriendsOfBehat\SymfonyExtension:
            kernel:
                debug: false
                class: AppKernel
```

#### 🚀 CI/CD Integration Examples

**GitHub Actions Workflow:**
```yaml
name: OroCommerce Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install OroDC
        run: |
          /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
          brew tap digitalspacestdio/docker-compose-oroplatform
          brew install docker-compose-oroplatform
      
      - name: Start services
        run: |
          orodc up -d
          orodc tests install
          orodc tests install
      
      - name: Run tests
        run: |
          orodc test all                    # PHPUnit tests
          orodc bin/behat --suite=OroUserBundle --dry-run  # Behat validation
      
      - name: Cleanup
        if: always()
        run: |
          orodc tests purge
          orodc down
```

**GitLab CI Pipeline:**
```yaml
# .gitlab-ci.yml
stages:
  - test

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: ""

test:
  stage: test
  image: ubuntu:22.04
  services:
    - docker:dind
  before_script:
    - apt-get update && apt-get install -y curl git
    - /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    - brew tap digitalspacestdio/docker-compose-oroplatform
    - brew install docker-compose-oroplatform
  script:
    - orodc up -d
    - orodc tests install
    - orodc tests install
    - orodc test all
    - orodc bin/behat --suite=OroUserBundle --dry-run
  after_script:
    - orodc tests purge || true
    - orodc down || true
```

**Local Pre-commit Hook:**
```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "🧪 Running pre-commit tests..."

# Ensure test environment is ready
orodc tests setup

# Run quick tests
echo "Running unit tests..."
if ! orodc tests unit; then
    echo "❌ Unit tests failed!"
    exit 1
fi

echo "Validating Behat scenarios..."
if ! orodc bin/behat --suite=OroUserBundle --dry-run; then
    echo "❌ Behat validation failed!"
    exit 1
fi

echo "✅ All tests passed!"
exit 0
```

**4. Common Error:**
```
Could not open connection: Failed to connect to localhost port 4444
```
This means Selenium WebDriver server is not running on port 4444.

**5. Quick Selenium Setup for Testing:**
```bash
# Start Selenium temporarily in background (auto-cleanup with --rm)
docker run --rm -d --name selenium-chrome \
  --network dc_shared_net \
  -p 4444:4444 -p 7900:7900 --shm-size="2g" \
  selenium/standalone-chrome:latest &

# Wait for Selenium to be ready
sleep 5 && curl http://localhost:4444/wd/hub/status

# Run your Behat tests
orodc bin/behat --suite=OroUserBundle

# Kill Selenium when done (auto-cleanup)
docker kill selenium-chrome
```

**6. One-liner for quick testing:**
```bash
# Start Selenium, run tests, auto-cleanup
docker run --rm -d --name selenium-chrome --network dc_shared_net -p 4444:4444 --shm-size="2g" selenium/standalone-chrome:latest && \
sleep 5 && \
orodc bin/behat --suite=OroUserBundle --dry-run && \
docker kill selenium-chrome
```

**7. Network Configuration:**
- OroDC uses `dc_shared_net` Docker network
- Selenium must be in same network to access OroDC containers
- Your app will be accessible at `http://orocommerce_nginx` from Selenium container

For full Behat testing, consider using a dedicated testing environment with proper browser automation setup.

#### 🎯 Behat vs PHPUnit

- **PHPUnit**: Unit and functional tests (faster, isolated)
- **Behat**: End-to-end behavior tests (slower, full user scenarios)
- **Recommendation**: Use PHPUnit for development, Behat for acceptance testing

### 🔧 Development Commands

```bash
# Composer commands
orodc composer install     # Install dependencies
orodc composer update      # Update dependencies
orodc composer require package/name

# Database operations
orodc mysql                # Connect to MySQL
orodc psql                 # Connect to PostgreSQL
orodc databaseimport dump.sql    # Import database
orodc databaseexport             # Export database

# Other tools
orodc npm install          # Node.js commands
orodc yarn install         # Yarn commands  
orodc bash                 # Direct bash access
```

### 🎯 Docker Compose Profiles & Consumer Management

OroDC supports Docker Compose profiles for advanced service management:

```bash
# Start with specific profiles
orodc up --profile=consumer -d              # Start with consumer services
orodc up --profile=worker --profile=api -d  # Multiple profiles
orodc up --profile=consumer --profile=database-cli -d  # Mix regular and CLI profiles

# Profiles are cached and reused automatically
orodc php -v                    # Uses cached profiles from last 'up'
orodc bin/console cache:clear   # Same profiles applied
orodc logs nginx               # Same profiles applied

# Consumer/Worker examples
orodc up --profile=consumer -d                    # Start consumer services
orodc bin/console oro:message-queue:consume       # Process messages
orodc logs consumer                                # Check consumer logs

# CLI profiles (smart loading)
orodc up --profile=database-cli --profile=php-cli -d
orodc mysql                     # Loads database-cli profile automatically
orodc php -v                    # Loads php-cli profile automatically
orodc logs nginx               # Does NOT load CLI profiles (resource efficient)

# Profile management
orodc up -d                     # Clear all cached profiles
orodc down                      # Properly cleanup with all cached profiles
orodc purge                     # Complete cleanup with all profiles
```

### 🐛 XDEBUG Configuration

```bash
# CLI + FPM debugging
XDEBUG_MODE_FPM=debug XDEBUG_MODE_CLI=debug orodc up -d

# FPM only (web requests)
XDEBUG_MODE_FPM=debug orodc up -d

# CLI only (console commands)
XDEBUG_MODE_CLI=debug orodc up -d
```

### ⚡ Performance Features

OroDC includes several performance optimizations:

- **🚀 Fast Port Resolution**: Optimized Docker inspect calls (~1 second vs 5-10 seconds)
- **🧠 Smart Caching**: Docker container information cached during startup
- **🔄 Batch Processing**: Multiple port checks in single operation
- **🎯 Intelligent Conflicts**: Detects real port conflicts vs same-project reuse
- **💾 Efficient Sync**: Mutagen/Rsync for fast file synchronization

### 🎨 Colored Output

OroDC provides beautiful, informative output:

- 🟡 **Yellow warnings**: Port conflicts and important notices
- 🟠 **Orange errors**: Critical issues requiring attention  
- 🔵 **Blue info**: General information and status updates
- ✅ **Green success**: Successful operations and confirmations

## ⚙️ Environment Variables

Variables can be stored in `.env.orodc`, `.env-app.local`, `.env-app`, or `.env` in the project root.

### 🔧 Core Configuration

| Variable | Options | Default | Description |
|----------|---------|---------|-------------|
| **DC_ORO_MODE** | `default`\|`ssh`\|`mutagen` | `default` (Linux/WSL)<br>`mutagen` (macOS) | File sync method |
| **DC_ORO_NAME** | string | directory name | Project name |
| **DC_ORO_PORT_PREFIX** | 3-digit number | `302` | Port prefix (e.g., `302` → `30280`) |

### 🐳 Container Versions

| Variable | Options | Default | Description |
|----------|---------|---------|-------------|
| **DC_ORO_PHP_VERSION** | `7.4`, `8.1`, `8.2`, `8.3`, `8.4` | `8.3` | PHP version |
| **DC_ORO_NODE_VERSION** | `18`, `20`, `22` | `20` | Node.js version |
| **DC_ORO_COMPOSER_VERSION** | `1`, `2` | `2` | Composer version |
| **DC_ORO_PGSQL_VERSION** | PostgreSQL tag | `15.1` | PostgreSQL version |
| **DC_ORO_ELASTICSEARCH_VERSION** | Elasticsearch tag | `8.10.3` | Elasticsearch version |
| **DC_ORO_MYSQL_IMAGE** | MySQL tag | - | MySQL version (not recommended) |

### 📁 Sync Modes Explained

OroDC supports three different file synchronization modes to optimize performance across different operating systems and environments:

#### 🐧 `default` Mode (Linux/WSL Default)
- **How it works**: Direct bind mount between host and container (native filesystem)
- **Performance**: Fastest possible on Linux - no file copying overhead
- **Best for**: Linux, WSL2 on Windows (optimal choice)
- **Pros**: 
  - Real-time file changes with zero sync delay
  - Minimal resource usage
  - Native filesystem performance
- **Cons**: 
  - Significantly slower on macOS due to Docker Desktop filesystem performance issues
  - Not recommended for macOS development

```bash
# Set default mode explicitly
echo "DC_ORO_MODE=default" >> .env.orodc
```

#### 🍎 `mutagen` Mode (macOS Default)
- **How it works**: Docker volume + Mutagen two-way sync
- **Performance**: High performance with intelligent sync
- **Best for**: macOS development (default choice)
- **Pros**: Fast file operations, handles large codebases well, bi-directional sync
- **Cons**: Requires Mutagen installation, slight sync delay (usually <1s)

```bash
# Set Mutagen mode (macOS recommended)
echo "DC_ORO_MODE=mutagen" >> .env.orodc

# Install Mutagen if not already installed
brew install mutagen-io/mutagen/mutagen
```

#### 🔗 `ssh` Mode (Remote/Antivirus Issues)
- **How it works**: Files stored entirely inside Docker container, no local sync
- **Performance**: Very fast (especially on macOS), no filesystem overhead
- **Best for**: 
  - Remote Docker hosts
  - macOS with aggressive antivirus software that blocks file access
  - When you need maximum performance and don't require local file editing
- **Pros**: 
  - Fastest performance on macOS (bypasses Docker filesystem issues)
  - Completely bypasses antivirus interference
  - Works with any Docker host, handles network setups
- **Cons**: 
  - Local files are NOT synchronized back from container
  - Code changes must be made inside container via SSH/CLI
  - Requires SSH key setup

```bash
# Set SSH mode
echo "DC_ORO_MODE=ssh" >> .env.orodc

# Start with SSH mode
orodc up -d ssh
```

**🔧 Remote Development Setup:**

For the best SSH mode experience, use remote development tools in your IDE:

**VS Code Remote Development:**
```bash
# SSH connection details
Host: localhost
Port: (check with 'orodc ps' for SSH port)
User: www-data
Private Key: ~/.orodc/{project_name}/ssh_id_ed25519
```

**PhpStorm Remote Development:**
```bash
# SSH configuration
Host: localhost
Port: (check with 'orodc ps' for SSH port)  
Username: www-data
Authentication: Key pair
Private key file: ~/.orodc/{project_name}/ssh_id_ed25519
```

**SSH Key Location:**
```bash
# SSH keys are automatically generated and stored at:
Private key: ~/.orodc/{project_name}/ssh_id_ed25519
Public key:  ~/.orodc/{project_name}/ssh_id_ed25519.pub
```

#### 🎯 Mode Selection Guide

| Operating System | Recommended Mode | Alternative | Notes |
|------------------|------------------|-------------|-------|
| **Linux** | `default` | `ssh` (for remote Docker) | Native bind mount is fastest |
| **WSL2** | `default` | `ssh` (for remote Docker) | Native performance on WSL2 |
| **macOS** | `mutagen` | `ssh` (if antivirus blocks files) | Both `mutagen` and `ssh` bypass Docker filesystem issues |
| **Remote Docker** | `ssh` | - | Only option for remote hosts |

#### ⚡ Performance Comparison

**On Linux/WSL2:**
- **`default`** ⭐⭐⭐⭐⭐ - Fastest (native bind mount, no sync overhead)
- **`mutagen`** ⭐⭐⭐⭐ - Fast (but unnecessary overhead on Linux)
- **`ssh`** ⭐⭐⭐⭐⭐ - Fast (files stored in container, but no local sync)

**On macOS:**
- **`mutagen`** ⭐⭐⭐⭐⭐ - Fastest (avoids macOS Docker filesystem issues)
- **`ssh`** ⭐⭐⭐⭐⭐ - Fastest (files stored in container, bypasses antivirus)
- **`default`** ⭐⭐ - Slow (macOS Docker filesystem performance issues)

**Key Notes:**
- **`ssh` mode**: Files are stored inside the container and not synchronized back to local filesystem, which prevents antivirus interference but means local file changes aren't reflected
- **`mutagen` mode**: Two-way sync with ~1s delay, good balance of performance and local file access
- **`default` mode**: Best on Linux (native), problematic on macOS due to Docker filesystem performance

### 📝 Example Configurations

#### 🐧 Linux/WSL Configuration
Create `.env.orodc` in your project root:

```bash
# Project settings
DC_ORO_NAME=myproject
DC_ORO_PORT_PREFIX=301

# PHP/Node versions
DC_ORO_PHP_VERSION=8.3
DC_ORO_NODE_VERSION=20

# Sync mode (Linux/WSL default)
DC_ORO_MODE=default

# Database (PostgreSQL recommended)
DC_ORO_PGSQL_VERSION=15.1
```

#### 🍎 macOS Configuration
Create `.env.orodc` in your project root:

```bash
# Project settings
DC_ORO_NAME=myproject
DC_ORO_PORT_PREFIX=301

# PHP/Node versions
DC_ORO_PHP_VERSION=8.3
DC_ORO_NODE_VERSION=20

# Sync mode (macOS default)
DC_ORO_MODE=mutagen

# Database (PostgreSQL recommended)
DC_ORO_PGSQL_VERSION=15.1
```

#### 🔗 Remote Docker / SSH Configuration
Create `.env.orodc` in your project root:

```bash
# Project settings
DC_ORO_NAME=myproject
DC_ORO_PORT_PREFIX=301

# PHP/Node versions
DC_ORO_PHP_VERSION=8.3
DC_ORO_NODE_VERSION=20

# Sync mode (remote Docker)
DC_ORO_MODE=ssh

# Remote Docker host (if needed)
DOCKER_HOST=ssh://user@remote-host

# Database (PostgreSQL recommended)
DC_ORO_PGSQL_VERSION=15.1
```

**🔧 Setting up Remote Development:**

1. **Start the project:**
   ```bash
   orodc up -d ssh
   ```

2. **Get SSH connection details:**
   ```bash
   orodc ps  # Check the SSH port
   ```

3. **Configure VS Code Remote Development:**
   - Install "Remote - SSH" extension
   - Add SSH configuration to `~/.ssh/config`:
   ```bash
   Host orodc-myproject
     HostName localhost
     Port [SSH_PORT_FROM_orodc_ps]
     User www-data
     IdentityFile ~/.orodc/myproject/ssh_id_ed25519
     StrictHostKeyChecking no
   ```
   - Connect via Command Palette: "Remote-SSH: Connect to Host" → `orodc-myproject`

4. **Configure PhpStorm Remote Development:**
   - Go to File → Settings → Build, Execution, Deployment → Deployment
   - Add new deployment of type "SFTP"
   - SSH configuration:
     - Host: `localhost`
     - Port: [SSH_PORT_FROM_orodc_ps]
     - User name: `www-data`
     - Authentication type: Key pair
     - Private key file: `~/.orodc/myproject/ssh_id_ed25519`
   - Set remote path to `/var/www/html`

### 🏭 Production-Like Setup Examples

**E-commerce with Consumer Processing:**
```bash
# .env.orodc
DC_ORO_NAME=orocommerce-prod
DC_ORO_PORT_PREFIX=302
DC_ORO_PHP_VERSION=8.3
DC_ORO_MODE=default

# Start with consumer services
orodc up --profile=consumer -d

# Process message queue
orodc bin/console oro:message-queue:consume --time-limit=3600
```

**Development with CLI Tools:**
```bash
# .env.orodc  
DC_ORO_NAME=oro-dev
DC_ORO_PORT_PREFIX=301
DC_ORO_PHP_VERSION=8.3
DC_ORO_MODE=mutagen

# Start with CLI profiles for development
orodc up --profile=database-cli --profile=php-cli -d

# Development workflow
orodc mysql                              # Database access
orodc php bin/console cache:clear        # Clear cache
orodc composer require new/package       # Add dependencies
```

**Multi-Service Architecture:**
```bash
# Start multiple service profiles
orodc up --profile=api --profile=worker --profile=consumer -d

# Monitor different services
orodc logs api        # API service logs
orodc logs worker     # Worker service logs  
orodc logs consumer   # Consumer service logs

# Scale specific services
orodc up --scale consumer=3 -d    # Run 3 consumer instances
```

## 🔄 Working with Existing Projects

If you have an existing OroPlatform/OroCommerce project and want to run it with OroDC, follow these steps:

### 1. Setup Environment

```bash
# Navigate to your existing project directory
cd /path/to/your/oro-project

# Initialize OroDC configuration
orodc up -d
```

### 2. Import Database

If you have an existing database dump:

```bash
# Import database from SQL dump
orodc databaseimport /path/to/your/database.sql

# Or import from compressed dump
orodc databaseimport /path/to/your/database.sql.gz
```

### 3. Update Application URLs

After importing the database, update the application URLs to match your local environment:

```bash
# Update application URLs to local development URLs
orodc update uri

# Or specify custom URL
orodc update uri https://myproject.docker.local
```

This command updates:
- `oro_ui.application_url` 
- `oro_website.url`

### 4. Clear Cache and Update Platform

```bash
# Clear application cache
orodc cache:clear

# Update platform (migrations, search index, etc.)
orodc platform update
```

### 5. Complete Project Recreation from Database Dump

For complete project recreation from an existing database dump (useful when you need a clean environment):

```bash
# Full project recreation with specific profile (single command)
orodc --profile=consumer purge && \
orodc importdb ~/orocommerce-backup-2024-01-15.sql.gz && \
orodc platformupdate && \
orodc bin/console oro:user:update --user-password=12345678 admin && \
orodc updateurl
```

**Step-by-step breakdown:**

```bash
# 1. Clean existing project with specific profile
orodc --profile=consumer purge

# 2. Import database dump  
orodc importdb ~/orocommerce-backup-2024-01-15.sql.gz

# 3. Update platform after import
orodc platformupdate

# 4. Reset admin user password
orodc bin/console oro:user:update --user-password=12345678 admin

# 5. Update URLs for local development
orodc updateurl
```

This workflow is particularly useful for:
- Setting up development environment from production backup
- Testing with real data
- Onboarding new team members with existing project state

### 6. Install Dependencies (if needed)

```bash
# Install PHP dependencies
orodc composer install

# Install and build frontend assets
orodc npm install
orodc npm run build
```

### 7. Complete Setup

```bash
# Access your application
orodc ssh

# Or open in browser
open http://localhost:30280
```

### 📋 Quick Setup Checklist

For existing projects, run these commands in order:

```bash
# 1. Start containers
orodc up -d

# 2. Import your database
orodc databaseimport /path/to/database.sql

# 3. Update URLs for local development
orodc update uri

# 4. Clear cache
orodc cache:clear

# 5. Update platform
orodc platform update

# 6. Install dependencies (if needed)
orodc composer install

# 7. Access application
open http://localhost:30280
```

## 🆘 Troubleshooting

### Common Issues

**Port conflicts:**
```bash
# Check which ports are in use
orodc down && orodc up -d

# Use different port prefix
echo "DC_ORO_PORT_PREFIX=301" >> .env.orodc
```

**Slow performance on macOS:**
```bash
# Switch to Mutagen sync
echo "DC_ORO_MODE=mutagen" >> .env.orodc
orodc down && orodc up -d
```

**Permission issues:**
```bash
# Reset Docker volumes
orodc purge
orodc install
```

**Container not starting:**
```bash
# Check logs
orodc logs [service-name]

# Rebuild containers
orodc down && orodc up -d --build
```

### 🔍 Debug Mode

Enable debug output for troubleshooting:

```bash
DEBUG=1 orodc [command]
```

## 🤝 Contributing

We welcome contributions! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- OroPlatform team for the amazing e-commerce platform
- Docker community for containerization excellence
- Homebrew maintainers for package management simplicity

---

**Made with ❤️ for the Oro community**

