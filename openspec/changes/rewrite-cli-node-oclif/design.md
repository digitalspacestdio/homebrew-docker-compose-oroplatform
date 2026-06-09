## Context

OroDC currently ships as a Homebrew formula with `bin/orodc` as the public entry point, Bash command modules under `libexec/orodc/`, and static Docker assets under `compose/`. The CLI is responsible for finding the project root, loading `.env` and `.env.orodc` files, resolving Homebrew and Docker paths, generating compose configuration, running Docker Compose, prompting users, displaying spinners, and delegating commands for PHP, Composer, databases, proxy, tests, image builds, diagnostics, and interactive menus.

The rewrite targets a full replacement of the Bash implementation with a TypeScript + oclif CLI. Docker Compose files, Dockerfiles, doctor YAML configs, agent docs, and other static assets remain part of the package and continue to be consumed by the CLI.

Constraints:

- The public `orodc` command surface must remain stable unless this change explicitly marks a behavior as removed.
- Configuration locations must remain compatible: project `.env.orodc`, global `~/.orodc/<project>/.env.orodc`, generated `~/.orodc/<project>/compose.yml`, and environment registry files.
- Docker Compose remains the orchestration engine; this change does not replace compose with a native Docker API.
- Homebrew remains the distribution mechanism for macOS, Linux, and WSL2 users.
- Shell scripts inside Docker images or static build contexts may remain if they are container entrypoints or image assets rather than host CLI implementation modules.

## Goals / Non-Goals

**Goals:**

- Implement `orodc` as a TypeScript + oclif CLI with typed command modules and shared libraries.
- Preserve existing public commands, aliases, flags pass-through behavior, environment variables, config precedence, and compose workflows.
- Replace shell string assembly with structured process execution wherever possible.
- Keep static compose and Docker assets installable and addressable from both a development checkout and a Homebrew installation.
- Add contract tests that make the rewrite verifiable against current behavior.
- Make future command additions follow one command-per-module conventions instead of adding logic to a monolithic router.

**Non-Goals:**

- Do not redesign Docker Compose service topology.
- Do not rename public `orodc` commands as part of the rewrite.
- Do not remove support for macOS, Linux, or WSL2.
- Do not move user configuration out of `.env.orodc` or `~/.orodc`.
- Do not replace Homebrew distribution with npm-only distribution.
- Do not document private developer-only tooling in user-facing docs.

## Decisions

### Use oclif as the command framework

Use oclif because OroDC has a large command tree with nested groups, aliases, help text, flags, and command-specific modules. oclif provides TypeScript-first command classes, generated help, structured parsing, hooks, and a project layout that maps well to `orodc database psql`, `orodc proxy up`, `orodc tests phpunit`, and top-level aliases.

Alternatives considered:

- Commander.js: simpler, but too lightweight for a full multi-command rewrite with typed command modules and framework-level conventions.
- Go + Cobra: strong binary distribution and good CLI primitives, but the selected direction is Node.js/TypeScript for faster migration and easier scripting around JSON/YAML/process orchestration.

### Keep Docker Compose as an external command

The TypeScript CLI will continue invoking `docker compose` rather than using a Docker API client. Docker Compose is already the source of truth for service assembly, profiles, health checks, logs, and user expectations.

Command execution should use `spawn`/`execa`-style argv arrays for normal execution and reserve shell execution only for cases that truly require shell semantics. Compose flags must remain pass-through compatible.

### Split shared logic into typed core modules

Create shared modules for:

- `env`: load env files, apply priority rules, normalize key values, and expose a typed runtime context.
- `paths`: resolve development checkout paths, Homebrew install paths, `compose/`, `libexec` replacement assets, and project/global config paths.
- `compose`: parse compose-left and compose-right flags, generate config, execute compose commands, and implement `up` orchestration.
- `process`: run commands, stream output, capture logs, handle exit codes, and preserve signals.
- `ui`: colors, spinners, prompts, confirmation flows, tables, and verbose/debug modes.
- `registry`: manage `~/.orodc/environments.json`.
- `cms`: detect Oro, Magento, Symfony, Laravel, WinterCMS, WordPress, Drupal, and generic PHP projects.
- `ports`: resolve the project port prefix and allocate free host ports for each service.
- `sync`: select the source-code sync mode and run appcode volume rsync and mutagen session lifecycle.

### Preserve source-code sync modes

OroDC selects a source-code sync mode through `DC_ORO_MODE`, defaulting to `mutagen` on macOS and `default` on Linux/WSL2, and also supports an `ssh` mode. The TypeScript CLI must preserve these modes and their behavior:

