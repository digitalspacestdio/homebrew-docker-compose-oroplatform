## 1. Contract Inventory and Golden Fixtures

- [ ] 1.1 Build a routing inventory table from `bin/orodc` and `libexec/orodc/`: every public command, subcommand, alias, deprecated compose command, no-project-required command, and the smart PHP detection paths (PHP flags, `.php` scripts, `bin/console`, `bin/magento`).
- [ ] 1.2 Inventory the fuzzy/pattern-matched command spellings (`importdb`/`dbimport`/`databaseimport`, `exportdb`/`dbexport`/`dump database`, `platformupdate`/`updateplatform`, `cache:*`, "set/update url", "composer install" phrases) and record which behavior each pattern routes to.
- [ ] 1.3 Capture golden fixtures for `help`, `man`, `version`, unknown command errors, unknown subcommand errors, and deprecated compose syntax errors (old/new syntax examples, exit code 1).
- [ ] 1.4 Capture environment precedence fixtures: `.env`, `.env-app`, `.env-app.local`, global `~/.orodc/<project>/.env.orodc`, local `.env.orodc`, override ordering, and old `~/.orodc/<project>.env.orodc` file migration.
- [ ] 1.5 Capture DSN parsing fixtures from `parse_dsn_uri` for database, search, message queue, and Redis URIs, including edge cases (missing port, encoded credentials, schema variants).
- [ ] 1.6 Capture command construction fixtures (expected argv arrays) for compose, PHP, Composer, exec, database, proxy, tests, image, and ssh workflows without requiring Docker execution.
- [ ] 1.7 Capture port allocation fixtures: prefix-derived map for nginx/database/search/mq/redis/mail/ssh/gotenberg/xhgui, explicit `DC_ORO_PORT_*` overrides, and Docker-aware free-port fallback behavior of `orodc-find_free_port`.
- [ ] 1.8 Capture compose file stack fixtures: which `-f` files are selected per sync mode (`default`/`mutagen`/`ssh`), database schema (pgsql/mysql), Oro vs non-Oro project, and CMS cron file (oro/magento ofelia).
- [ ] 1.9 Define the release-gating Docker integration test matrix (Linux, macOS, WSL2-representative) and mark which scenarios from `test-oro-installations-containerized.yml` gate the release versus run nightly.

## 2. TypeScript CLI Foundation

- [ ] 2.1 Add the Node.js package scaffold: TypeScript, oclif, ESLint/Prettier, and a test runner with coverage; add `package.json` scripts for build, lint, test, and dev execution.
- [ ] 2.2 Create the oclif project layout (`src/commands`, `src/services`, `src/hooks`) and a bootstrap `bin` entry point for the public `orodc` executable.
- [ ] 2.3 Implement shared error types, exit-code normalization, `DEBUG`/verbose mode detection, and signal cleanup in a top-level error handler.
- [ ] 2.4 Implement a pre-parse router hook for behaviors oclif cannot express natively: smart PHP detection, fuzzy command patterns, deprecated compose command errors, and no-args menu dispatch.
- [ ] 2.5 Implement the compatibility test harness that runs CLI commands against fixture projects and compares output to the golden fixtures from section 1.
- [ ] 2.6 Add development checkout execution support (run from repo without Homebrew install) with asset resolution against the checkout.

## 3. Shared Runtime Services

- [ ] 3.1 Implement the `paths` service: source checkout paths, Homebrew prefix resolution, `compose/` assets, doctor configs, agent docs, project config dir `~/.orodc/<project>/`, and searched-paths error reporting for missing assets.
- [ ] 3.2 Implement the `env` file parser (comments, quotes, blank values, export prefixes) with fixtures matching current `load_env_safe` semantics.
- [ ] 3.3 Implement environment loading with current precedence (`.env`, `.env-app`, `.env-app.local`, global then local `.env.orodc`) and old global config file-to-directory migration.
- [ ] 3.4 Implement the DSN/URI parser for database, search, MQ, and Redis URLs and expose normalized `DC_ORO_DATABASE_*`/`DC_ORO_*_URI` values to compose generation.
- [ ] 3.5 Implement project detection: `composer.json`, `.env.orodc`, global config dirs, empty-directory handling, and `check_in_project` gating for project-required commands.
- [ ] 3.6 Implement CMS/application detection (Oro, Marello, Magento, Symfony, Laravel, WinterCMS, WordPress, Drupal, generic PHP) plus PHP version detection from `composer.json` and compatible Node/database/search version helpers.
- [ ] 3.7 Implement the environment registry service for `~/.orodc/environments.json`: register, unregister, status, scan-and-register, stale-entry cleanup, real-path resolution, and last-used environment lookup.
- [ ] 3.8 Implement the `ui` service: colored messages, headers, spinners with progress and timing, confirmation prompts, selectors, port prompts, tables, and non-interactive/no-TTY degradation.
- [ ] 3.9 Implement the `process` runner: argv execution, streaming mode, captured-log mode with failure log display, TTY passthrough, exit-code preservation, and signal forwarding.
- [ ] 3.10 Implement binary resolution (`resolve_bin` equivalent) for docker, docker compose, brew, mutagen, rsync, jq-replacement needs, and mkcert, with user-friendly install hints on missing binaries.
- [ ] 3.11 Implement the `ports` service: prefix-derived service ports, explicit `DC_ORO_PORT_*` overrides, and Docker-aware free-port fallback (inspecting existing container bindings), replacing `orodc-find_free_port`.
- [ ] 3.12 Implement Xdebug mode persistence (`XDEBUG_MODE*` save/load) and menu-driven environment switching resolution from `DC_ORO_SELECTED_ENV_NAME`/`_PATH`/`_CONFIG`.
- [ ] 3.13 Implement `COMPOSER_AUTH` forwarding: derive from `DC_ORO_COMPOSER_AUTH`, `COMPOSER_AUTH`, or `~/.composer/auth.json`, compact to single-line JSON, and expose for container and SSH execution.
- [ ] 3.14 Implement compose profiles caching (`save_profiles`/`load_cached_profiles` equivalents) and project certificate setup (mkcert-based `setup_project_certificates`).

