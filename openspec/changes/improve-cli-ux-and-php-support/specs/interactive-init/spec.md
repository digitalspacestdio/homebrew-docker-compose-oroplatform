# Interactive Configuration Tool Specification

## ADDED Requirements

### Requirement: Input Validation with Retry Logic
The system SHALL validate all user inputs and re-prompt on invalid entries.

#### Scenario: Version selection validates numeric input
- **WHEN** user enters a non-numeric value in version selector
- **THEN** an error message SHALL be displayed
- **AND** the selection prompt SHALL be re-displayed
- **AND** user SHALL be prompted again until valid input is provided

#### Scenario: Version selection validates range
- **WHEN** user enters a number outside valid range (e.g., "77" when options are 1-6)
- **THEN** error "Invalid choice: '77'. Please enter a number between 1 and 6." SHALL be displayed
- **AND** all options SHALL be re-displayed
- **AND** user SHALL be prompted again

#### Scenario: Port validation enforces valid range
- **WHEN** user enters port number outside 1-65535 range
- **THEN** error message SHALL be displayed
- **AND** user SHALL be prompted again until valid port is entered

#### Scenario: Yes/No prompts accept multiple formats
- **WHEN** user enters 'y', 'yes', 'Y', 'YES', 'n', 'no', 'N', or 'NO'
- **THEN** input SHALL be accepted
- **WHEN** user enters any other value
- **THEN** error "Invalid input: 'X'. Please enter 'y' (yes) or 'n' (no)." SHALL be displayed
- **AND** user SHALL be prompted again

### Requirement: Smart Default Detection from Existing Configuration
The system SHALL read existing `.env.orodc` values and use them as defaults in interactive prompts.

#### Scenario: Load existing PHP version as default
- **WHEN** `.env.orodc` contains `DC_ORO_PHP_VERSION=8.3`
- **AND** user runs `orodc init`
- **THEN** PHP version selector SHALL show "8.3" as `[default]`

#### Scenario: Load existing Node.js version if compatible
- **WHEN** existing Node.js version is compatible with selected PHP
- **THEN** it SHALL be used as default
- **WHEN** existing Node.js version is incompatible with selected PHP
- **THEN** recommended default for selected PHP SHALL be used instead

#### Scenario: Load existing database type and version
- **WHEN** `.env.orodc` contains `DC_ORO_DATABASE_SCHEMA=mysql`
- **THEN** "MySQL" SHALL be pre-selected
- **AND** existing `DC_ORO_DATABASE_VERSION` SHALL be default if valid

#### Scenario: Version defaults validate service type compatibility
- **WHEN** user switches from PostgreSQL to MySQL
- **THEN** MySQL default version SHALL be used (not PostgreSQL version)
- **WHEN** user switches from Elasticsearch to OpenSearch
- **THEN** OpenSearch default version SHALL be used (not Elasticsearch version)

### Requirement: Non-Destructive Configuration Updates
The system SHALL preserve all existing variables in `.env.orodc` when updating configuration.

#### Scenario: Update only changed variables
- **WHEN** `.env.orodc` contains `DC_ORO_NAME`, `DC_ORO_PORT_PREFIX`, and `DC_ORO_MODE`
- **AND** user runs `orodc init` and changes only PHP version
- **THEN** only `DC_ORO_PHP_VERSION` related variables SHALL be updated
- **AND** `DC_ORO_NAME`, `DC_ORO_PORT_PREFIX`, and `DC_ORO_MODE` SHALL remain unchanged

#### Scenario: Preserve user comments and custom variables
- **WHEN** `.env.orodc` contains custom comments and variables
- **AND** user runs `orodc init`
- **THEN** all custom content SHALL be preserved
- **AND** only variables managed by `orodc init` SHALL be modified

#### Scenario: Create backup before modification
- **WHEN** `.env.orodc` exists
- **AND** user runs `orodc init` and saves changes
- **THEN** backup file SHALL be created with timestamp (`.env.orodc.backup.YYYYMMDD_HHMMSS`)
- **AND** original file SHALL be modified with updated values

#### Scenario: Add timestamp to configuration file
- **WHEN** configuration is saved
- **THEN** "Last updated: <timestamp>" comment SHALL be added or updated at top of file

### Requirement: Selector Input Flexibility
The system SHALL accept both option numbers and direct values in interactive selectors.

#### Scenario: Accept option number in version selector
- **WHEN** user enters "2" in PHP version selector
- **THEN** second option SHALL be selected

#### Scenario: Accept direct value in IP address selector
- **WHEN** user enters "192.168.1.100" in bind address selector
- **THEN** custom IP address SHALL be accepted without validation against option numbers

#### Scenario: Empty input selects default value
- **WHEN** user presses Enter without input
- **THEN** default value shown in `[default]` marker SHALL be selected

### Requirement: Configuration Validation on Save
The system SHALL display summary and request confirmation before saving configuration.

#### Scenario: Display configuration summary
- **WHEN** user completes all configuration sections
- **THEN** complete configuration summary SHALL be displayed
- **AND** "Save configuration to .env.orodc? [Y/n]" prompt SHALL be shown

#### Scenario: Allow cancellation before save
- **WHEN** user enters 'n' at save confirmation
- **THEN** no changes SHALL be written to disk
- **AND** message "Configuration not saved" SHALL be displayed

### Requirement: Context-Aware Custom Image Prompts
The system SHALL detect custom images and show current values in prompts.

#### Scenario: Show current custom PHP image
- **WHEN** existing image is custom (not standard ghcr.io/digitalspacestdio/orodc-php-node-symfony)
- **THEN** "Use custom PHP image? [Y/n]" SHALL default to yes
- **AND** prompt SHALL show "[current: <image>]" when asking for new value

#### Scenario: Allow keeping existing custom image
- **WHEN** user presses Enter on custom image prompt
- **AND** existing custom image is set
- **THEN** existing value SHALL be preserved

