## ADDED Requirements

### Requirement: Interactive Menu Display When No Arguments Provided

The system SHALL display an interactive menu when `orodc` is executed without any arguments in an interactive terminal.

#### Scenario: Display menu when no arguments provided
- **WHEN** user runs `orodc` without any arguments
- **AND** terminal is interactive (TTY)
- **THEN** an interactive menu SHALL be displayed with numbered options (1-18)
- **AND** current environment context SHALL be shown (name, status, directory)
- **AND** user SHALL be prompted to select an option

#### Scenario: Display grouped menu in single column
- **WHEN** menu is displayed in terminals narrower than 100 columns
- **THEN** menu options SHALL be grouped under headings in this order: Environment Management (1-6, includes SSH), Configuration (7-8), Database (9-10), Maintenance (11-13), Other (14-16, includes Image build and proxy), Installation (17-18)
- **AND** each option number SHALL align with its heading and description

#### Scenario: Display grouped menu in two columns
- **WHEN** menu is displayed in terminals 100 columns wide or more
- **THEN** menu SHALL render a two-column layout with paired headings: Environment Management vs Configuration; Database vs Maintenance; Other vs Installation
- **AND** options 1-18 SHALL be displayed in the same numeric order as the single-column layout, preserving their groupings

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
- **WHEN** `DC_ORO_NO_MENU=1` environment variable is set
- **THEN** menu SHALL be skipped even in interactive mode

### Requirement: Environment Registry Management

The system SHALL maintain a registry of all OroDC environments with their paths and status information.

#### Scenario: Auto-discover environments from config directory
- **WHEN** menu is displayed for the first time
- **AND** `~/.orodc/` directory exists
- **THEN** system SHALL scan subdirectories for environments
- **AND** each directory containing `compose.yml` or `.env.orodc` SHALL be registered
- **AND** environment name SHALL be extracted from directory name or `DC_ORO_NAME` from config

#### Scenario: Store environment registry
- **WHEN** environment is discovered or manually registered
- **THEN** registry SHALL be stored in `~/.orodc/environments.json`
- **AND** registry SHALL include: name, path, config_dir, last_used timestamp

#### Scenario: Read environment registry
- **WHEN** menu option "List all environments" is selected
- **THEN** system SHALL read `~/.orodc/environments.json`
- **AND** display all registered environments with their status

### Requirement: Environment Status Detection

The system SHALL detect and display the current status (running/stopped) of environments.

#### Scenario: Detect running environment
- **WHEN** environment has active Docker Compose containers
- **THEN** status SHALL be displayed as "running"
- **WHEN** environment has no active containers
- **THEN** status SHALL be displayed as "stopped"

#### Scenario: Show current environment in menu
- **WHEN** menu is displayed
- **AND** current directory matches a registered environment
- **THEN** menu header SHALL show: "Current Environment: {name} ({status})"
- **AND** current directory path SHALL be displayed

### Requirement: Menu Option: List All Environments

The system SHALL provide a menu option to display all registered environments.

#### Scenario: Display environment list
- **WHEN** user selects option "1) List all environments"
- **THEN** system SHALL display a table with columns: Name, Path, Status, Last Used
- **AND** environments SHALL be sorted by last_used timestamp (most recent first)
- **AND** after display, menu SHALL return to main menu

### Requirement: Menu Option: Initialize Environment

The system SHALL provide a menu option to initialize and configure an environment.

#### Scenario: Run init from menu
- **WHEN** user selects option "2) Initialize environment and determine versions"
- **THEN** system SHALL execute `orodc init` command
- **AND** after completion, menu SHALL return to main menu

### Requirement: Menu Option: Start Environment

The system SHALL provide a menu option to start the environment in the current directory.

#### Scenario: Start environment from menu
- **WHEN** user selects option "3) Start environment in current folder"
- **AND** current directory contains a valid OroDC environment
- **THEN** system SHALL execute `orodc up -d` in current directory
- **AND** after completion, menu SHALL return to main menu

