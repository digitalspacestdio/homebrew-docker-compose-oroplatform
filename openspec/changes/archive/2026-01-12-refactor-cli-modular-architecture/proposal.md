# Change: Document CLI Modular Architecture Decomposition

## Why
The OroDC CLI application has been undergoing decomposition from a monolithic `bin/orodc` script into a modular architecture with separate command modules. Database commands have been successfully extracted into `libexec/orodc/database/*.sh` modules. This change documents the current decomposition state, establishes the modular architecture pattern, and identifies remaining work.

## Current State

### Completed Decomposition
- **Database Commands**: Successfully extracted into `libexec/orodc/database/`:
  - `mysql.sh` - MySQL client access
  - `psql.sh` - PostgreSQL client access
  - `import.sh` - Database import operations
  - `export.sh` - Database export operations
  - `cli.sh` - CLI container access

### Existing Modular Structure
The following command groups and modules already exist:
- **Compose Commands**: `libexec/orodc/compose.sh` (Docker Compose operations)
- **Tests Commands**: `libexec/orodc/tests/*.sh` (install, run, behat, phpunit, shell)
- **Proxy Commands**: `libexec/orodc/proxy/*.sh` (up, down, install-certs)
- **Image Commands**: `libexec/orodc/image/build.sh`
- **Single-File Commands**: `init.sh`, `purge.sh`, `config-refresh.sh`, `ssh.sh`, `install.sh`, `cache.sh`, `php.sh`, `composer.sh`, `platform-update.sh`, `menu.sh`

### Main Script Current State
The main `bin/orodc` script (357 lines) currently contains:
- Path resolution and library sourcing (lines 8-23)
- Version command handling (lines 25-54)
- Help/man command handling (lines 56-110)
- Environment initialization logic (lines 112-129)
- Command routing case statement (lines 136-357)
  - Routes to modules via `exec "${LIBEXEC_DIR}/<module>.sh"`
  - Handles command groups (database, tests, proxy, image)
  - Handles single-file commands
  - Provides command aliases
  - Shows error messages for deprecated/unknown commands

## What Changes
- Document the modular CLI architecture pattern established by database command decomposition
- Specify the command routing mechanism in the main `bin/orodc` script
- Define module structure and conventions for future decomposition
- Document current decomposition status (completed: database commands)
- Establish architectural patterns for consistent module development

## Remaining Work (Future Decomposition Opportunities)

### Potential Further Decomposition
While the main script is now primarily a router, the following could be considered for future decomposition if needed:

1. **Version Command**: Could be extracted to `libexec/orodc/version.sh` if it grows in complexity
2. **Help Command**: Could be extracted to `libexec/orodc/help.sh` if help generation becomes more sophisticated
3. **Command Routing Logic**: The case statement could potentially be externalized to a routing configuration file if it becomes unwieldy

**Note**: Current main script size (357 lines) is reasonable for a router. Further decomposition should only be considered if:
- Individual command handlers exceed ~100 lines
- Routing logic becomes complex enough to warrant externalization
- New requirements demand more sophisticated command discovery

## Impact
- Affected specs: New `openspec/specs/cli-architecture/spec.md` capability
- Affected code: Documentation only (no code changes)
- Establishes foundation for future decomposition work
- Documents architectural decisions for maintainability
