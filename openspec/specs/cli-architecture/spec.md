# cli-architecture Specification

## Purpose
TBD - created by archiving change refactor-cli-modular-architecture. Update Purpose after archive.
## Requirements
### Requirement: Modular Command Architecture
The system SHALL organize CLI commands into separate module files under `libexec/orodc/` directory structure, with the main `bin/orodc` script acting as a lightweight router.

#### Scenario: Database commands are modular
- **GIVEN** database-related functionality exists
- **WHEN** user executes `orodc database mysql`, `orodc database psql`, `orodc database import`, `orodc database export`, or `orodc database cli`
- **THEN** main script SHALL route to `libexec/orodc/database/mysql.sh`, `libexec/orodc/database/psql.sh`, `libexec/orodc/database/import.sh`, `libexec/orodc/database/export.sh`, or `libexec/orodc/database/cli.sh` respectively
- **AND** each module SHALL be a standalone executable script
- **AND** each module SHALL source required library files from `libexec/orodc/lib/`

#### Scenario: Command aliases route to modules
- **GIVEN** convenience aliases exist (`orodc mysql`, `orodc psql`, `orodc cli`)
- **WHEN** user executes an alias command
- **THEN** main script SHALL route directly to the corresponding module file
- **AND** behavior SHALL be identical to the full command path

### Requirement: Main Script Command Routing
The main `bin/orodc` script SHALL provide command routing logic using a case statement that delegates to appropriate module files.

#### Scenario: Command routing delegates to modules
- **GIVEN** user executes `orodc <command> [subcommand] [args]`
- **WHEN** command matches a known route
- **THEN** main script SHALL shift arguments and exec the corresponding module script
- **AND** all remaining arguments SHALL be passed to the module script
- **AND** module script SHALL handle its own argument parsing

#### Scenario: Unknown commands show error
- **GIVEN** user executes an unknown command
- **WHEN** command does not match any route
- **THEN** system SHALL display error message "Unknown command: <command>"
- **AND** system SHALL suggest running `orodc help` for available commands
- **AND** exit code SHALL be 1

### Requirement: Module Structure Conventions
All command modules SHALL follow consistent structure and conventions for maintainability.

#### Scenario: Module script structure
- **GIVEN** a command module file exists
- **WHEN** module is executed
- **THEN** module SHALL start with shebang `#!/bin/bash`
- **AND** module SHALL enable strict error handling with `set -e`
- **AND** module SHALL enable debug mode with `if [ "$DEBUG" ]; then set -x; fi`
- **AND** module SHALL determine script directory using `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`
- **AND** module SHALL source required libraries from `libexec/orodc/lib/`
- **AND** module SHALL check project context when required using `check_in_project`

#### Scenario: Module library dependencies
- **GIVEN** a command module requires common functionality
- **WHEN** module sources libraries
- **THEN** module SHALL source `lib/common.sh` for common utilities
- **AND** module SHALL source `lib/ui.sh` for UI functions (msg_ok, msg_error, etc.)
- **AND** module SHALL source `lib/environment.sh` for environment initialization
- **AND** module MAY source additional libraries as needed (port-manager.sh, docker-utils.sh)

### Requirement: Database Command Module Decomposition
Database-related commands SHALL be organized in `libexec/orodc/database/` directory with separate scripts for each operation.

#### Scenario: Database command modules exist
- **GIVEN** database functionality is required
- **WHEN** system provides database commands
- **THEN** `libexec/orodc/database/mysql.sh` SHALL exist for MySQL client access
- **AND** `libexec/orodc/database/psql.sh` SHALL exist for PostgreSQL client access
- **AND** `libexec/orodc/database/import.sh` SHALL exist for database import operations
- **AND** `libexec/orodc/database/export.sh` SHALL exist for database export operations
- **AND** `libexec/orodc/database/cli.sh` SHALL exist for CLI container access

#### Scenario: Database modules use environment variables
- **GIVEN** database modules are executed
- **WHEN** modules require database connection information
- **THEN** modules SHALL use `DC_ORO_DATABASE_HOST`, `DC_ORO_DATABASE_PORT`, `DC_ORO_DATABASE_USER`, `DC_ORO_DATABASE_PASSWORD`, `DC_ORO_DATABASE_DBNAME` environment variables
- **AND** modules SHALL use `DC_ORO_DATABASE_SCHEMA` to determine database type (postgres/mysql)
- **AND** modules SHALL use `DOCKER_COMPOSE_BIN_CMD` for Docker Compose operations

### Requirement: Main Script Responsibilities
The main `bin/orodc` script SHALL handle only essential routing, initialization, and built-in commands.

#### Scenario: Main script handles version command
- **GIVEN** user executes `orodc version`
- **WHEN** version command is processed
- **THEN** main script SHALL extract version from Formula file
- **AND** main script SHALL display version without delegating to modules
- **AND** main script SHALL exit immediately after displaying version

#### Scenario: Main script handles help command
- **GIVEN** user executes `orodc help` or `orodc man`
- **WHEN** help command is processed
- **THEN** main script SHALL locate and display README.md file
- **AND** main script SHALL fall back to basic help if README not found
- **AND** main script SHALL exit immediately after displaying help

