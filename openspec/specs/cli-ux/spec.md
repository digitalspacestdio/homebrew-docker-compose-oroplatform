# cli-ux Specification

## Purpose
TBD - created by archiving change improve-cli-ux-and-php-support. Update Purpose after archive.
## Requirements
### Requirement: Spinner Animation for Long-Running Commands
The system SHALL display an animated spinner during long-running operations to provide visual feedback to users.

#### Scenario: Building Docker images with spinner
- **WHEN** user runs `orodc build` or `orodc up`
- **THEN** a spinner animation SHALL be displayed
- **AND** verbose Docker output SHALL be redirected to a log file
- **AND** only essential status messages SHALL be shown

#### Scenario: Starting services with two-phase feedback
- **WHEN** user runs `orodc up -d`
- **THEN** first spinner SHALL display "Building services..."
- **AND** second spinner SHALL display "Starting services..."
- **AND** application URLs SHALL be shown only after both phases complete

#### Scenario: Error handling with automatic log display
- **WHEN** a command with spinner fails
- **THEN** the spinner SHALL stop
- **AND** the full error log SHALL be automatically displayed
- **AND** the exit code SHALL be preserved

### Requirement: Verbose Mode Override
The system SHALL provide a `--verbose` flag to display full command output when debugging is needed.

#### Scenario: Verbose flag displays all output
- **WHEN** user runs `orodc build --verbose` or `orodc up --verbose`
- **THEN** no spinner SHALL be shown
- **AND** all Docker Compose output SHALL stream to terminal in real-time

#### Scenario: DEBUG environment variable enables verbose mode
- **WHEN** `DEBUG=1` environment variable is set
- **THEN** verbose mode SHALL be automatically enabled
- **AND** additional debug information SHALL be displayed

### Requirement: Clean Service URL Display
The system SHALL display service URLs in a clean, organized format after successful startup.

#### Scenario: Display localhost URLs after startup
- **WHEN** services start successfully
- **THEN** HTTP URLs SHALL be displayed (e.g., `http://localhost:30280`)
- **AND** Admin URLs SHALL be shown (e.g., `http://localhost:30280/admin`)

#### Scenario: Display proxy URLs when proxy is running
- **WHEN** `proxy` container is running
- **THEN** HTTPS custom domain URL SHALL be displayed in bold green (e.g., `https://project.docker.local`)
- **AND** localhost URLs SHALL still be shown after a blank line

#### Scenario: Warning when proxy is not running
- **WHEN** `proxy` container is not running
- **THEN** a warning message SHALL be displayed
- **AND** instructions to start proxy SHALL be provided (`orodc proxy up -d`)

### Requirement: Confirmation Prompts for Destructive Operations
The system SHALL require user confirmation before executing destructive operations.

#### Scenario: Purge requires confirmation in interactive mode
- **WHEN** user runs `orodc purge` in interactive terminal
- **THEN** a warning about data deletion SHALL be displayed
- **AND** a `[y/N]` confirmation prompt SHALL be shown
- **AND** operation SHALL proceed only if user enters 'y' or 'yes'

#### Scenario: Purge skips confirmation in non-interactive mode
- **WHEN** user runs `orodc purge` with piped input or `DC_ORO_PURGE_FORCE=1`
- **THEN** confirmation SHALL be skipped
- **AND** a warning message SHALL be displayed
- **AND** operation SHALL proceed automatically

### Requirement: Progress Feedback for All Proxy Commands
The system SHALL provide spinner feedback for proxy management commands.

#### Scenario: Starting proxy with spinner
- **WHEN** user runs `orodc proxy up -d`
- **THEN** "Starting proxy services..." spinner SHALL be displayed
- **AND** verbose output SHALL be hidden unless `--verbose` is used

#### Scenario: Stopping proxy with spinner
- **WHEN** user runs `orodc proxy down`
- **THEN** "Stopping proxy services..." spinner SHALL be displayed

#### Scenario: Purging proxy with spinner
- **WHEN** user runs `orodc proxy purge`
- **THEN** "Removing proxy services and volumes..." spinner SHALL be displayed

