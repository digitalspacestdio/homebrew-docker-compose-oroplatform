# Local Development Workflow

Internal reference. Read this for day-to-day environment, PHP, and database actions. Run all commands from the application root.

## Environment

```bash
orodc status                  # Check project state (run first)
orodc up -d                   # Start services
orodc down                    # Stop services
orodc ps                      # Status
orodc config                  # Inspect merged configuration
orodc ssh                     # Shell in container
orodc logs [service]          # Read logs
DEBUG=1 orodc up -d           # Debug startup problems
```

Prefer `orodc` over raw `php`, `docker compose`, or ad-hoc container commands when the task is about the managed local environment.

## PHP and application commands

```bash
orodc --version
orodc bin/console cache:clear
orodc composer install
orodc script.php
```

- Do not use `orodc cli php ...` for normal PHP commands.
- `orodc` auto-detects PHP flags, `.php` files, and entrypoints like `bin/console`, `bin/phpunit`, and `bin/magento`.

## Database and environment actions

```bash
orodc psql
orodc mysql
orodc importdb dump.sql.gz
orodc databaseexport
```

Use the repository CLI before reaching for direct Docker commands.

## Platform defaults

- Linux and WSL2: `DC_ORO_MODE=default`
- macOS: `DC_ORO_MODE=mutagen`
- CI: keep `DC_ORO_CONFIG_DIR` inside the workspace

## Oro default URLs

- App: `https://<project-folder-name>.docker.local`
- Admin: `https://<project-folder-name>.docker.local/admin`
- Admin credentials: `admin` / `12345678` or `$ecretPassw0rd`
- If Authelia appears: `oro` / `oro`