#### Scenario: Error when no environment in current directory
- **WHEN** user selects option "3) Start environment in current folder"
- **AND** current directory does not contain a valid OroDC environment
- **THEN** error message SHALL be displayed
- **AND** menu SHALL return to main menu

### Requirement: Menu Option: Stop Environment

The system SHALL provide a menu option to stop the environment.

#### Scenario: Stop environment from menu
- **WHEN** user selects option "4) Stop environment"
- **AND** current directory contains a running environment
- **THEN** system SHALL execute `orodc down` in current directory
- **AND** after completion, menu SHALL return to main menu

### Requirement: Menu Option: Delete Environment

The system SHALL provide a menu option to delete an environment with confirmation.

#### Scenario: Delete environment with confirmation
- **WHEN** user selects option "5) Delete environment"
- **THEN** warning message about data deletion SHALL be displayed
- **AND** confirmation prompt SHALL be shown: "Are you sure? This will delete all containers and volumes. [y/N]"
- **WHEN** user confirms with 'y' or 'yes'
- **THEN** system SHALL execute `orodc purge`
- **AND** environment SHALL be removed from registry
- **WHEN** user enters 'n' or presses Enter
- **THEN** operation SHALL be cancelled
- **AND** menu SHALL return to main menu

### Requirement: Menu Option: Add/Manage Domains

The system SHALL provide a menu option to interactively manage `DC_ORO_EXTRA_HOSTS` configuration.

#### Scenario: Display current domains
- **WHEN** user selects option "7) Add/Manage domains"
- **THEN** current `DC_ORO_EXTRA_HOSTS` value SHALL be displayed from `.env.orodc` or environment
- **AND** prompt SHALL be shown: "Add domain (or 'remove <domain>' to delete, 'done' to finish):"

#### Scenario: Add new domain
- **WHEN** user enters a domain name (e.g., "api")
- **THEN** domain SHALL be validated (trim whitespace, handle short/full hostnames)
- **AND** domain SHALL be added to `DC_ORO_EXTRA_HOSTS` in `.env.orodc`
- **AND** updated list SHALL be displayed
- **AND** prompt SHALL be shown again for additional domains

#### Scenario: Remove domain
- **WHEN** user enters "remove api"
- **THEN** "api" SHALL be removed from `DC_ORO_EXTRA_HOSTS`
- **AND** updated list SHALL be displayed
- **AND** prompt SHALL be shown again

#### Scenario: Finish domain management
- **WHEN** user enters "done"
- **THEN** final domain list SHALL be displayed
- **AND** menu SHALL return to main menu

#### Scenario: Validate domain format
- **WHEN** user enters invalid domain format
- **THEN** error message SHALL be displayed
- **AND** user SHALL be prompted again

### Requirement: Menu Option: Configure Application URL

The system SHALL provide a menu option to configure the application URL interactively.

#### Scenario: Display current URL and prompt for new
- **WHEN** user selects option "8) Configure application URL"
- **THEN** current application URL SHALL be displayed (from config or default)
- **AND** prompt SHALL be shown: "Enter new application URL [default: https://${DC_ORO_NAME}.docker.local]:"

#### Scenario: Update URL with user input
- **WHEN** user enters a URL (e.g., "https://myproject.local")
- **AND** URL starts with `http://` or `https://`
- **THEN** system SHALL execute `orodc updateurl <URL>`
- **AND** success message SHALL be displayed with updated URL
- **AND** menu SHALL return to main menu

#### Scenario: Use default URL
- **WHEN** user presses Enter without input
- **THEN** default URL `https://${DC_ORO_NAME}.docker.local` SHALL be used
- **AND** system SHALL execute `orodc updateurl` with default URL

