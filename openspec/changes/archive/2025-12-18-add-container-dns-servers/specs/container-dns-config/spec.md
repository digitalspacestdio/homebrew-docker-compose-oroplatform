## ADDED Requirements

### Requirement: CONTAINER-DNS-001 - DNS Server Configuration for All Containers

All Docker containers MUST be configured with DNS servers 1.1.1.1 and 8.8.8.8 for external DNS resolution.

#### Scenario: FPM Container DNS Configuration

**Given** docker-compose.yml contains fpm service definition  
**When** the fpm container starts  
**Then** the container MUST have DNS servers 1.1.1.1 and 8.8.8.8 configured  
**And** DNS resolution MUST work: `docker exec <fpm> nslookup google.com` succeeds  
**And** both DNS servers MUST be listed in `/etc/resolv.conf` inside the container

#### Scenario: CLI Container DNS Configuration

**Given** docker-compose.yml contains cli service definition  
**When** the cli container starts  
**Then** the container MUST have DNS servers 1.1.1.1 and 8.8.8.8 configured  
**And** DNS resolution MUST work: `docker exec <cli> nslookup github.com` succeeds

#### Scenario: Database Container DNS Configuration

**Given** docker-compose-pgsql.yml or docker-compose-mysql.yml contains database service definition  
**When** the database container starts  
**Then** the container MUST have DNS servers 1.1.1.1 and 8.8.8.8 configured  
**And** DNS resolution MUST work: `docker exec <database> nslookup cloudflare.com` succeeds

#### Scenario: All Services Have DNS Configuration

**Given** all Docker Compose files (docker-compose.yml, docker-compose-pgsql.yml, docker-compose-mysql.yml, docker-compose-proxy.yml)  
**When** any service container starts (fpm, cli, consumer, websocket, nginx, database, search, mq, redis, mail, mongodb, xhgui, proxy)  
**Then** the container MUST have DNS servers 1.1.1.1 and 8.8.8.8 configured  
**And** DNS configuration MUST be present in the service definition as `dns: [1.1.1.1, 8.8.8.8]`

#### Scenario: Internal DNS Resolution Still Works

**Given** containers have DNS servers 1.1.1.1 and 8.8.8.8 configured  
**When** a container tries to resolve another container's hostname (e.g., `database`, `redis`, `search`)  
**Then** internal Docker DNS resolution MUST still work  
**And** container-to-container communication MUST not be affected  
**And** both external DNS servers and Docker's internal DNS MUST be available

#### Scenario: DNS Server Redundancy

**Given** containers are configured with DNS servers 1.1.1.1 and 8.8.8.8  
**When** DNS server 1.1.1.1 is unreachable  
**Then** the container MUST automatically fallback to 8.8.8.8  
**And** DNS resolution MUST continue to work

