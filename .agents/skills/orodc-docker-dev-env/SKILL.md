---
name: orodc-docker-dev-env
description: Manage the local PHP Docker dev environment (Oro, Magento, Symfony, Laravel, generic PHP) in this repository via `orodc`. Use when starting/stopping services, running PHP/Composer/`bin/console`/`bin/magento` commands, accessing the database, installing or setting up a CMS, configuring `*.docker.local` access, or whenever a task needs `orodc help` or `orodc agents` guidance.
license: MIT
metadata:
  author: local
  scope: project
---

# Docker Dev Env

Use this skill only for this repository. It is a thin router; read the internal reference file that matches the task instead of duplicating its content here.

## Entry Points

Use these entrypoints in this order:

- `orodc status`: first command to understand project state
- `orodc help`: general documentation and command overview
- `orodc agents`: agent-focused guidance, CMS-specific instructions, coding rules, and installation steps

If it is unclear where to start, run `orodc status` first, then `orodc help`, then `orodc agents`.

## When `orodc` Is Missing

If `orodc help` reports command not found, `orodc` is not installed. Do not run `orodc`-based steps as if the command exists.

The quick install command is:

```bash
brew install digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform
```

For the full install flow (Docker requirement, `*.docker.local` infrastructure, platform-specific proxy setup, certificates, and project bootstrap), read [references/installation.md](references/installation.md).

## Internal References

Read the file that matches the task; do not preload them all:

- [references/installation.md](references/installation.md): install `orodc` + infrastructure, bootstrap a project, set up `*.docker.local`.
- [references/agents.md](references/agents.md): `orodc agents` (CMS conventions, coding rules, installation guides).
- [references/workflow.md](references/workflow.md): local dev, PHP/app commands, database actions, platform defaults, Oro URLs.
- [references/proxy.md](references/proxy.md): proxy and domain troubleshooting for `*.docker.local`.

## Usage Rules

- Run `orodc status` first when starting work in a project.
- Run `orodc agents ...` from the target project root when agent documentation is needed.
- Run environment and PHP-related commands from the target project root.
- Prefer `orodc` over raw `php`, `docker compose`, or ad-hoc container commands when the task is about the managed local environment.
- If the user asks to install, set up, deploy, or create a CMS project, read `references/agents.md` and run `orodc agents installation` first, then follow it step by step.
- Do not duplicate large parts of `orodc help` inside this skill; keep it a short router to the right entrypoints and reference files.

## Useful References

- `LOCAL-TESTING.md`
- `AGENTS.md`
- `README.md`
