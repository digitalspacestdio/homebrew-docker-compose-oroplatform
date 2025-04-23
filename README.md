# ORO Platform Docker Compose

CLI tool to run ORO applications locally or on the server. This tool is specially designed for local development environments.

## Supported Systems
- MacOS (Intel, Apple Silicon)
- Linux (AMD64, ARM64)
- Windows via WSL2 (AMD64)

## Pre-requirements

### Docker
- **MacOS**: [Install Docker for Mac](https://docs.docker.com/desktop/mac/install/)
- **Linux** (Ubuntu and others):
  - [Install Docker Engine](https://docs.docker.com/engine/install/ubuntu/)
  - [Install Docker Compose](https://docs.docker.com/compose/install/compose-plugin/)
- **Windows**: [Follow this guide](https://docs.docker.com/desktop/windows/wsl/)

### Homebrew (MacOs/Linux/Windows)
- [Install Homebrew by following this guide](https://docs.brew.sh/Installation)

### Configure COMPOSER Credentials (optional)
If no local composer setup exists, export the following variable or add it to the .bashrc or .zshrc file:
```bash
export DC_ORO_COMPOSER_AUTH='{
  "http-basic": {
    "repo.example.com": {
      "username": "xxxxxxxxxxxx",
      "password": "yyyyyyyyyyyy"
    }
  },
  "github-oauth": {
    "github.com": "xxxxxxxxxxxx"
  },
  "gitlab-token": {
    "example.org": "xxxxxxxxxxxx"
  }
}'
```

Also, you can use the command to obtain values from any machine:
```bash
echo "export COMPOSER_AUTH='"$(cat $(php -d display_errors=0 $(which composer) config --no-interaction --global home 2>/dev/null)/auth.json)"'"
```

## Installation
Install via homebrew with the following command:
```bash
brew install digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform
```

## Usage
Clone the application source code:
```bash
git clone --single-branch --branch 6.1.0 https://github.com/oroinc/orocommerce-application.git ~/orocommerce
```

Navigate to the directory:
```bash
cd ~/orocommerce
```

Pull docker images and install composer dependencies:
```bash
orodc pull
orodc composer install -o --no-interaction
```

Optionally, adjust the database driver in the config/parameters.yml or .env-app file:
```
example: ORO_DB_URL=postgres://application:application@database:5432/application?sslmode=disable&charset=utf8&serverVersion=13.7
```

Install the application using the following command:
```bash
orodc bin/console --env=prod --timeout=1800 oro:install --language=en --formatting-code=en_US --organization-name='Acme Inc.' --user-name=admin --user-email=admin@example.com --user-firstname=John --user-lastname=Doe --user-password='$ecretPassw0rd' --application-url='http://localhost:30180/' --sample-data=y
```

Optional: import a database dump (supports *.sql and *.sql.gz files):
```bash
orodc import-database /path/to/dump.sql.gz
```

Start and stop the stack:
```bash
orodc up -d
orodc down
```

To cleanup temporary data use:
```bash
orodc down -v
```

## Environment Variables
Variables can be stored in the .dockenv, .dockerenv or .env file in the project root. Here is a list of the main configuration options:
- **DC_ORO_MODE** - (`default`|`ssh`|`mutagen`)
- **DC_ORO_COMPOSER_VERSION** - (`1`|`2`)
- **DC_ORO_PHP_VERSION** - (`7.4`|`8.1`|`8.2`|`8.3`|`8.4`), image built from the corresponding `fpm-alpine` image. [See more versions](https://hub.docker.com/_/php/?tab=tags&page=1&name=fpm-alpine&ordering=name)
- **DC_ORO_NODE_VERSION** - (`18`|`20`|`22`), image will be built from the corresponding `alpine` image. [See more versions](https://hub.docker.com/_/node/tags?page=1&name=alpine3.16)
- **DC_ORO_MYSQL_IMAGE** - `mysql:8.0-oracle`. [See more versions](https://hub.docker.com/_/mysql/?tab=tags)
- **DC_ORO_PGSQL_VERSION** - `15.1`. [See more versions](https://hub.docker.com/_/postgres/?tab=tags)
- **DC_ORO_ELASTICSEARCH_VERSION** - `8.9.1`. [See more versions](https://www.docker.elastic.co/r/elasticsearch/elasticsearch-oss)
- **DC_ORO_NAME** - by default the working directory name will be used
- **DC_ORO_PORT_PREFIX** - `302` by default

## Extra Tools
- **Connecting to the cli container**: 
```bash
orodc bash
```
- **To generate the compose config use**:
```bash
orodc config > compose.yml
```
