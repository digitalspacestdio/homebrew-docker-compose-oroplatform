---
name: php-docker-dev-env
description: Work with this repository's Docker-based PHP development environment, CI workflows, and troubleshooting patterns. Use when the user asks about environment setup, GitHub Actions failures, container startup issues, PHP command execution, or config and permission problems in this repository.
license: MIT
metadata:
  author: local
  scope: project
---

# PHP Docker Dev Env

Use this skill only for this repository.

## Quick Start

Before making changes:

1. Read `openspec/project.md` and `DEVELOPMENT.md`.
2. Start analysis from `bin/orodc`, then follow the routed module in `libexec/orodc/`.
3. Prefer the repository CLI for PHP commands and environment actions instead of raw `php`, `docker compose`, or ad-hoc shell flows when the task is about the managed app environment.

## Repository Rules

- Keep `bin/orodc` thin. Put business logic in `libexec/orodc/` or `libexec/orodc/lib/`.
- Fix root causes, not symptoms.
- Do not push without explicit user confirmation.
- Do not add extra refactors or unrelated cleanups.
- If changing `bin/` or `compose/`, update `Formula/docker-compose-oroplatform.rb`.
- After changing `libexec/` or `compose/`, reinstall the formula.

## Platform Defaults

- Linux and WSL2: use `DC_ORO_MODE=default`.
- macOS: use `DC_ORO_MODE=mutagen`.
- CI: keep `DC_ORO_CONFIG_DIR` inside the workspace so Docker mounts and file permissions stay writable.

## CI Troubleshooting

When GitHub Actions fail:

1. Inspect the workflow under `.github/workflows/`.
2. Check `DC_ORO_CONFIG_DIR`, runner UID/GID, workspace mounts, and ownership of generated files.
3. If the failure involves SSH keys, config files, or generated compose files, trace creation through `libexec/orodc/lib/environment.sh` and `bin/orodc`.
4. Prefer fixing path, ownership, or execution context problems in the workflow before adding fallbacks in shell code.

## Investigation Path

Use this order when debugging:

1. `bin/orodc`
2. `libexec/orodc/lib/environment.sh`
3. `libexec/orodc/lib/docker-utils.sh`
4. The specific command module in `libexec/orodc/`
5. Relevant workflow in `.github/workflows/`

## Validation

After shell changes:

1. Run `bash -n` on changed shell scripts.
2. Run `shellcheck` and fix warnings except `SC1091`.
3. If repository checks are needed, run `brew lgtm`.

For workflow-only changes:

1. Validate YAML structure.
2. Re-read the affected workflow diff and confirm variable paths, quoting, and permissions.

## Useful References

- `openspec/project.md`
- `DEVELOPMENT.md`
- `LOCAL-TESTING.md`
- `bin/orodc`
- `libexec/orodc/lib/environment.sh`
- `libexec/orodc/lib/docker-utils.sh`
