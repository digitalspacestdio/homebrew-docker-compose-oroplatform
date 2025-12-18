# Change: Add DNS Servers to All Containers

## Why

Containers need reliable DNS resolution for external network requests. By default, Docker containers use the host's DNS configuration, which may be unreliable or slow in some environments. Configuring explicit DNS servers (1.1.1.1 and 8.8.8.8) ensures consistent, fast DNS resolution across all containers regardless of host DNS settings.

## What Changes

- All Docker Compose services will have DNS servers 1.1.1.1 and 8.8.8.8 configured
- DNS configuration will be applied to all service containers (fpm, cli, consumer, websocket, nginx, database, search, mq, redis, mail, mongodb, xhgui, proxy, etc.)
- Configuration will be consistent across all compose files (base, database-specific, proxy, test)
- DNS servers will be set via Docker Compose `dns` directive

## Impact

- **Affected specs**: New capability `container-dns-config`
- **Affected code**: 
  - `compose/docker-compose.yml` (base services)
  - `compose/docker-compose-pgsql.yml` (PostgreSQL services)
  - `compose/docker-compose-mysql.yml` (MySQL services)
  - `compose/docker-compose-proxy.yml` (proxy service)
  - `compose/docker-compose-test.yml` (test services)
  - Any other compose files with service definitions
- **Breaking changes**: None - this is an additive change that improves DNS reliability

