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

## SSH access

`orodc ssh` opens a shell in the `ssh` service container.

**Authentication:** always uses the project key `~/.orodc/<project>/ssh_id_ed25519` (`IdentitiesOnly=yes`). Host keys from `ssh-agent` are not used to log in.

**SSH agent forwarding:** the host `ssh-agent` is forwarded into the container by default (`ForwardAgent=yes`). Use this for `git clone`/`git pull` over SSH, deploy keys, and other outbound SSH from inside the container.

**Disable agent forwarding** when you need container-local keys (different from the host agent):

```bash
# In ~/.orodc/<project>/.env.orodc or project .env.orodc
DC_ORO_SSH_FORWARD_AGENT=no

# Or one-shot
DC_ORO_SSH_FORWARD_AGENT=no orodc ssh
```

Disable values: `no`, `0`, `false`, `off`, `disabled`. Default: `yes`.

**Prerequisites on the host:**

```bash
eval "$(ssh-agent -s)"   # if agent is not running yet
ssh-add ~/.ssh/id_ed25519   # or your key path
ssh-add -l                  # verify keys are loaded
```

**Verify inside the container:**

```bash
orodc ssh
ssh-add -l                  # should list the same keys as on the host
git ls-remote git@github.com:org/repo.git
```

**Notes:**

- `COMPOSER_AUTH` is also sent into the container (`SendEnv=COMPOSER_AUTH`).
- Project key is created automatically on first `orodc ssh` if missing.
- To pass extra SSH client options, use `ORO_DC_SSH_ARGS` in `.env.orodc`.
- To disable host agent forwarding, use `DC_ORO_SSH_FORWARD_AGENT=no` in `.env.orodc`.

## Oro default URLs

- App: `https://<project-folder-name>.docker.local`
- Admin: `https://<project-folder-name>.docker.local/admin`
- Admin credentials: `admin` / `12345678` or `$ecretPassw0rd`
- If Authelia appears: `oro` / `oro`
