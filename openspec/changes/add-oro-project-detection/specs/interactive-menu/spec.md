## MODIFIED Requirements

### Requirement: Interactive Menu Display When No Arguments Provided

The system SHALL display an interactive menu when `orodc` is executed without any arguments in an interactive terminal. Menu items SHALL be conditionally displayed based on whether the project is an Oro Platform application.

#### Scenario: Display menu when no arguments provided
- **WHEN** user runs `orodc` without any arguments
- **AND** terminal is interactive (TTY)
- **THEN** an interactive menu SHALL be displayed
- **AND** current environment context SHALL be shown (name, status, directory)
- **AND** user SHALL be prompted to select an option

#### Scenario: Display full menu for Oro projects
- **WHEN** menu is displayed
- **AND** project is detected as Oro project (via `is_oro_project()` or `DC_ORO_IS_ORO_PROJECT=1`)
- **THEN** all menu options (1-18) SHALL be displayed including Oro-specific items:
  - 12) Platform update
  - 17) Install with demo data
  - 18) Install without demo data

#### Scenario: Display reduced menu for non-Oro projects
- **WHEN** menu is displayed
- **AND** project is NOT detected as Oro project
- **THEN** Oro-specific menu items SHALL be hidden:
  - Platform update SHALL NOT be displayed
  - Install with demo data SHALL NOT be displayed
  - Install without demo data SHALL NOT be displayed
- **AND** remaining menu items SHALL be renumbered to fill gaps
- **AND** menu numbering SHALL remain sequential without gaps

#### Scenario: Display grouped menu in single column
- **WHEN** menu is displayed in terminals narrower than 100 columns
- **THEN** menu options SHALL be grouped under headings in this order: Environment Management (1-6, includes SSH), Configuration (7-8), Database (9-10), Maintenance (11-13 for Oro, 11 for non-Oro), Other (14-16 for Oro, 12-14 for non-Oro), Installation (17-18 for Oro only)
- **AND** each option number SHALL align with its heading and description

#### Scenario: Display grouped menu in two columns
- **WHEN** menu is displayed in terminals 100 columns wide or more
- **THEN** menu SHALL render a two-column layout with paired headings
- **AND** Oro-specific sections SHALL be omitted for non-Oro projects

#### Scenario: Skip menu in non-interactive mode
- **WHEN** user runs `orodc` without arguments
- **AND** terminal is not interactive (piped input, script execution)
- **THEN** menu SHALL be skipped
- **AND** system SHALL fall through to default Docker Compose behavior

#### Scenario: Skip menu when arguments provided
- **WHEN** user runs `orodc` with any arguments (e.g., `orodc up -d`)
- **THEN** menu SHALL be skipped
- **AND** command SHALL execute normally

#### Scenario: Skip menu with environment variable
- **WHEN** `ORODC_NO_MENU=1` environment variable is set
- **THEN** menu SHALL be skipped even in interactive mode

### Requirement: Menu Option: Platform Update

The system SHALL provide a menu option to perform platform update, visible only for Oro projects.

#### Scenario: Platform update visible for Oro projects
- **WHEN** menu is displayed
- **AND** project is detected as Oro project
- **THEN** "Platform update" option SHALL be visible in Maintenance section

#### Scenario: Platform update hidden for non-Oro projects
- **WHEN** menu is displayed
- **AND** project is NOT detected as Oro project
- **THEN** "Platform update" option SHALL NOT be displayed

#### Scenario: Platform update stops services and runs CLI only
- **WHEN** user selects "Platform update" option
- **THEN** system SHALL stop all application services (FPM, Nginx, WebSocket, Consumer)
- **AND** system SHALL keep dependency services running (Database, Redis, Elasticsearch, RabbitMQ)
- **AND** system SHALL execute `docker compose run --rm cli php bin/console oro:platform:update --force`
- **AND** progress SHALL be displayed during update
- **AND** after completion, success message SHALL be displayed

### Requirement: Menu Option: Install With Demo Data

The system SHALL provide a menu option to install with demo data, visible only for Oro projects.

#### Scenario: Install with demo visible for Oro projects
- **WHEN** menu is displayed
- **AND** project is detected as Oro project
- **THEN** "Install with demo data" option SHALL be visible in Installation section

#### Scenario: Install with demo hidden for non-Oro projects
- **WHEN** menu is displayed
- **AND** project is NOT detected as Oro project
- **THEN** "Install with demo data" option SHALL NOT be displayed

### Requirement: Menu Option: Install Without Demo Data

The system SHALL provide a menu option to install without demo data, visible only for Oro projects.

#### Scenario: Install without demo visible for Oro projects
- **WHEN** menu is displayed
- **AND** project is detected as Oro project
- **THEN** "Install without demo data" option SHALL be visible in Installation section

#### Scenario: Install without demo hidden for non-Oro projects
- **WHEN** menu is displayed
- **AND** project is NOT detected as Oro project
- **THEN** "Install without demo data" option SHALL NOT be displayed
