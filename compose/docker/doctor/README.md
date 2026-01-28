# Doctor Goss Configuration

This directory contains Goss configuration files for the `orodc doctor` command.

## Directory Structure

```
doctor/
├── legacy/           # Legacy configurations (port-only checks for OroPlatform < 6.1)
│   ├── fpm.yaml
│   ├── nginx.yaml
│   ├── redis.yaml
│   └── ...
├── default/          # Default configurations (full checks for OroPlatform 6.1+)
│   ├── fpm.yaml
│   ├── cli.yaml
│   ├── nginx.yaml
│   └── ...
├── v6.1/             # Configurations for OroPlatform 6.1
│   ├── fpm.yaml
│   └── ...
├── v6.2/             # Configurations for OroPlatform 6.2
│   ├── fpm.yaml
│   └── ...
└── README.md
```

## How It Works

1. **Version Detection**: The `orodc doctor` command automatically detects the OroPlatform version from `composer.json` by looking for `oro/platform`, `oro/commerce`, or `oro/crm` packages.

2. **Version-Based Mode Selection**:
   - **OroPlatform >= 6.1**: Uses full checks (processes, ports, commands, HTTP checks)
   - **OroPlatform < 6.1**: Uses legacy mode (port-only checks)

3. **Config Selection**: 
   - For **6.1+**: If version-specific config exists (e.g., `v6.1/fpm.yaml`), it is used. Otherwise, default config is used (e.g., `default/fpm.yaml`)
   - For **< 6.1**: If legacy config exists (e.g., `legacy/fpm.yaml`), it is used. Otherwise, port-only config is auto-generated
   - If no config file exists, appropriate config is auto-generated

4. **Config Mounting**: Configs are copied to `${DC_ORO_CONFIG_DIR}/doctor/` and mounted into containers using Docker bind mounts when running checks.

## Version Support

### Legacy Mode (< 6.1)
For OroPlatform versions < 6.1, only **port checks** are performed. This ensures compatibility with older versions without requiring complex service-specific checks.

Legacy configs are located in `legacy/` directory and contain minimal port-only checks.

### Full Mode (6.1+)
For OroPlatform versions >= 6.1, **full checks** are performed including:
- Process checks
- Port checks
- Command checks (PHP extensions, versions, etc.)
- HTTP checks (for web services)

## Adding Version-Specific Configs

To add configurations for a new OroPlatform version (6.1+):

1. Create a directory named after the version (e.g., `v6.3/`)
2. Copy or create service-specific config files (e.g., `fpm.yaml`, `nginx.yaml`)
3. Customize checks as needed for that version

Example:
```bash
mkdir -p compose/docker/doctor/v6.3
cp compose/docker/doctor/default/fpm.yaml compose/docker/doctor/v6.3/fpm.yaml
# Edit v6.3/fpm.yaml to add version-specific checks
```

For legacy versions (< 6.1), edit files in `legacy/` directory if you need custom port checks.

## Service Config Files

Each service should have its own YAML file named after the service (e.g., `fpm.yaml`, `nginx.yaml`).

Supported services:
- `fpm.yaml` - PHP-FPM service checks
- `cli.yaml` - CLI container checks
- `nginx.yaml` - Nginx web server checks
- `database.yaml` - Database (PostgreSQL/MySQL) checks
- `redis.yaml` - Redis cache checks
- `search.yaml` - Elasticsearch checks
- `mq.yaml` - RabbitMQ message queue checks
- `mail.yaml` - Mailpit/Mailhog checks
- `mongodb.yaml` - MongoDB checks

## Goss Configuration Format

See [Goss documentation](https://github.com/goss-org/goss/blob/master/docs/manual.md) for full syntax.

Example config structure:
```yaml
# Process checks
process:
  nginx:
    running: true

# Port checks
port:
  tcp:80:
    listening: true

# Command checks
command:
  nginx-config-test:
    exec: "nginx -t 2>&1"
    exit-status: 0
```