## 4. Docker Compose Core

- [ ] 4.1 Implement Docker and Docker Compose binary discovery and validation with user-friendly errors, plus dynamic discovery of supported compose subcommands for pass-through routing.
- [ ] 4.2 Implement compose flag parsing: left-side flags/options, compose command, right-side flags/options, and service arguments with preserved ordering (`parse_compose_flags` equivalent).
- [ ] 4.3 Implement compose file stack selection: base file, `docker-compose-default.yml` in default mode, pgsql/mysql file by schema (including persisted-schema detection from existing config dir files), `docker-compose-oro.yml` for Oro projects, and CMS cron/ofelia files.
- [ ] 4.4 Implement compose config generation into `~/.orodc/<project>/compose.yml`: copy/render compose assets into the config dir, generate the `ssh_id_ed25519` key when missing, resolve ports, build Traefik rules and extra hosts, and update the registry after generation.
- [ ] 4.5 Implement `compose` command execution using structured argv (no shell `eval`) with config refresh-if-needed before execution.
- [ ] 4.6 Implement `up` orchestration: image pull, appcode volume sync, optional build, start, health-check wait, timing persistence with previous-run comparison, and service URL display.
- [ ] 4.7 Implement top-level compose aliases `up`, `down`, `ps`, `logs`, `start`, `stop`, `restart` with pass-through arguments identical to `orodc compose <cmd>`.
- [ ] 4.8 Implement deprecated compose command errors (`build`, `config`, `cp`, `create`, `events`, `images`, `kill`, `pull`, `push`, `rm`, `run`, `stats`, `watch`) with old/new syntax examples and exit code 1.
- [ ] 4.9 Implement sync mode selection: `DC_ORO_MODE` with OS-based default (`mutagen` on macOS, `default` on Linux/WSL2) including WSL2 detection.
- [ ] 4.10 Implement appcode volume management and ssh-mode seeding: ensure `<project>_appcode` volume, start the `ssh` service when needed, and rsync the source excluding `var/cache`, `vendor`, `node_modules`.
- [ ] 4.11 Implement the mutagen session lifecycle: create against the `ssh` service if absent, wait for watching state, avoid duplicate sessions, and terminate on down/purge.

## 5. Command Surface Rewrite

- [ ] 5.1 Implement informational commands `help`, `man`, and `version` (formula/package version metadata, doc asset fallback).
- [ ] 5.2 Implement `status`, `env`, `list`, `conf`, and `agents` commands against the shared registry, environment, and asset services.
- [ ] 5.3 Implement the `v`/`verbose` toggle with persisted state, immediate exit, and no project initialization.
- [ ] 5.4 Implement smart PHP routing: implicit PHP for bare flags (`orodc -v`, `orodc --version`, `orodc -r <code>`), `.php` script paths, `bin/console`, `bin/magento`, and related executable paths, including PHP logging setup.
- [ ] 5.5 Implement explicit `php`, `composer`, and `exec` commands with current interactive TTY and non-interactive behavior.
- [ ] 5.6 Implement direct database client routing: `mysql`, `psql`, and `database-cli` (default to bash) via `docker compose run` with credential env injection.
- [ ] 5.7 Implement the `database` group and `db` alias: `mysql`, `psql`, `cli`, `purge`, `recreate`, with unknown-subcommand errors.
- [ ] 5.8 Implement `database import` with its current format and source handling (file formats, archive handling, URL/stdin sources as supported today) and progress feedback; port the behavior of the 600-line Bash implementation incrementally with fixtures.
- [ ] 5.9 Implement `database export` and the interactive export/import flows used by the menu (dump listing, naming, confirmation).
- [ ] 5.10 Implement fuzzy database/platform command patterns from task 1.2 routing to import/export/platform-update/cache behaviors.
- [ ] 5.11 Implement project lifecycle commands `install`, `purge` (containers, volumes, images, registry cleanup), and `config-refresh`.
- [ ] 5.12 Implement `cache` and `platform-update` commands including `cache:*` console pass-through.
- [ ] 5.13 Implement the `tests` group: `install`, `run`, `behat`, `phpunit`, `shell`, with the test database environment and `docker-compose-test.yml` stack.
- [ ] 5.14 Implement the `proxy` group: `up`, `down`, `restart`, `install-certs`, using `docker-compose-proxy.yml` and certificate setup.
- [ ] 5.15 Implement `image build` and `docker-build` commands with current build-argument and tagging behavior.
- [ ] 5.16 Implement the `ssh` command: SSH port discovery from the running `ssh` service, `ssh_id_ed25519` identity, `SendEnv COMPOSER_AUTH`, host key options, and argument pass-through.
- [ ] 5.17 Implement the `search` command.
- [ ] 5.18 Implement the `init` command and interactive wizard: validation, defaults, CMS-aware suggestions, config preservation, backups, and save confirmation.