#### Scenario: Validate URL format
- **WHEN** user enters invalid URL (does not start with http:// or https://)
- **THEN** error message SHALL be displayed: "Invalid URL format. URL must start with http:// or https://"
- **AND** user SHALL be prompted again

### Requirement: Menu Option: Export Database

The system SHALL provide a menu option to export the database to the `var/` folder.

#### Scenario: Export database to var folder
- **WHEN** user selects option "9) Export database"
- **THEN** system SHALL check if `var/` directory exists in `$DC_ORO_APPDIR`
- **AND** if directory does not exist, it SHALL be created
- **AND** prompt SHALL be shown: "Enter filename [default: database-YYYYMMDDHHMMSS.sql.gz]:"
- **WHEN** user enters filename or presses Enter for default
- **THEN** system SHALL execute `orodc exportdb` with target path `var/<filename>`
- **AND** success message SHALL display file path and size
- **AND** menu SHALL return to main menu

#### Scenario: Export with custom filename
- **WHEN** user enters custom filename (e.g., "backup-2024.sql.gz")
- **THEN** database SHALL be exported to `var/backup-2024.sql.gz`
- **AND** file SHALL be compressed with gzip

### Requirement: Menu Option: Import Database

The system SHALL provide a menu option to import a database from the `var/` folder or file path.

#### Scenario: List available dumps in var folder
- **WHEN** user selects option "10) Import database"
- **AND** `var/` directory exists with `.sql` or `.sql.gz` files
- **THEN** numbered list of available dump files SHALL be displayed
- **AND** prompt SHALL be shown: "Select dump number or enter file path:"

#### Scenario: Import from var folder by number
- **WHEN** user enters a number corresponding to a dump file
- **THEN** corresponding file from `var/` directory SHALL be selected
- **AND** system SHALL execute `orodc importdb var/<selected-file>`
- **AND** after completion, menu SHALL return to main menu

#### Scenario: Import from file path
- **WHEN** user enters a file path (absolute or relative)
- **THEN** system SHALL validate file exists and is readable
- **WHEN** file is valid
- **THEN** system SHALL execute `orodc importdb <file-path>`
- **AND** after completion, menu SHALL return to main menu

#### Scenario: Error when no dumps found
- **WHEN** user selects option "10) Import database"
- **AND** `var/` directory is empty or does not exist
- **THEN** message SHALL be displayed: "No database dumps found in var/ folder"
- **AND** prompt SHALL allow entering file path directly

### Requirement: Menu Option: Clear Cache

The system SHALL provide a menu option to clear the application cache.

#### Scenario: Clear cache from menu
- **WHEN** user selects option "11) Clear cache"
- **THEN** system SHALL execute `orodc cache clear`
- **AND** success message SHALL be displayed: "Cache cleared successfully"
- **AND** menu SHALL return to main menu

### Requirement: Menu Option: Platform Update

The system SHALL provide a menu option to perform platform update by stopping application services and running only CLI container.

#### Scenario: Platform update stops services and runs CLI only
- **WHEN** user selects option "12) Platform update"
- **THEN** system SHALL stop all application services (FPM, Nginx, WebSocket, Consumer)
- **AND** system SHALL keep dependency services running (Database, Redis, Elasticsearch, RabbitMQ)
- **AND** system SHALL execute `docker compose run --rm cli php bin/console oro:platform:update --force`
- **AND** progress SHALL be displayed during update
- **AND** after completion, success message SHALL be displayed

#### Scenario: Platform update prompts to restart services
- **WHEN** platform update completes successfully
- **THEN** prompt SHALL be shown: "Platform update completed. Restart services? [Y/n]"
- **WHEN** user confirms with 'y' or presses Enter
- **THEN** system SHALL execute `orodc up -d` to restart services
- **WHEN** user enters 'n'
- **THEN** services SHALL remain stopped
- **AND** menu SHALL return to main menu

#### Scenario: Platform update clears cache before update
- **WHEN** platform update is executed
- **THEN** system SHALL clear cache (`rm -rf var/cache/*`) before running update command
- **AND** update command SHALL run with `--force` flag

### Requirement: Menu Option: Connect via SSH

The system SHALL provide a menu option to connect to the environment via SSH.

#### Scenario: Connect via SSH when service is running
- **WHEN** user selects option "6) Connect via SSH"
- **AND** SSH service is running
- **THEN** system SHALL execute `orodc ssh` command
- **AND** interactive SSH session SHALL be opened
- **WHEN** user exits SSH session
- **THEN** menu SHALL return to main menu

#### Scenario: Error when SSH service is not running
- **WHEN** user selects option "6) Connect via SSH"
- **AND** SSH service is not running
- **THEN** error message SHALL be displayed: "SSH service is not running. Start environment first."
- **AND** menu SHALL return to main menu

### Requirement: Menu Option: Image Build

The system SHALL provide a menu option to build application images.

#### Scenario: Build images with or without cache
- **WHEN** user selects option "14) Image build"
- **THEN** system SHALL prompt for cache usage ("Build images with cache?" default yes)
- **WHEN** user confirms, system SHALL execute `orodc image build` (with `--no-cache` when user requests full rebuild)
- **AND** after completion or cancellation, menu SHALL return to main menu

### Requirement: Menu Option: Run Doctor

The system SHALL provide a menu option to display current container status for the environment.

#### Scenario: Show container status
- **WHEN** user selects option "13) Run doctor"
- **THEN** system SHALL execute `docker compose ps` with project name
- **AND** output SHALL list container name and status columns
- **AND** when no containers are found, menu SHALL inform user to start environment
- **AND** menu SHALL return to main menu after display

### Requirement: Menu Option: Start Proxy

The system SHALL provide a menu option to start the Traefik reverse proxy.

#### Scenario: Start proxy from menu
- **WHEN** user selects option "15) Start proxy"
- **THEN** system SHALL execute `orodc proxy up -d`
- **AND** after completion, menu SHALL return to main menu

### Requirement: Menu Option: Stop Proxy

The system SHALL provide a menu option to stop the Traefik reverse proxy.

#### Scenario: Stop proxy from menu
- **WHEN** user selects option "16) Stop proxy"
- **THEN** system SHALL execute `orodc proxy down`
- **AND** after completion, menu SHALL return to main menu

### Requirement: Menu Option: Install With Demo Data

The system SHALL provide a menu option to purge and install the application with demo data.

#### Scenario: Confirm install with demo data
- **WHEN** user selects option "17) Install with demo data"
- **THEN** warning about purge SHALL be displayed
- **WHEN** user confirms
- **THEN** system SHALL run `orodc purge --yes` followed by `orodc install with demo`
- **AND** menu SHALL return to main menu after completion or cancellation

### Requirement: Menu Option: Install Without Demo Data

The system SHALL provide a menu option to purge and install the application without demo data.

#### Scenario: Confirm install without demo data
- **WHEN** user selects option "18) Install without demo data"
- **THEN** warning about purge SHALL be displayed
- **WHEN** user confirms
- **THEN** system SHALL run `orodc purge --yes` followed by `orodc install without demo`
- **AND** menu SHALL return to main menu after completion or cancellation

### Requirement: Menu Input Validation

The system SHALL validate menu input and handle invalid selections gracefully.

#### Scenario: Accept valid menu option
- **WHEN** user enters a number between 1-18
- **THEN** corresponding option SHALL be executed

#### Scenario: Handle invalid input
- **WHEN** user enters a number outside 1-18 range
- **THEN** error message SHALL be displayed: "Invalid option. Please enter a number between 1-18."
- **AND** menu SHALL be re-displayed

#### Scenario: Quit menu
- **WHEN** user enters 'q' or 'Q'
- **THEN** menu SHALL exit
- **AND** `orodc` SHALL exit with code 0

#### Scenario: Handle empty input
- **WHEN** user presses Enter without input
- **THEN** menu SHALL be re-displayed (no action taken)
