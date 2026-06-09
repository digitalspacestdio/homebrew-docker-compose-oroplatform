## ADDED Requirements

### Requirement: TypeScript oclif CLI Runtime
The system SHALL implement the public `orodc` CLI as a TypeScript application using oclif command modules.

#### Scenario: Execute compiled CLI entry point
- **WHEN** user runs `orodc --help` after installation
- **THEN** the installed command SHALL execute the compiled TypeScript CLI
- **AND** help output SHALL be displayed without requiring Bash command modules under `libexec/orodc`

#### Scenario: Support development checkout execution
- **WHEN** a maintainer runs the CLI from a source checkout
- **THEN** the CLI SHALL resolve project assets from the checkout path
- **AND** command behavior SHALL match the installed Homebrew package for the same inputs

#### Scenario: Provide command classes for public commands
- **WHEN** a public command exists in the supported command surface
- **THEN** the command SHALL be implemented as an oclif command class or explicit alias route
- **AND** command-specific logic SHALL NOT be added to a monolithic dispatcher

### Requirement: Public Command Surface Compatibility
The system SHALL preserve the existing public `orodc` command surface during the rewrite.

#### Scenario: Preserve top-level compose aliases
- **WHEN** user runs `orodc up`, `orodc down`, `orodc ps`, `orodc logs`, `orodc start`, `orodc stop`, or `orodc restart`
- **THEN** the CLI SHALL route to the same behavior as the corresponding compose operation
- **AND** remaining arguments SHALL be passed through unchanged

#### Scenario: Preserve command groups
- **WHEN** user runs `orodc database <subcommand>`, `orodc tests <subcommand>`, `orodc proxy <subcommand>`, or `orodc image <subcommand>`
- **THEN** the CLI SHALL route to the matching command group implementation
- **AND** unknown subcommands SHALL produce a helpful error with exit code 1

#### Scenario: Preserve database aliases
- **WHEN** user runs `orodc mysql`, `orodc psql`, or `orodc cli`
- **THEN** the CLI SHALL execute behavior equivalent to `orodc database mysql`, `orodc database psql`, or `orodc database cli`

#### Scenario: Preserve smart PHP command detection
- **WHEN** user runs `orodc --version`, `orodc -r <code>`, `orodc script.php`, `orodc bin/console <args>`, or `orodc bin/magento <args>`
- **THEN** the CLI SHALL route the command to the configured CLI container using the same PHP command detection rules as the current implementation

#### Scenario: Preserve database group alias
- **WHEN** user runs `orodc db <subcommand>`
- **THEN** the CLI SHALL route to the same behavior as `orodc database <subcommand>`

#### Scenario: Preserve verbose toggle command
- **WHEN** user runs `orodc v` or `orodc verbose`
- **THEN** the CLI SHALL toggle verbose mode and report the new state
- **AND** the command SHALL exit immediately without initializing project context

#### Scenario: Preserve menu environment switching
- **WHEN** the interactive menu selects a different environment and re-invokes the CLI with `DC_ORO_SELECTED_ENV_NAME`, `DC_ORO_SELECTED_ENV_PATH`, and `DC_ORO_SELECTED_ENV_CONFIG`
- **THEN** the CLI SHALL resolve the project name, app directory, and config directory from those values when the current directory matches the selected path

### Requirement: Source Code Synchronization Modes
The system SHALL preserve the existing source-code sync modes and their default selection.

#### Scenario: Select default sync mode by OS
- **WHEN** `DC_ORO_MODE` is not set
- **THEN** the CLI SHALL default to `mutagen` on macOS
- **AND** the CLI SHALL default to `default` on Linux and WSL2

#### Scenario: Manage mutagen sync session lifecycle
- **WHEN** `DC_ORO_MODE` is `mutagen` and the project is valid
- **THEN** the CLI SHALL ensure the `<project>_appcode` Docker volume exists
- **AND** create the mutagen sync session against the running `ssh` service if it does not already exist
- **AND** wait until the session reaches a watching state before continuing
- **AND** avoid creating duplicate sessions when one already exists

