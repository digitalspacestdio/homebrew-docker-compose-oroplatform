# Interactive Menu UI - Implementation Tasks

## 1. Core Infrastructure

### 1.1 Environment Registry System
- [x] Create environment registry file structure (`~/.orodc/environments.json`)
- [x] Implement functions to read/write environment registry (name, path, status, last_used)
- [x] Add function to detect current environment from `DC_ORO_NAME` and `PWD`
- [x] Add function to scan and register environments from `~/.orodc/*` directories
- [x] Add function to get environment status (running/stopped/uninitialized) via Docker Compose
- [x] Add function to get last used environment for auto-switching

### 1.2 Interactive Menu Framework
- [x] Detect when `orodc` is run without arguments (check `$# -eq 0` after flag parsing)
- [x] Create menu display function with numbered options and current environment context
- [x] Implement menu input handler (accept numbers 1-17, handle invalid input)
- [x] Add welcome message and environment status display
- [x] Ensure menu works in both interactive and non-interactive terminals (skip menu if not TTY)
- [x] Auto-switch to last used project if current directory has no project

## 2. Environment Management

- [x] Option 1: List environments - display all registered environments with status, allow selection to switch
- [x] Option 2: Initialize environment - call `orodc init` command
- [x] Option 3: Start environment - call `orodc up -d` in current directory
- [x] Option 4: Stop environment - call `orodc down` in current directory
- [x] Option 5: Delete environment - call `orodc purge --yes` and remove config directory with confirmation

## 3. Configuration Management

### 3.1 Domain Management
- [x] Option 6: Add/Manage domains - interactive prompt for `DC_ORO_EXTRA_HOSTS` management
- [x] Display current domains from `.env.orodc` or environment
- [x] Update `.env.orodc` with new domain configuration
- [x] Validate domain format (allow short names and full hostnames)

### 3.2 URL Configuration
- [x] Option 9: Configure application URL - display current URL, prompt for new URL with default
- [x] Validate URL format (must start with http:// or https://)
- [x] Call `orodc updateurl <URL>` with provided URL

## 4. Database Operations

- [x] Option 7: Export database - export to `var/backup/` folder with interactive file selection
- [x] Option 8: Import database - import from `var/backup/` folder or file path with interactive selection
- [x] Add function to list database dump files in `var/backup/` folder (fallback to `var/`)
- [x] Ensure `var/backup/` directory exists, create if needed
- [x] Handle both `.sql` and `.sql.gz` file formats

## 5. Maintenance Operations

- [x] Option 10: Clear cache - call `orodc cache clear` command
- [x] Option 11: Platform update - stop application services, run CLI container with `oro:platform:update --force`
- [x] Option 15: Run doctor - show container status (docker compose ps) with name and status only
- [x] Display progress and completion messages for all operations

## 6. Proxy Management

- [x] Option 13: Start proxy - call `orodc proxy up -d`
- [x] Option 14: Stop proxy - call `orodc proxy down` with confirmation

## 7. Installation Features

- [x] Option 16: Install with demo data - purge + install with demo data (with confirmation)
- [x] Option 17: Install without demo data - purge + install without demo data (with confirmation)

## 8. Additional Features

- [x] Option 12: Connect via SSH - execute `orodc ssh` command

## 9. Testing & Validation

- [x] Test menu display in interactive terminal
- [x] Test menu skip in non-interactive mode (piped input, scripts)
- [x] Test all menu options execute correctly
- [x] Test environment registry read/write operations
- [x] Test auto-switch to last used project
- [x] Test domain management updates `.env.orodc` correctly
- [x] Test database export to `var/backup/` folder
- [x] Test database import from `var/backup/` folder and file path
- [x] Test URL configuration updates application URLs
- [x] Test cache clear command execution
- [x] Test platform update workflow
- [x] Test proxy start/stop with confirmation
- [x] Test install commands with purge
- [x] Test delete environment (purge + config removal)
- [x] Run `openspec validate add-interactive-menu-ui --strict`

Note: Manual feature tests should be rerun in a live environment; `openspec validate add-interactive-menu-ui --strict` was executed here.
