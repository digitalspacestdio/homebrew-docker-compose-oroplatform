# codex-integration Specification

## Purpose
Defines the integration between OroDC and Codex CLI, enabling AI-assisted development with automatic context configuration.

## ADDED Requirements

### Requirement: Codex CLI Proxy Command

The system SHALL provide an `orodc codex` command that proxies to Codex CLI with automatic context configuration.

#### Scenario: Execute Codex CLI with auto-configuration
- **WHEN** user executes `orodc codex`
- **THEN** system SHALL check if `codex` CLI is installed
- **AND** if installed, SHALL execute `codex cli` with:
  - Detected or configured CMS type as context
  - OroDC documentation (README.md path or `orodc help` output) as documentation
  - System prompt instructing Codex to work only with OroDC commands
- **AND** all additional arguments SHALL be passed through to Codex CLI

#### Scenario: Error when Codex CLI not installed
- **WHEN** user executes `orodc codex`
- **AND** `codex` CLI is not found in PATH
- **THEN** system SHALL display error message indicating Codex CLI is required
- **AND** SHALL provide installation instructions or link

#### Scenario: Pass arguments to Codex CLI
- **WHEN** user executes `orodc codex [codex-args]`
- **THEN** system SHALL pass all arguments after `codex` to Codex CLI
- **AND** SHALL preserve argument order and flags

### Requirement: CMS Type Detection for Codex

The system SHALL detect CMS type (php-generic, symfony, laravel, magento, oro) for Codex context configuration.

#### Scenario: Detect Symfony project
- **WHEN** `composer.json` exists in project directory
- **AND** `require` section contains `symfony/symfony` or `symfony/framework-bundle`
- **THEN** CMS type SHALL be detected as `symfony`
- **AND** SHALL be passed to Codex CLI as context

#### Scenario: Detect Laravel project
- **WHEN** `composer.json` exists in project directory
- **AND** `require` section contains `laravel/framework`
- **THEN** CMS type SHALL be detected as `laravel`
- **AND** SHALL be passed to Codex CLI as context

#### Scenario: Detect Magento project
- **WHEN** CMS type detection identifies Magento (via existing detection logic)
- **THEN** CMS type SHALL be detected as `magento`
- **AND** SHALL be passed to Codex CLI as context

#### Scenario: Detect Oro Platform project
- **WHEN** CMS type detection identifies Oro Platform (via existing detection logic)
- **THEN** CMS type SHALL be detected as `oro`
- **AND** SHALL be passed to Codex CLI as context

#### Scenario: Default to PHP generic
- **WHEN** no CMS/framework is detected
- **THEN** CMS type SHALL default to `php-generic`
- **AND** SHALL be passed to Codex CLI as context

#### Scenario: Use configured CMS type
- **WHEN** `DC_ORO_CMS_TYPE` is set in `.env.orodc` or environment
- **THEN** system SHALL use configured value instead of auto-detection
- **AND** SHALL validate value is one of: `php-generic`, `symfony`, `laravel`, `magento`, `oro`

### Requirement: Documentation Context for Codex

The system SHALL provide OroDC documentation to Codex CLI as context.

#### Scenario: Use README.md when available
- **WHEN** `README.md` exists in project root or OroDC installation directory
- **THEN** system SHALL pass README.md file path to Codex CLI as documentation context
- **AND** Codex SHALL have access to full OroDC documentation

#### Scenario: Fallback to help output
- **WHEN** `README.md` is not available
- **THEN** system SHALL execute `orodc help` and capture output
- **AND** SHALL pass help output to Codex CLI as documentation context

#### Scenario: Minimal context fallback
- **WHEN** neither README.md nor help output is available
- **THEN** system SHALL provide minimal context about OroDC
- **AND** SHALL still execute Codex CLI (with reduced context)

### Requirement: System Prompt Configuration

The system SHALL configure Codex CLI with a system prompt that constrains the agent to work only with OroDC commands.

#### Scenario: Inject OroDC-only system prompt
- **WHEN** `orodc codex` is executed
- **THEN** system SHALL inject a system prompt that instructs Codex to:
  - Work only with OroDC commands (`orodc <command>`)
  - Understand OroDC project structure and conventions
  - Use CMS-specific patterns based on detected CMS type
  - Reference OroDC documentation when needed
- **AND** system prompt SHALL be injected via Codex CLI configuration (`-c` flag or config file)

#### Scenario: CMS-aware system prompt
- **WHEN** CMS type is detected or configured
- **THEN** system prompt SHALL mention the detected CMS type
- **AND** SHALL include CMS-specific guidance (e.g., Symfony console commands, Laravel artisan, Magento bin/magento)

### Requirement: CMS Type Configuration in Init Wizard

The system SHALL optionally allow users to configure CMS type during `orodc init`.

#### Scenario: Optional CMS type selection
- **WHEN** user runs `orodc init`
- **THEN** wizard SHALL optionally prompt for CMS type selection
- **AND** SHALL allow user to choose: php-generic, symfony, laravel, magento, oro
- **AND** SHALL allow user to skip (default to auto-detection)
- **AND** if selected, SHALL save to `.env.orodc` as `DC_ORO_CMS_TYPE`

#### Scenario: Skip CMS type configuration
- **WHEN** user runs `orodc init`
- **AND** user skips CMS type selection
- **THEN** system SHALL use auto-detection
- **AND** SHALL not save `DC_ORO_CMS_TYPE` to `.env.orodc`

### Requirement: Command Routing Integration

The system SHALL route `orodc codex` command following modular architecture patterns.

#### Scenario: Route to codex module
- **WHEN** user executes `orodc codex`
- **THEN** main router SHALL route to `libexec/orodc/codex.sh` module
- **AND** SHALL pass all arguments to the module

#### Scenario: Support interactive menu
- **WHEN** `orodc codex` is executed from interactive menu
- **AND** `DC_ORO_IS_INTERACTIVE_MENU` is set
- **THEN** command SHALL execute and return to menu after completion
- **AND** SHALL follow `execute_with_menu_return` pattern