#### Scenario: Main script initializes environment
- **GIVEN** user executes a command requiring project context
- **WHEN** command is not in skip list (help, version, proxy, image)
- **THEN** main script SHALL call `initialize_environment` before routing
- **AND** main script SHALL allow graceful failure for menu command when not in project

### Requirement: Command Group Organization
Related commands SHALL be organized into logical groups with subcommand routing.

#### Scenario: Database command group routing
- **GIVEN** user executes `orodc database <subcommand>`
- **WHEN** subcommand is mysql, psql, import, export, or cli
- **THEN** main script SHALL route to appropriate `libexec/orodc/database/<subcommand>.sh`
- **AND** main script SHALL display error for unknown database subcommands

#### Scenario: Tests command group routing
- **GIVEN** user executes `orodc tests <subcommand>`
- **WHEN** subcommand is install, run, behat, phpunit, or shell
- **THEN** main script SHALL route to appropriate `libexec/orodc/tests/<subcommand>.sh`
- **AND** main script SHALL display error for unknown tests subcommands

#### Scenario: Proxy command group routing
- **GIVEN** user executes `orodc proxy <subcommand>`
- **WHEN** subcommand is up, down, or install-certs
- **THEN** main script SHALL route to appropriate `libexec/orodc/proxy/<subcommand>.sh`
- **AND** main script SHALL display error for unknown proxy subcommands

### Requirement: Single-File Command Modules
Simple commands without subcommands SHALL be implemented as single module files directly under `libexec/orodc/`.

#### Scenario: Single-file command routing
- **GIVEN** commands like `init`, `purge`, `config-refresh`, `ssh`, `install`, `cache`, `php`, `composer`, `platform-update` exist
- **WHEN** user executes `orodc <command>`
- **THEN** main script SHALL route directly to `libexec/orodc/<command>.sh`
- **AND** no subcommand routing SHALL be required

### Requirement: Command Aliases
The system SHALL provide convenient aliases for commonly used commands while maintaining modular routing.

#### Scenario: Compose command aliases
- **GIVEN** user executes `orodc start`, `orodc stop`, `orodc restart`, `orodc up`, `orodc down`, `orodc logs`, or `orodc ps`
- **WHEN** alias command is executed
- **THEN** main script SHALL route to `libexec/orodc/compose.sh` with appropriate subcommand
- **AND** behavior SHALL be identical to `orodc compose <subcommand>`

#### Scenario: Database command aliases
- **GIVEN** user executes `orodc mysql`, `orodc psql`, or `orodc cli`
- **WHEN** alias command is executed
- **THEN** main script SHALL route directly to corresponding database module
- **AND** behavior SHALL be identical to `orodc database <subcommand>`

### Requirement: Error Handling for Deprecated Commands
The system SHALL provide helpful error messages for deprecated command syntax.

#### Scenario: Old Docker Compose syntax shows migration help
- **GIVEN** user executes old syntax like `orodc build`, `orodc config`, `orodc exec`, etc.
- **WHEN** deprecated command is detected
- **THEN** system SHALL display error message "Docker Compose commands must use 'compose' prefix"
- **AND** system SHALL show old syntax and new syntax examples
- **AND** system SHALL suggest running `orodc help` for more information
- **AND** exit code SHALL be 1

### Requirement: Future Decomposition Guidelines
The system SHALL maintain guidelines for when further decomposition of the main script should be considered.

#### Scenario: Current main script size is acceptable
- **GIVEN** main script acts as a router
- **WHEN** main script size is approximately 357 lines
- **THEN** current size SHALL be considered reasonable for a router
- **AND** further decomposition SHALL only be considered if specific conditions are met

#### Scenario: Conditions for extracting version command
- **GIVEN** version command is currently implemented in main script
- **WHEN** version command logic grows in complexity beyond simple version extraction
- **THEN** version command MAY be extracted to `libexec/orodc/version.sh` module
- **AND** extraction SHALL only occur if version command exceeds ~100 lines or requires complex logic

#### Scenario: Conditions for extracting help command
- **GIVEN** help command is currently implemented in main script
- **WHEN** help generation becomes more sophisticated (dynamic generation, multiple formats, etc.)
- **THEN** help command MAY be extracted to `libexec/orodc/help.sh` module
- **AND** extraction SHALL only occur if help command exceeds ~100 lines or requires complex logic

#### Scenario: Conditions for externalizing routing logic
- **GIVEN** command routing is currently implemented as a case statement in main script
- **WHEN** routing logic becomes unwieldy (excessive nesting, complex patterns, etc.)
- **THEN** routing logic MAY be externalized to a routing configuration file
- **AND** externalization SHALL only occur if routing logic exceeds maintainability thresholds
- **AND** externalization SHALL only occur if new requirements demand more sophisticated command discovery

#### Scenario: Decomposition decision criteria
- **GIVEN** consideration of further decomposition
- **WHEN** evaluating whether to extract functionality from main script
- **THEN** extraction SHALL be considered if individual command handlers exceed ~100 lines
- **AND** extraction SHALL be considered if routing logic becomes complex enough to warrant externalization
- **AND** extraction SHALL be considered if new requirements demand more sophisticated command discovery
- **AND** extraction SHALL NOT be performed solely for the sake of reducing main script size

