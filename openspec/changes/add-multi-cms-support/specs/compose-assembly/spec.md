## ADDED Requirements

### Requirement: Compose File Assembly Order for Multi-CMS Support

The system SHALL assemble Docker Compose command with files in specific order to ensure proper override behavior, supporting multiple CMS types.

#### Scenario: Standard compose file order for base PHP/Symfony/Laravel project
- **WHEN** compose command is built for base CMS type with PostgreSQL
- **THEN** files SHALL be included in this order:
  1. `docker-compose.yml` (base services: CLI, FPM, Nginx, Database, Redis, Elasticsearch)
  2. `docker-compose-default.yml` (sync mode, if applicable)
  3. `docker-compose-pgsql.yml` or `docker-compose-mysql.yml` (database-specific)
  4. `.docker-compose.user.yml` (user custom, if exists)
- **AND** `docker-compose-consumer.yml`, `docker-compose-websocket.yml`, `docker-compose-cron.yml` SHALL NOT be included

#### Scenario: Standard compose file order for Oro project
- **WHEN** compose command is built for Oro CMS type with PostgreSQL
- **THEN** files SHALL be included in this order:
  1. `docker-compose.yml` (base services)
  2. `docker-compose-default.yml` (sync mode, if applicable)
  3. `docker-compose-pgsql.yml` or `docker-compose-mysql.yml` (database-specific)
  4. `docker-compose-consumer.yml` (Oro consumer service)
  5. `docker-compose-websocket.yml` (Oro websocket service)
  6. `.docker-compose.user.yml` (user custom, if exists)
- **AND** `docker-compose-cron.yml` SHALL NOT be included

#### Scenario: Standard compose file order for Magento project
- **WHEN** compose command is built for Magento CMS type with MySQL
- **THEN** files SHALL be included in this order:
  1. `docker-compose.yml` (base services)
  2. `docker-compose-default.yml` (sync mode, if applicable)
  3. `docker-compose-mysql.yml` (database-specific, typically MySQL for Magento)
  4. `docker-compose-cron.yml` (Magento cron service)
  5. `.docker-compose.user.yml` (user custom, if exists)
- **AND** `docker-compose-consumer.yml` and `docker-compose-websocket.yml` SHALL NOT be included

## ADDED Requirements

### Requirement: WebSocket Service in Separate Compose File

The Oro WebSocket service SHALL be defined in a separate compose file that is conditionally included based on CMS type detection.

#### Scenario: WebSocket service defined in docker-compose-websocket.yml
- **WHEN** OroDC compose files are processed
- **THEN** `websocket` service definition SHALL exist in `compose/docker-compose-websocket.yml`
- **AND** `websocket` service SHALL NOT exist in base `compose/docker-compose.yml`
- **AND** `docker-compose-websocket.yml` SHALL contain full websocket service configuration including build, volumes, environment, depends_on, Traefik labels

#### Scenario: WebSocket compose file included for Oro projects
- **WHEN** `orodc up` or similar compose command is executed
- **AND** CMS type is detected as `oro` (via `detect_cms_type()` or `DC_ORO_CMS_TYPE=oro`)
- **THEN** `docker-compose-websocket.yml` SHALL be included in compose command via `-f` flag
- **AND** websocket service SHALL start with other services

#### Scenario: WebSocket compose file excluded for non-Oro projects
- **WHEN** `orodc up` or similar compose command is executed
- **AND** CMS type is NOT detected as `oro`
- **THEN** `docker-compose-websocket.yml` SHALL NOT be included in compose command
- **AND** no websocket service SHALL be started
- **AND** no errors related to missing `gos:websocket:server` command SHALL occur

### Requirement: Cron Service in Separate Compose File

The Magento cron service SHALL be defined in a separate compose file that is conditionally included based on CMS type detection.

#### Scenario: Cron service defined in docker-compose-cron.yml
- **WHEN** OroDC compose files are processed
- **THEN** `cron` service definition SHALL exist in `compose/docker-compose-cron.yml`
- **AND** `cron` service SHALL NOT exist in base `compose/docker-compose.yml`
- **AND** `docker-compose-cron.yml` SHALL contain full cron service configuration using Ofelia image

#### Scenario: Cron compose file included for Magento projects
- **WHEN** `orodc up` or similar compose command is executed
- **AND** CMS type is detected as `magento` (via `detect_cms_type()` or `DC_ORO_CMS_TYPE=magento`)
- **THEN** `docker-compose-cron.yml` SHALL be included in compose command via `-f` flag
- **AND** cron service SHALL start with other services

#### Scenario: Cron compose file excluded for non-Magento projects
- **WHEN** `orodc up` or similar compose command is executed
- **AND** CMS type is NOT detected as `magento`
- **THEN** `docker-compose-cron.yml` SHALL NOT be included in compose command
- **AND** no cron service SHALL be started

#### Scenario: Cron service waits for cron.sh file
- **WHEN** cron service starts
- **AND** `cron.sh` file does NOT exist in project root
- **THEN** cron service SHALL sleep for 5 seconds
- **AND** SHALL check again for `cron.sh` file
- **AND** SHALL repeat until `cron.sh` file appears

#### Scenario: Cron service runs cron.sh when available
- **WHEN** cron service starts
- **AND** `cron.sh` file exists in project root
- **THEN** cron service SHALL execute `cron.sh` using Ofelia
- **AND** SHALL continue running scheduled tasks

### Requirement: Base Compose File Contains Only Core Services

The base `docker-compose.yml` file SHALL contain only core services that are common to all CMS types.

#### Scenario: Base compose file services
- **WHEN** base `docker-compose.yml` is examined
- **THEN** it SHALL contain these services:
  - `cli` (PHP CLI container)
  - `fpm` (PHP-FPM container)
  - `nginx` (Nginx web server)
  - `database` (placeholder, replaced by database-specific compose file)
  - `redis` (Redis cache)
  - `search` (Elasticsearch)
  - `mq` (RabbitMQ, if applicable)
  - `mail` (MailHog for testing)
- **AND** SHALL NOT contain:
  - `consumer` service (moved to `docker-compose-consumer.yml`)
  - `websocket` service (moved to `docker-compose-websocket.yml`)
  - `cron` service (moved to `docker-compose-cron.yml`)