## 6. Interactive and Diagnostic Workflows

- [ ] 6.1 Implement no-args dispatch: interactive menu in a TTY, last-used environment switching when outside a project, `DC_ORO_NO_MENU` suppression, and non-interactive skip behavior.
- [ ] 6.2 Implement the interactive menu: environment list with status, command actions, menu-return flow after command completion, and environment switching via `DC_ORO_SELECTED_ENV_*`.
- [ ] 6.3 Implement domain management and application URL configuration flows (Traefik rule rebuild, extra hosts, config persistence).
- [ ] 6.4 Implement doctor configuration discovery, Oro version detection, and generated Goss config output with fixtures for generated configs.
- [ ] 6.5 Implement doctor service checks and result tables, with fixtures for service health parsing.

## 7. Packaging and Distribution

- [ ] 7.1 Update the Homebrew formula to build/install the compiled Node CLI with a Homebrew Node.js dependency, keeping `orodc` as the installed entry point.
- [ ] 7.2 Ensure `compose/`, Dockerfiles, doctor configs, agent docs, and required static scripts are installed to the shared asset location resolvable by the `paths` service.
- [ ] 7.3 Remove companion binaries: replace `orodc-find_free_port` with the TypeScript `ports` service, delete the unused vendored osync (`bin/orodc-sync`), and drop both from formula installation.
- [ ] 7.4 Add a formula smoke test for `orodc --help` (or another non-Docker command) and verify it passes via `brew test`.
- [ ] 7.5 Add generated shell completion support or explicitly defer completions with a documented follow-up task.
- [ ] 7.6 Remove host-side Bash module installation (`libexec/orodc/`, Bash `bin/orodc`) once the TypeScript CLI fully replaces it, keeping container-side scripts and image assets.

## 8. Validation

- [ ] 8.1 Run unit tests for env parsing/precedence, DSN parsing, path resolution, CMS detection, registry management, ports, profiles cache, and `COMPOSER_AUTH` handling.
- [ ] 8.2 Run unit tests for process runner behavior: exit codes, signal forwarding, captured-log failure output, and TTY/non-TTY modes.
- [ ] 8.3 Run golden output tests for help/version/errors, deprecated syntax, aliases, fuzzy patterns, and smart PHP routing against section 1 fixtures.
- [ ] 8.4 Run command construction tests verifying generated argv arrays for compose, PHP, Composer, database, proxy, tests, image, and ssh workflows without a Docker daemon.
- [ ] 8.5 Run sync-mode tests: OS default selection (macOS/Linux/WSL2), appcode volume idempotency, mutagen session lifecycle, and ssh-mode rsync seeding (mocked where Docker is unavailable).
- [ ] 8.6 Run Docker integration tests for init, config generation, up, ps, logs, down, database import/export, proxy, and image build per the release-gating matrix from task 1.9.
- [ ] 8.7 Verify Homebrew install/reinstall/upgrade from a development tap checkout, including config compatibility for an environment created by the Bash CLI.
- [ ] 8.8 Run shellcheck/bash syntax checks for remaining shell assets that still execute as Docker entrypoints or static helpers.
- [ ] 8.9 Update CI: add Node build/lint/test workflow and adjust `test-oro-installations-containerized.yml` to exercise the new CLI.
- [ ] 8.12 Add a CI job that validates Homebrew installation on Linux and macOS: `brew install` from the tap checkout, `brew test`, and a non-Docker `orodc` command, gating every change to the formula or CLI.
- [ ] 8.10 Update developer documentation for the TypeScript architecture, dev-checkout workflow, and contribution conventions.
- [ ] 8.11 Run the repository-required verification command before requesting review.
