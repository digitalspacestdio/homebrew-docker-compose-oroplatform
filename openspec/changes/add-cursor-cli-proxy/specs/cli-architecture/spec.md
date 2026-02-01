## MODIFIED Requirements

### Requirement: Single-File Command Modules
Simple commands without subcommands SHALL be implemented as single module files directly under `libexec/orodc/`.

#### Scenario: Single-file command routing
- **GIVEN** commands like `init`, `purge`, `config-refresh`, `ssh`, `install`, `cache`, `php`, `composer`, `platform-update`, `codex`, `gemini`, `cursor` exist
- **WHEN** user executes `orodc <command>`
- **THEN** main script SHALL route directly to `libexec/orodc/<command>.sh`
- **AND** no subcommand routing SHALL be required
