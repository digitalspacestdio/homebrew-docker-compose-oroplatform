
# ORO Platform Docker Compose (OroDC)
![Docker architecture](docs/docker-architecture-small.png)
CLI tool to run ORO applications locally or on a server. Designed specifically for local development environments.

## Supported Systems
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

## Installation
Install via Homebrew:

```bash
brew install digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform
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

2. **Install Homebrew** (recommended):
   - [Follow this guide](https://brew.sh/)

3. **Install OroDC**:
   ```bash
   brew install digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform
   ```

4. **Clone your Oro project**:
   ```bash
   git clone --single-branch --branch 6.1.0 https://github.com/oroinc/orocommerce-application.git ~/orocommerce
   cd ~/orocommerce
   ```

5. **Pull Docker images and install Composer dependencies**:
   ```bash
   orodc pull
   orodc composer install -o --no-interaction
   ```

6. (Optional) Adjust your database connection settings (PostgreSQL by default).

7. **Launch the environment**:
   ```bash
   orodc up -d
   ```

8. **Install Oro application with sample data**:
   ```bash
   orodc install
   ```

9. **Open your application**:
   ```
   http://localhost:30280/
   ```

10. **Develop using your favorite IDE (PHPStorm or VSCode Remote Development)**

## Usage

Basic commands:

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

XDEBUG
```bash
# CLI + FPM 
XDEBUG_MODE_FPM=debug XDEBUG_MODE_CLI=debug orodc up -d

# FPM only 
XDEBUG_MODE_FPM=debug orodc up -d

# CLI only
XDEBUG_MODE_CLI=debug orodc up -d
```

## Environment Variables

Variables can be stored in `.env.orodc`, `.env-app.local`, `.env-app`, or `.env` in the project root.

Important options:
- **DC_ORO_MODE** - (`default`|`ssh`|`mutagen`)
   * `default` - uses bind mount (this is default for linux and wsl hosts)
   * `ssh` - uses isolated docker volume
   * `mutagen` - uses isomutagen with isolated docker volume (this is default for macos hosts)
- **DC_ORO_COMPOSER_VERSION** - Composer version (`1`|`2` default:`2`)
- **DC_ORO_PHP_VERSION** - PHP version (`7.4`, `8.1`, `8.2`, `8.3`, `8.4`)
- **DC_ORO_NODE_VERSION** - Node.js version (`18`, `20`, `22`)
- **DC_ORO_MYSQL_IMAGE** - MySQL image (not recommended)
- **DC_ORO_PGSQL_VERSION** - PostgreSQL version (default: `15.1`)
- **DC_ORO_ELASTICSEARCH_VERSION** - Elasticsearch version (default: `8.9.1`)
- **DC_ORO_NAME** - Project name (defaults to directory name)
- **DC_ORO_PORT_PREFIX** - Port prefix (default `302`)