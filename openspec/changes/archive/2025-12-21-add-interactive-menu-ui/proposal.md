# Change: Add Interactive Menu UI to `orodc`

## Why
Currently, `orodc` requires users to know specific commands and their syntax. When run without parameters, it falls through to Docker Compose commands, which is not intuitive for new users or when managing multiple environments. Users need an interactive menu that provides easy access to common operations without memorizing command syntax.

## What Changes
- When `orodc` is run without any arguments, display an interactive menu with numbered options
- Menu options include:
  1. List all environments (from config directory)
  2. Initialize environment and determine versions (`orodc init`)
  3. Start environment in current folder (`orodc up -d`)
  4. Stop environment (`orodc down`)
  5. Delete environment (`orodc purge`)
  6. Add domains (`DC_ORO_EXTRA_HOSTS` management)
  7. Export database (to `var/` folder)
  8. Import database (from `var/` folder or file path)
  9. Configure application URL (`orodc updateurl`)
  10. Clear cache (`orodc cache clear`)
  11. Platform update (stop application, run `oro:platform:update --force` in CLI only)
  12. Connect via SSH (`orodc ssh`)
  13. Start proxy (`orodc proxy up -d`)
  14. Stop proxy (`orodc proxy down`)
  15. Run doctor for environment (future placeholder)
- Environment registry: Store environment paths in a config file (`~/.orodc/environments.json` or similar)
- Menu navigation: Use arrow keys or numbers for selection, Enter to confirm
- Context awareness: Show current environment status (running/stopped) in menu

## Impact
- Affected specs: `openspec/specs/cli-ux/spec.md` (new interactive menu requirements)
- Affected code: `bin/orodc` (add menu handler when no arguments provided)
- New files: Environment registry management functions