#### Scenario: Seed appcode volume in ssh mode
- **WHEN** `DC_ORO_MODE` is `ssh`
- **THEN** the CLI SHALL ensure the `<project>_appcode` Docker volume exists
- **AND** perform an initial rsync of the project source into the running `ssh` service, excluding `var/cache`, `vendor`, and `node_modules`

#### Scenario: Use bind mount in default mode
- **WHEN** `DC_ORO_MODE` is `default`
- **THEN** the CLI SHALL not create a mutagen session or appcode rsync sync
- **AND** the project directory SHALL be mounted directly

### Requirement: Dynamic Host Port Allocation
The system SHALL resolve host ports for each service using the project port prefix with free-port fallback.

#### Scenario: Derive ports from prefix
- **WHEN** service ports are not explicitly overridden
- **THEN** the CLI SHALL derive nginx, database, search, message queue, redis, mail, ssh, gotenberg, and profiler ports from `DC_ORO_PORT_PREFIX`

#### Scenario: Respect explicit port overrides
- **WHEN** a per-service port variable such as `DC_ORO_PORT_NGINX` is set
- **THEN** the CLI SHALL use the explicit value instead of the prefix-derived value

#### Scenario: Fall back to a free port on collision
- **WHEN** a derived or requested host port is unavailable
- **THEN** the CLI SHALL allocate an available free port for that service
- **AND** expose the resolved ports for compose generation

### Requirement: Environment Loading Compatibility
The system SHALL load project and OroDC configuration files with the same precedence as the current CLI.

#### Scenario: Load project environment files
- **WHEN** a project contains `.env`, `.env-app`, and `.env-app.local`
- **THEN** the CLI SHALL load these files before OroDC-specific config
- **AND** exported database, search, queue, and Redis URLs SHALL be available to later compose generation

#### Scenario: Apply global then local OroDC config
- **WHEN** both `~/.orodc/<project>/.env.orodc` and `<project>/.env.orodc` exist
- **THEN** the CLI SHALL load the global config first
- **AND** the local project config SHALL override matching values from the global config

#### Scenario: Preserve config file locations
- **WHEN** the CLI reads or writes OroDC-managed configuration
- **THEN** project configuration SHALL remain in `.env.orodc`
- **AND** global project configuration SHALL remain in `~/.orodc/<project>/.env.orodc`
- **AND** generated compose output SHALL remain in `~/.orodc/<project>/compose.yml`

#### Scenario: Migrate old global config location
- **WHEN** `~/.orodc/<project>.env.orodc` exists and `~/.orodc/<project>/.env.orodc` does not exist
- **THEN** the CLI SHALL migrate the old file to the directory-based location
- **AND** subsequent loads SHALL use `~/.orodc/<project>/.env.orodc`

### Requirement: Asset Resolution
The system SHALL resolve static OroDC assets consistently in development and installed environments.

#### Scenario: Resolve compose assets from Homebrew install
- **WHEN** the CLI is installed through Homebrew
- **THEN** compose YAML files, Dockerfiles, doctor configs, agent docs, and static scripts SHALL be resolved from the installed package asset directory

#### Scenario: Resolve compose assets from source checkout
- **WHEN** the CLI is executed from a repository checkout
- **THEN** assets SHALL be resolved from the checkout `compose/` and related project directories

#### Scenario: Error on missing required asset
- **WHEN** a required asset file cannot be found
- **THEN** the CLI SHALL display the searched paths
- **AND** exit with a non-zero status code
- **AND** avoid generating partial configuration from missing assets

### Requirement: Structured Process Execution
The system SHALL execute external commands through a shared process runner that preserves exit codes, TTY behavior, and output mode.

#### Scenario: Stream interactive command output
- **WHEN** a command requires an interactive terminal
- **THEN** the process runner SHALL attach stdio to the current terminal
- **AND** user input SHALL reach the child process

