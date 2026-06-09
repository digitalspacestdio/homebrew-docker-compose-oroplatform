## 1. Contract Inventory

- [ ] 1.1 Inventory all public commands, subcommands, aliases, deprecated syntax errors, smart PHP detection paths, and no-project-required commands from the current CLI.
- [ ] 1.2 Capture current help, version, unknown command, deprecated compose syntax, and common routing outputs as golden fixtures.
- [ ] 1.3 Capture environment precedence fixtures for `.env`, `.env-app`, `.env-app.local`, global `.env.orodc`, local `.env.orodc`, and old global config migration.
- [ ] 1.4 Capture command construction fixtures for compose, PHP, Composer, database, proxy, tests, image, and doctor workflows without requiring Docker execution.
- [ ] 1.5 Define the release-gating Docker integration test matrix for Linux, macOS, and WSL2-representative environments.

## 2. TypeScript CLI Foundation

- [ ] 2.1 Add TypeScript, oclif, lint, format, and test tooling for the new CLI implementation.
- [ ] 2.2 Create the oclif project layout and bootstrap entry point for the public `orodc` executable.
- [ ] 2.3 Implement shared error handling, exit-code normalization, DEBUG/verbose mode detection, and signal cleanup.
- [ ] 2.4 Implement a compatibility test harness that can run CLI commands against fixtures and compare golden output.
- [ ] 2.5 Add development checkout execution support so the CLI can resolve assets without Homebrew installation.

## 3. Shared Runtime Services

- [ ] 3.1 Implement path resolution for source checkout paths, Homebrew install paths, compose assets, doctor configs, agent docs, and generated config directories.
- [ ] 3.2 Implement environment file parsing and loading with current precedence and old global config migration behavior.
- [ ] 3.3 Implement project detection from `composer.json`, `.env.orodc`, global config directories, and empty project directories.
- [ ] 3.4 Implement CMS detection and PHP/Node/database/search compatibility helpers used by init and command routing.
- [ ] 3.5 Implement the environment registry service for `~/.orodc/environments.json`.
- [ ] 3.6 Implement UI services for colored messages, spinners, confirmations, selectors, tables, and non-interactive behavior.
- [ ] 3.7 Implement a process runner that supports argv execution, streaming mode, captured log mode, TTY mode, exit-code preservation, and signal forwarding.
- [ ] 3.8 Implement the port allocation service with prefix-derived service ports, explicit overrides, and free-port fallback (replacing or wrapping `orodc-find_free_port`).
- [ ] 3.9 Implement Xdebug mode persistence and menu-driven environment switching (`DC_ORO_SELECTED_ENV_*`) resolution.

## 4. Docker Compose Core

- [ ] 4.1 Implement Docker and Docker Compose binary discovery with validation and user-friendly errors.
- [ ] 4.2 Implement compose flag parsing for left-side flags, compose command, right-side flags/options, and service arguments.
- [ ] 4.3 Implement compose config generation into `~/.orodc/<project>/compose.yml` and registry updates after generation.
- [ ] 4.4 Implement `compose` command execution using structured argv instead of shell `eval`.
- [ ] 4.5 Implement `up` orchestration with pull, appcode volume sync, optional build, start, health-check wait, timing, and service URL display.
- [ ] 4.6 Implement top-level compose aliases: `up`, `down`, `ps`, `logs`, `start`, `stop`, and `restart`.
- [ ] 4.7 Implement deprecated compose command errors with old/new syntax examples.
- [ ] 4.8 Implement source-code sync modes: OS-based `DC_ORO_MODE` default, appcode volume management, ssh-mode rsync seeding, and mutagen sync session create/wait/terminate lifecycle.

## 5. Command Surface Rewrite

- [ ] 5.1 Implement informational commands: `help`, `man`, `version`, `status`, `env`, `list`, `conf`, `agents`, and the `v`/`verbose` toggle.
- [ ] 5.2 Implement project lifecycle commands: `init`, `install`, `purge`, `config-refresh`, `cache`, and `platform-update`.
- [ ] 5.3 Implement smart PHP routing for PHP flags, `.php` scripts, `bin/console`, `bin/magento`, and related executable paths.
- [ ] 5.4 Implement `php`, `composer`, and `exec` commands with current non-interactive and TTY behavior.
- [ ] 5.5 Implement database commands and aliases: `database mysql`, `database psql`, `database import`, `database export`, `database cli`, `database purge`, `database recreate`, the `db` group alias, `mysql`, `psql`, and `cli`.
- [ ] 5.6 Implement tests commands: `tests install`, `tests run`, `tests behat`, `tests phpunit`, and `tests shell`.
- [ ] 5.7 Implement proxy commands: `proxy up`, `proxy down`, `proxy restart`, and `proxy install-certs`.
- [ ] 5.8 Implement image commands: `image build` and `docker-build`.
- [ ] 5.9 Implement `ssh` and `search` commands.

## 6. Interactive and Diagnostic Workflows

- [ ] 6.1 Reimplement interactive menu display, no-argument behavior, non-interactive skip behavior, and menu command return flow.
- [ ] 6.2 Reimplement interactive init wizard with validation, defaults, config preservation, backups, and save confirmation.
- [ ] 6.3 Reimplement domain management and application URL configuration flows.
- [ ] 6.4 Reimplement doctor configuration discovery, Oro version detection, generated Goss config output, service checks, and result tables.
- [ ] 6.5 Add fixtures for doctor config generation and service health parsing.

## 7. Packaging and Distribution

- [ ] 7.1 Update the Homebrew formula to install the compiled Node CLI, runtime dependencies, and static assets.
- [ ] 7.2 Ensure `compose/`, Dockerfiles, doctor configs, agent docs, and required static scripts are copied to the installed asset location.
- [ ] 7.6 Decide and implement the fate of `orodc-find_free_port` and `orodc-sync` (reimplement in TypeScript or keep as bundled companion binaries) and update formula installation accordingly.
- [ ] 7.3 Add a formula smoke test for `orodc --help` or another non-Docker command.
- [ ] 7.4 Add generated completion support or explicitly defer completions with a documented follow-up task.
- [ ] 7.5 Remove host-side Bash module installation once the TypeScript CLI fully replaces it.

## 8. Validation

- [ ] 8.1 Run unit tests for environment loading, path resolution, command construction, UI modes, process runner behavior, and registry management.
- [ ] 8.2 Run golden output tests for command help, errors, aliases, and smart routing.
- [ ] 8.3 Run Docker integration tests for init, config generation, up, ps, logs, down, database access, proxy, and image build dry-run or fixture coverage.
- [ ] 8.8 Add tests for port allocation (prefix derivation, overrides, free-port fallback) and sync-mode selection/lifecycle (default/mutagen/ssh) without requiring a running Docker daemon where possible.
- [ ] 8.4 Verify Homebrew install/reinstall behavior on a development tap checkout.
- [ ] 8.5 Run shellcheck and bash syntax checks for remaining shell assets that still execute as Docker entrypoints or static helper scripts.
- [ ] 8.6 Update developer documentation to explain the TypeScript CLI architecture and new contribution workflow.
- [ ] 8.7 Run the repository-required verification command before requesting review.
