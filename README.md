# OroCommerce|OroCRM|OroPlatform Docker Environment

**Supported Systems**
* MacOs (Intel, Apple Silicon)
* Linux (AMD64, ARM64)
* Windows via WSL2 (AMD64)

## Pre-requirements
### Docker
**MacOs**  
Install Docker for Mac: https://docs.docker.com/desktop/mac/install/  

**Linux (Ubuntu and others)**  
Install Docker Engine: https://docs.docker.com/engine/install/ubuntu/  
Install Docker Compose https://docs.docker.com/compose/install/compose-plugin/

**Windows**  
Follow this guide: https://docs.docker.com/desktop/windows/wsl/  

### Homebrew (MacOs/Linux/Windows)
Install Homebrew by following guide https://docs.brew.sh/Installation

### Configure COMPOSER Credentials (optional)
If no local composer setup exists you will need to export following variable or add it to the `.bashrc` or `.zshrc` file
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

Also you can user the command to obtain the value from any machine:
```bash
echo "export COMPOSER_AUTH='"$(cat $(php -d display_errors=0 $(which composer) config --no-interaction --global home 2>/dev/null)/auth.json)"'"
```

## Installation
Install via homebrew by following command
```bash
brew install digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform
```

## Usage
1. Clone the application source code
```bash
git clone --single-branch --branch 6.1.0 https://github.com/oroinc/orocommerce-application.git ~/orocommerce
```
1. Navigate to the directory
```bash
cd ~/orocommerce
```
1. Pull docker images
```bash
orodc pull
```
1. Pull docker images
```bash
orodc pull
```
1. Install composer dependencies
```bash
orodc composer install -o --no-interaction
```
1. Optionally: Ajust the database driver in the `config/parameters.yml` (or `.env-app`) file.
> example: `ORO_DB_URL=postgres://application:application@database:5432/application?sslmode=disable&charset=utf8&serverVersion=13.7`
1. Install the application by following command
```bash
orodc bin/console --env=prod --timeout=1800 oro:install --language=en --formatting-code=en_US --organization-name='Acme Inc.' --user-name=admin --user-email=admin@example.com --user-firstname=John --user-lastname=Doe --user-password='$ecretPassw0rd' --application-url='http://localhost:30180/' --sample-data=y
```
1. Optional: import database dump (supports `*.sql` and `*.sql.gz` files)
```bash
orodc import-database /path/to/dump.sql.gz
```
1. Start the stack in the background mode
```bash
orodc up -d
```

## Stop the project
Stop containers
```bash
orodc down
```

To cleanup temporary data use (this is will drop database and search data too)
```bash
orodc down -v
```

## Extra tools
Connecting to the cli container
```bash
orodc bash
```

To generate the compose config use
```bash
orodc config > compose.yml
```

## Environment Variables
> Can be stored in the `.dockenv`, `.dockerenv` or `.env` file in the project root
* `DC_ORO_MODE` - (`default`|`ssh`|`mutagen`)
* `DC_ORO_COMPOSER_VERSION` - (`1|2` )
* `DC_ORO_PHP_VERSION` - (`7.4`|`8.1`|`8.2`|`8.3`|`8.4`), the image built from a corresponding `fpm-alpine` image, see https://hub.docker.com/_/php/?tab=tags&page=1&name=fpm-alpine&ordering=name for more versions
* `DC_ORO_NODE_VERSION` - (`18`|`20`|`22`) the image will be built from a corresponding `alpine` image, see https://hub.docker.com/_/node/tags?page=1&name=alpine3.16 for more versions
* `DC_ORO_MYSQL_IMAGE` - `mysql:8.0-oracle` see https://hub.docker.com/_/mysql/?tab=tags for more versions
* `DC_ORO_PGSQL_VERSION` - `15.1` see https://hub.docker.com/_/postgres/?tab=tags for more versions
* `DC_ORO_ELASTICSEARCH_VERSION` - `8.9.1` see https://www.docker.elastic.co/r/elasticsearch/elasticsearch-oss for more versions
* `DC_ORO_NAME` - by default the working directory name will be used
* `DC_ORO_PORT_PREFIX` - `302` by default