#### Scenario: Capture output for spinner commands
- **WHEN** a long-running command is executed in normal mode with spinner feedback
- **THEN** the process runner SHALL capture command output to a log file
- **AND** display concise progress output
- **AND** show captured error output when the command fails

#### Scenario: Preserve child exit code
- **WHEN** an external command exits with a non-zero code
- **THEN** `orodc` SHALL exit with the same code unless a command-specific compatibility rule explicitly handles that code

#### Scenario: Propagate termination signals
- **WHEN** user sends an interrupt or termination signal to `orodc`
- **THEN** the CLI SHALL forward the signal to the active child process
- **AND** clean up any spinner or temporary terminal state

### Requirement: Docker Compose Command Construction
The system SHALL construct Docker Compose invocations from parsed arguments without unsafe shell string evaluation.

#### Scenario: Pass through compose flags
- **WHEN** user runs `orodc compose <command> <flags> <services>`
- **THEN** the CLI SHALL pass supported left-side and right-side Docker Compose flags to `docker compose`
- **AND** service names and remaining arguments SHALL preserve ordering

#### Scenario: Generate compose config before compose commands
- **WHEN** a command requires generated compose configuration
- **THEN** the CLI SHALL generate or refresh `compose.yml` before executing Docker Compose
- **AND** the environment registry SHALL be updated after successful generation

#### Scenario: Avoid shell eval for normal commands
- **WHEN** the CLI executes Docker, Docker Compose, rsync, mutagen, Homebrew, or PHP-related external commands
- **THEN** the command SHALL be invoked with an argument array
- **AND** shell execution SHALL be used only for documented cases that require shell semantics

### Requirement: Homebrew Packaging for Node CLI
The system SHALL install the rewritten CLI and required assets through the Homebrew formula.

#### Scenario: Install Node CLI through formula
- **WHEN** user installs the formula
- **THEN** Homebrew SHALL install the compiled CLI entry point
- **AND** `orodc` SHALL be available on PATH
- **AND** required runtime dependencies SHALL be installed or bundled

#### Scenario: Formula includes static assets
- **WHEN** the formula installs OroDC
- **THEN** `compose/` assets and other runtime data files SHALL be copied to the installed package location
- **AND** the CLI SHALL locate those assets without relying on the source tap checkout

#### Scenario: Handle companion binaries
- **WHEN** the formula installs OroDC
- **THEN** free-port discovery and source-sync helpers SHALL be available either as bundled companion binaries or as reimplemented TypeScript services
- **AND** any retained companion binary SHALL be resolvable by the asset resolver and invoked through the shared process runner

#### Scenario: Formula smoke test
- **WHEN** Homebrew runs the formula test
- **THEN** the test SHALL execute a non-Docker command such as `orodc --help`
- **AND** the command SHALL complete successfully

### Requirement: Regression Test Contract
The system SHALL include tests that verify the rewritten CLI preserves current public behavior.

#### Scenario: Golden output tests
- **WHEN** tests run for help, version, routing errors, deprecated syntax errors, and common aliases
- **THEN** the rewritten CLI output SHALL match approved golden fixtures or documented intentional changes

#### Scenario: Environment fixture tests
- **WHEN** tests run against fixture projects with `.env`, `.env-app`, `.env-app.local`, global `.env.orodc`, and local `.env.orodc`
- **THEN** the computed runtime environment SHALL match expected precedence and normalized values

#### Scenario: Command construction tests
- **WHEN** tests run for compose, PHP, Composer, database, proxy, image, and tests commands
- **THEN** generated external command argv arrays SHALL match expected commands
- **AND** no Docker daemon SHALL be required for these unit tests

#### Scenario: Docker integration tests
- **WHEN** integration tests run in an environment with Docker available
- **THEN** representative `init`, `config`, `up`, `ps`, `down`, database, and proxy workflows SHALL be validated against real Docker Compose execution
