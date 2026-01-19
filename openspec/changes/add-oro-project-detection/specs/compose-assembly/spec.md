## ADDED Requirements

### Requirement: Consumer Service in Separate Compose File

The Oro message queue consumer service SHALL be defined in a separate compose file that is conditionally included based on Oro project detection.

#### Scenario: Consumer service defined in docker-compose-consumer.yml
- **WHEN** OroDC compose files are processed
- **THEN** `consumer` service definition SHALL exist in `compose/docker-compose-consumer.yml`
- **AND** `consumer` service SHALL NOT exist in base `compose/docker-compose.yml`
- **AND** `docker-compose-consumer.yml` SHALL contain full consumer service configuration including build, volumes, environment, depends_on

#### Scenario: Consumer compose file included for Oro projects
- **WHEN** `orodc up` or similar compose command is executed
- **AND** project is detected as Oro project (via `is_oro_project()` or `DC_ORO_IS_ORO_PROJECT=1`)
- **THEN** `docker-compose-consumer.yml` SHALL be included in compose command via `-f` flag
- **AND** consumer service SHALL start with other services

#### Scenario: Consumer compose file excluded for non-Oro projects
- **WHEN** `orodc up` or similar compose command is executed
- **AND** project is NOT detected as Oro project
- **THEN** `docker-compose-consumer.yml` SHALL NOT be included in compose command
- **AND** no consumer service SHALL be started
- **AND** no errors related to missing `oro:message-queue:consume` command SHALL occur

### Requirement: Compose File Assembly Order

The system SHALL assemble Docker Compose command with files in specific order to ensure proper override behavior.

#### Scenario: Standard compose file order for Oro project
- **WHEN** compose command is built for Oro project with PostgreSQL
- **THEN** files SHALL be included in this order:
  1. `docker-compose.yml` (base services)
  2. `docker-compose-default.yml` (sync mode, if applicable)
  3. `docker-compose-pgsql.yml` (database)
  4. `docker-compose-consumer.yml` (Oro consumer)
  5. `.docker-compose.user.yml` (user overrides, if exists)

#### Scenario: Standard compose file order for non-Oro project
- **WHEN** compose command is built for non-Oro project with PostgreSQL
- **THEN** files SHALL be included in this order:
  1. `docker-compose.yml` (base services)
  2. `docker-compose-default.yml` (sync mode, if applicable)
  3. `docker-compose-pgsql.yml` (database)
  4. `.docker-compose.user.yml` (user overrides, if exists)
- **AND** `docker-compose-consumer.yml` SHALL NOT be included

### Requirement: Debug Output for Compose Assembly

The system SHALL provide debug output showing which compose files are included and why.

#### Scenario: Debug shows Oro detection result
- **WHEN** `DEBUG=1` environment variable is set
- **AND** compose command is being built
- **THEN** debug output SHALL show whether project is detected as Oro
- **AND** debug output SHALL list all compose files being included
- **AND** debug output SHALL indicate if consumer compose is included or excluded
