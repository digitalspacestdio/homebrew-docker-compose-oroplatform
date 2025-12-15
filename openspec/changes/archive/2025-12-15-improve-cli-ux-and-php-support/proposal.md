# Change: Improve CLI UX with Spinners and PHP 7.3 Support

## Why
OroDC command output was verbose and overwhelming for users during normal operations. Commands like `build`, `up`, `down`, and `purge` displayed extensive Docker Compose logs that made it difficult to track progress and identify issues. Additionally, the interactive configuration tool (`orodc init`) lacked input validation, didn't preserve existing configuration, and missed support for legacy PHP 7.3 projects.

## What Changes
### CLI UX Improvements
- Added spinner animations for long-running operations (`build`, `up`, `down`, `purge`, `proxy` commands)
- Implemented clean output mode that hides verbose Docker logs by default
- Added `--verbose` flag to display full logs when needed
- Enhanced error handling with automatic log display on failures
- Split `orodc up` into two visible steps: "Building services" and "Starting services"
- Improved service URL display logic with proxy detection

### Interactive Configuration
- Added input validation with retry logic for all selectors
- Implemented smart default detection from existing `.env.orodc` values
- Changed file update strategy to preserve all existing variables (non-destructive updates)
- Added confirmation prompts for destructive operations (`orodc purge`)
- Fixed version default selection when switching service types (PostgreSQL↔MySQL, Elasticsearch↔OpenSearch, Redis↔KeyDB)

### PHP/Node.js Compatibility
- Added PHP 7.3 support with Node.js 18 compatibility
- Corrected default Node.js versions for PHP 8.1-8.4
- Updated auto-detection logic for `composer.json` parsing

## Impact
### Affected Capabilities
- **cli-ux** (NEW): Command-line user experience and output formatting
- **interactive-init** (NEW): Interactive configuration tool behavior
- **php-compatibility** (NEW): PHP version support and Node.js compatibility matrix

### Affected Code
- `bin/orodc`: Core CLI script (~1000 lines added/modified)
  - Spinner functions (`show_spinner`, `run_with_spinner`)
  - Validation functions (`prompt_selector`, `prompt_port`, `confirm_yes_no`, `prompt_select`)
  - Configuration preservation logic (`update_env_var`)
  - Version detection and defaults
- `Formula/docker-compose-oroplatform.rb`: Version bumped from 0.12.27 → 0.12.37
- `README.md`: Updated documentation with new features and flags

### Breaking Changes
None - all changes are backwards compatible and enhance existing functionality.

### Version History
- v0.12.28: Initial spinners and clean output
- v0.12.29: Interactive selector validation
- v0.12.30: Sort version arrays
- v0.12.31: Read existing config values
- v0.12.32: Preserve existing variables
- v0.12.33: Fix prompt_select validation
- v0.12.34: Fix version defaults for service type switching
- v0.12.35: Non-destructive `.env.orodc` updates
- v0.12.36: PHP 7.3 support
- v0.12.37: Correct Node.js defaults for PHP 8.1-8.4