- `default`: bind-mount the project directory directly.
- `mutagen`: create, wait for, and terminate a mutagen sync session against the `ssh` service container, and ensure the `<project>_appcode` Docker volume exists.
- `ssh`: ensure the `<project>_appcode` volume and seed it with an initial rsync over SSH into the running `ssh` service.

This behavior is OS-sensitive and must keep the same default selection, environment variables, and idempotent session/volume management.

### Resolve dynamic host ports

OroDC derives service host ports from `DC_ORO_PORT_PREFIX` (e.g. nginx, database, search, mq, redis, mail, ssh, gotenberg, xhgui) and falls back to free-port discovery to avoid collisions. The current implementation shells out to the `orodc-find_free_port` companion binary. The rewrite must preserve the same default port mapping, per-service env overrides, and free-port fallback.

### Handle companion binaries

The formula currently installs two companion executables alongside `orodc`: `orodc-find_free_port` and `orodc-sync`. The rewrite must decide their fate explicitly:

- Reimplement free-port discovery inside the TypeScript `ports` service or keep `orodc-find_free_port` as a bundled binary invoked through the process runner.
- Keep `orodc-sync` as a bundled asset/binary if it is still required, or remove it if the new `sync` service fully replaces it.

Whatever is kept must remain installable through the formula and resolvable by the asset resolver.

### Preserve static assets as package data

The new CLI should not inline compose YAML, Dockerfiles, doctor configs, or agent docs into TypeScript. These assets remain files under predictable package paths and are copied by Homebrew during installation.

The asset resolver must support:

- source checkout execution during development;
- installed Homebrew prefix execution;
- test fixture execution.

### Use Node runtime through Homebrew first

Initial packaging should depend on a Homebrew Node.js formula and install the compiled TypeScript CLI plus package dependencies. A bundled executable can be evaluated later only if runtime dependency issues become a real user problem.

Rationale: Homebrew already manages project dependencies, Node.js is common on developer machines, and bundled Node CLIs add build and signing complexity.

### Build compatibility tests before removing Bash

Because this is a full rewrite, tests must capture current behavior before replacement. Golden tests should cover command routing, help/error output, env precedence, path resolution, command construction, and non-Docker dry-run flows. Docker integration tests should cover representative full workflows.

## Risks / Trade-offs

- Regression in shell edge cases -> add golden tests for current command behavior and preserve pass-through semantics for unknown compose/PHP/Composer arguments.
- Node runtime dependency friction -> install Node through Homebrew and keep formula tests validating `orodc --help` and a non-Docker command.
- Signal/TTY behavior changes -> centralize process execution and test interactive/non-interactive modes separately.
- Different `.env` parsing semantics -> implement parser fixtures for comments, quotes, blank values, existing `.env.orodc` files, and global/local priority.
- Hidden dependency on internal Bash module paths -> explicitly support only the public `orodc` command and mark internal module path calls as unsupported.
- Large `doctor` rewrite risk -> treat doctor as a late milestone with fixtures for generated Goss configs and service checks.
- Full rewrite increases delivery risk -> sequence implementation by command risk and keep the old implementation available on a branch/tag until the new CLI passes the full matrix.

## Migration Plan

1. Add TypeScript build/test tooling and oclif project structure without changing the public formula entry point.
2. Create behavior fixtures from current Bash commands and commit them as regression tests.
3. Implement shared core modules and low-risk commands.
4. Implement compose/project lifecycle/database/proxy/doctor/menu commands.
5. Update Homebrew formula to install the Node CLI and assets.
6. Run shellcheck only for remaining shell assets that are still part of Docker images or helper scripts.
7. Run full local and CI validation across Linux, macOS, and WSL2-representative environments.
8. Remove or archive host-side Bash implementation modules after the TypeScript CLI becomes the installed `orodc`.

Rollback strategy:

- Keep the last Bash-based release available as the previous Homebrew formula version.
- Avoid migrating user config formats in the initial rewrite so users can downgrade without config conversion.
- If the Node CLI fails in production, revert the formula entry point to the previous Bash implementation while retaining static assets.

## Open Questions

- Should generated shell completions be installed by the formula in the first release or deferred until command behavior stabilizes?
- Should the first Node release require Node.js from Homebrew, or should a bundled executable be prepared before public release?
- Which Docker integration tests are mandatory for release gating versus nightly validation?
- Should `orodc-find_free_port` and `orodc-sync` be reimplemented in TypeScript or kept as bundled binaries invoked through the process runner?
- Should the menu-driven environment switch (`DC_ORO_SELECTED_ENV_*`) and the `v`/`verbose` toggle keep their current shell-state semantics, or be redesigned for the Node CLI?
