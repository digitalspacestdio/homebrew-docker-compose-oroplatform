# cursor-integration Specification

## Purpose
Defines the integration between OroDC and Cursor CLI, enabling AI-assisted development with automatic context configuration.

## ADDED Requirements

### Requirement: Cursor CLI Proxy Command

The system SHALL provide an `orodc cursor` command that proxies to Cursor CLI with automatic context configuration.

#### Scenario: Execute Cursor CLI with auto-configuration
- **WHEN** user executes `orodc cursor`
- **THEN** system SHALL check if `cursor` CLI is installed
- **AND** if installed, SHALL execute Cursor CLI with:
  - Detected or configured CMS type as context
  - OroDC documentation (README.md path or `orodc help` output) as documentation
  - System prompt instructing Cursor CLI to work only with OroDC commands
- **AND** all additional arguments SHALL be passed through to Cursor CLI

#### Scenario: Error when Cursor CLI not installed
- **WHEN** user executes `orodc cursor`
- **AND** `cursor` CLI is not found in PATH
- **THEN** system SHALL display error message indicating Cursor CLI is required
- **AND** SHALL provide installation instructions or link

#### Scenario: Pass arguments to Cursor CLI
- **WHEN** user executes `orodc cursor [cursor-args]`
- **THEN** system SHALL pass all arguments after `cursor` to Cursor CLI
- **AND** SHALL preserve argument order and flags

### Requirement: CMS Type Detection for Cursor

The system SHALL detect CMS type (php-generic, symfony, laravel, magento, oro) for Cursor CLI context configuration, reusing existing detection logic.

#### Scenario: Reuse existing CMS detection
- **WHEN** `orodc cursor` is executed
- **THEN** system SHALL use existing CMS type detection logic (same as codex/gemini)
- **AND** SHALL detect: php-generic, symfony, laravel, magento, oro
- **AND** SHALL pass detected CMS type to Cursor CLI as context

#### Scenario: Use configured CMS type
- **WHEN** `DC_ORO_CMS_TYPE` is set in `.env.orodc` or environment
- **THEN** system SHALL use configured value instead of auto-detection
- **AND** SHALL validate value is one of: `php-generic`, `symfony`, `laravel`, `magento`, `oro`

### Requirement: Documentation Context for Cursor

The system SHALL provide OroDC documentation to Cursor CLI as context, reusing existing documentation context generation logic.

#### Scenario: Use README.md when available
- **WHEN** `README.md` exists in project root or OroDC installation directory
- **THEN** system SHALL pass README.md file path to Cursor CLI as documentation context
- **AND** Cursor CLI SHALL have access to full OroDC documentation

#### Scenario: Fallback to help output
- **WHEN** `README.md` is not available
- **THEN** system SHALL execute `orodc help` and capture output
- **AND** SHALL pass help output to Cursor CLI as documentation context

#### Scenario: Minimal context fallback
- **WHEN** neither README.md nor help output is available
- **THEN** system SHALL provide minimal context about OroDC
- **AND** SHALL still execute Cursor CLI (with reduced context)

### Requirement: System Prompt Configuration

The system SHALL configure Cursor CLI with a system prompt that constrains the agent to work only with OroDC commands, reusing existing system prompt generation logic.

#### Scenario: Inject OroDC-only system prompt
- **WHEN** `orodc cursor` is executed
- **THEN** system SHALL inject a system prompt that instructs Cursor CLI to:
  - Work only with OroDC commands (`orodc <command>`)
  - Understand OroDC project structure and conventions
  - Use CMS-specific patterns based on detected CMS type
  - Reference OroDC documentation when needed
- **AND** system prompt SHALL be injected via Cursor CLI configuration (method TBD based on Cursor CLI API)

#### Scenario: CMS-aware system prompt
- **WHEN** CMS type is detected or configured
- **THEN** system prompt SHALL mention the detected CMS type
- **AND** SHALL include CMS-specific guidance (e.g., Symfony console commands, Laravel artisan, Magento bin/magento)

#### Scenario: Reuse system prompt content
- **WHEN** system prompt is generated
- **THEN** system SHALL reuse the same system prompt content as Codex and Gemini integrations
- **AND** SHALL ensure consistency across all AI integrations

### Requirement: Command Routing Integration

The system SHALL route `orodc cursor` command following modular architecture patterns.

#### Scenario: Route to cursor module
- **WHEN** user executes `orodc cursor`
- **THEN** main router SHALL route to `libexec/orodc/cursor.sh` module
- **AND** SHALL pass all arguments to the module

#### Scenario: Support interactive menu
- **WHEN** `orodc cursor` is executed from interactive menu
- **AND** `DC_ORO_IS_INTERACTIVE_MENU` is set
- **THEN** command SHALL execute and return to menu after completion
- **AND** SHALL follow `execute_with_menu_return` pattern
