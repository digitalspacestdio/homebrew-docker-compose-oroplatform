---
name: docker-dev-env-php
description: Use `orodc help` for general documentation and `orodc agents` for CMS-specific agent guidance, then use `orodc` for local PHP Docker environment actions.
license: MIT
metadata:
  author: local
  scope: project
---

# PHP Docker Dev Env

Use this skill only for this repository.

## Entry Points

Use these entrypoints in this order:

- `orodc help`: general documentation and command overview
- `orodc agents`: agent-focused guidance, CMS-specific instructions, coding rules, and installation steps

If it is unclear where to start, run `orodc help` first, then `orodc agents`.

## `orodc agents`

Run `orodc agents` from the real application project root.

Expected project root markers:

- `composer.json`
- `.env.orodc`

Do not rely on `orodc agents` from the tap repository itself or from an arbitrary non-project directory.

Main commands:

```bash
orodc agents common
orodc agents rules
orodc agents installation
orodc agents <cms-type>
```

How to use them:

- `orodc agents common`: shared guidance for all projects
- `orodc agents rules`: coding rules for the detected CMS
- `orodc agents installation`: installation guide for the detected CMS
- `orodc agents <cms-type>`: CMS-specific instructions such as `oro`, `magento`, `symfony`, `laravel`, `wintercms`, or `php-generic`

Agent rule:

- Start with `orodc agents` when the task depends on project conventions or CMS-specific behavior.
- If the user asks to install, set up, deploy, or create a CMS project, read `orodc agents installation` first and follow it step by step.

## Usage Rules

- Run `orodc agents ...` from the target project root when agent documentation is needed.
- Run environment and PHP-related commands from the target project root.
- Prefer `orodc` over raw `php`, `docker compose`, or ad-hoc container commands when the task is about the managed local environment.
- Do not duplicate large parts of `orodc help` inside this skill; use the skill as a short guide to the right entrypoints and workflows.

## Proxy And Domains

Access via `https://<project>.docker.local` requires reverse proxy and local DNS setup. Without proxy, project domains will not open in the browser.

For Docker-based proxy management use:

```bash
orodc proxy up -d
orodc proxy install-certs
orodc proxy down
orodc proxy purge
```

Use this flow:

- Start proxy: `orodc proxy up -d`
- Install local certificates for HTTPS: `orodc proxy install-certs`
- Stop proxy without removing volumes: `orodc proxy down`
- Remove proxy completely: `orodc proxy purge`

Notes:

- `orodc proxy up -d` is the key command when domains like `*.docker.local` do not resolve through the local proxy.
- This is especially important on macOS and WSL2 with Docker Desktop.
- If proxy is not running, access by custom project domains will fail even if app containers are healthy.
- For full host infrastructure setup of Traefik, Dnsmasq, and local CA, see `README.md`.

## Local Development Workflow

Run these commands from the application root:

```bash
orodc up -d
orodc ps
orodc config
```

Use `orodc` as the default entrypoint for local development:

- Start services: `orodc up -d`
- Stop services: `orodc down`
- Check status: `orodc ps`
- Inspect merged configuration: `orodc config`
- Open shell in container: `orodc ssh`
- Read logs: `orodc logs [service]`
- Debug startup problems: `DEBUG=1 orodc up -d`

For Oro-based projects, the default local URLs are usually:

- App: `https://<project-folder-name>.docker.local`
- Admin: `https://<project-folder-name>.docker.local/admin`
- Admin credentials: `admin` / `12345678` or `$ecretPassw0rd`
- If Authelia appears: `oro` / `oro`

## PHP And App Commands

Use `orodc` for PHP and application commands instead of calling `php` directly:

```bash
orodc --version
orodc bin/console cache:clear
orodc composer install
orodc script.php
```

Important:

- Do not use `orodc cli php ...` for normal PHP commands.
- `orodc` auto-detects PHP flags, `.php` files, and common entrypoints like `bin/console`, `bin/phpunit`, and `bin/magento`.

## Database And Environment Actions

Prefer `orodc` for environment actions:

```bash
orodc psql
orodc mysql
orodc importdb dump.sql.gz
orodc databaseexport
```

Use the repository CLI before reaching for direct Docker commands.

## Platform Defaults

- Linux and WSL2: use `DC_ORO_MODE=default`
- macOS: use `DC_ORO_MODE=mutagen`
- CI: keep `DC_ORO_CONFIG_DIR` inside the workspace

## Useful References

- `LOCAL-TESTING.md`
- `AGENTS.md`
- `README.md`
