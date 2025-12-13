# Spec: SOCKS5 Proxy

**Capability:** socks5-proxy  
**Change ID:** enhance-proxy-networking  
**Type:** New Capability (Optional)

## Overview

Optional SOCKS5 proxy server for direct network access to Docker containers, enabling advanced debugging and testing scenarios where direct container network access is needed.

## ADDED Requirements

### Requirement: SOCKS5-OPTIONAL-001 - SOCKS5 is Opt-in

The SOCKS5 proxy MUST be disabled by default and enabled only when explicitly configured.

#### Scenario: Default Installation

**Given** the user installs the proxy with `orodc install-proxy`  
**And** no SOCKS5 configuration is provided  
**When** the proxy container starts  
**Then** the SOCKS5 proxy service MUST NOT be started  
**And** port 1080 MUST NOT be exposed  
**And** no SOCKS5-related logs MUST appear

#### Scenario: Explicit Enable

**Given** the user sets `DC_PROXY_SOCKS5_ENABLED=1` in .env.orodc  
**When** the proxy container starts  
**Then** the SOCKS5 proxy service MUST be started  
**And** port 1080 (or configured port) MUST be exposed  
**And** SOCKS5 startup MUST be logged

### Requirement: SOCKS5-SERVICE-001 - SOCKS5 Proxy Service

When enabled, the proxy container MUST provide a SOCKS5 proxy service using socks5-server (serjs/socks5-server).

#### Scenario: SOCKS5 Basic Connectivity

**Given** SOCKS5 is enabled via `DC_PROXY_SOCKS5_ENABLED=1`  
**And** the proxy container is running  
**When** a client connects to 127.0.0.1:1080 using SOCKS5 protocol  
**Then** the connection MUST be accepted  
**And** the client MUST be able to route traffic through the proxy  
**And** the client MUST have access to the dc_shared_net Docker network

#### Scenario: Container Access via SOCKS5 and Traefik

**Given** SOCKS5 is enabled  
**And** an OroPlatform application is running in container "myapp_nginx"  
**And** Traefik is routing requests for app.docker.local to myapp_nginx  
**And** a browser is configured to use SOCKS5 proxy 127.0.0.1:1080  
**When** the browser makes a request to http://app.docker.local  
**Then** the request MUST flow: Browser → SOCKS5 (localhost:1080) → socks5-server (in container) → Traefik (in container) → nginx (in container)  
**And** socks5-server MUST resolve app.docker.local using Docker's internal DNS  
**And** the request MUST reach Traefik at its Docker network address  
**And** Traefik MUST route the request to myapp_nginx container  
**And** the response MUST be returned to the browser via the same path

#### Scenario: Direct Traefik Access via Docker DNS Name

**Given** SOCKS5 is enabled  
**And** the proxy container is running with name "traefik_docker_local"  
**And** a browser is configured to use SOCKS5 proxy 127.0.0.1:1080  
**When** the browser makes a request to http://traefik_docker_local/api/rawdata  
**Then** socks5-server MUST resolve traefik_docker_local using Docker's internal DNS  
**And** the request MUST reach Traefik's API endpoint directly  
**And** Traefik configuration MUST be returned  
**And** no port mapping or host DNS configuration is needed

#### Scenario: No DNS Configuration Needed with SOCKS5

**Given** SOCKS5 is enabled  
**And** the user has NOT configured system DNS for *.docker.local  
**And** a browser is configured to use SOCKS5 proxy 127.0.0.1:1080  
**When** the browser makes a request to http://app.docker.local  
**Then** Docker's internal DNS MUST resolve app.docker.local  
**And** the request MUST succeed without any host DNS configuration  
**And** this demonstrates SOCKS5 bypasses need for orodc-dns-sync service

### Requirement: SOCKS5-CONFIG-001 - Configurable SOCKS5 Settings

SOCKS5 proxy settings MUST be configurable via environment variables.

#### Scenario: Custom SOCKS5 Port

**Given** the user sets `DC_PROXY_SOCKS5_PORT=9999` in .env.orodc  
**And** SOCKS5 is enabled  
**When** the proxy container starts  
**Then** SOCKS5 MUST listen on host port 9999  
**And** the default port 1080 MUST NOT be used

#### Scenario: SOCKS5 Bind Address

**Given** the user sets `DC_PROXY_SOCKS5_BIND=0.0.0.0` in .env.orodc  
**And** SOCKS5 is enabled  
**When** the proxy container starts  
**Then** SOCKS5 MUST listen on all network interfaces  
**And** external connections MUST be accepted  
**Warning** documentation MUST caution about security implications

#### Scenario: Default Bind to Localhost

**Given** no custom bind address is configured  
**And** SOCKS5 is enabled  
**When** the proxy container starts  
**Then** SOCKS5 MUST bind to 127.0.0.1 only  
**And** external connections MUST be rejected

### Requirement: SOCKS5-AUTH-001 - SOCKS5 Authentication (Optional)

The system MUST support optional SOCKS5 authentication.

#### Scenario: No Authentication (Default)

**Given** SOCKS5 is enabled  
**And** no authentication is configured  
**When** a client connects to the SOCKS5 proxy  
**Then** no username/password MUST be required  
**And** the connection MUST succeed immediately

#### Scenario: Basic Authentication

**Given** the user sets `DC_PROXY_SOCKS5_USER=admin` and `DC_PROXY_SOCKS5_PASS=secret`  
**And** SOCKS5 is enabled  
**When** a client connects without credentials  
**Then** the connection MUST be rejected  
**When** a client connects with correct credentials  
**Then** the connection MUST be accepted

### Requirement: SOCKS5-DOC-001 - SOCKS5 Documentation and Examples

The system MUST provide clear documentation and examples for SOCKS5 usage.

#### Scenario: README Documentation

**Given** the user reads the README.md  
**When** they navigate to the SOCKS5 proxy section  
**Then** documentation MUST explain what SOCKS5 is used for  
**And** documentation MUST explain traffic flow: Browser → SOCKS5 → socks5-server (container) → Traefik → app  
**And** documentation MUST show how to enable SOCKS5  
**And** examples MUST include:
- Browser proxy configuration (Firefox, Chrome)
- curl with SOCKS5 (`curl --socks5 127.0.0.1:1080 http://app.docker.local`)
- curl to Traefik directly (`curl --socks5 127.0.0.1:1080 http://traefik_docker_local`)
- curl to containers via Docker DNS names (`curl --socks5 127.0.0.1:1080 http://myapp_cli`)
- Database clients (DBeaver, pgAdmin) using Docker DNS names via SOCKS5

#### Scenario: Use Case Examples

**Given** the documentation includes use cases  
**Then** the following scenarios MUST be documented:
- **Browser Access**: Configure browser SOCKS5 to access http://app.docker.local without DNS setup
- **Direct Traefik Access**: Access Traefik dashboard via http://traefik_docker_local
- **Direct Database Access**: Connect to PostgreSQL via myapp_pgsql:5432 without port forwarding
- **API Testing**: Send requests to containers using Docker DNS names
- **Multi-container Debugging**: Access multiple containers without exposing all ports
- **No DNS Configuration**: Use SOCKS5 to bypass need for orodc-dns-sync service setup

### Requirement: SOCKS5-SECURITY-001 - Security Considerations

SOCKS5 proxy MUST have appropriate security defaults and warnings.

#### Scenario: Localhost Binding by Default

**Given** SOCKS5 is enabled without custom configuration  
**Then** SOCKS5 MUST bind to 127.0.0.1 only  
**And** no external network access MUST be possible  
**And** only host machine MUST be able to connect

#### Scenario: Security Warning for External Binding

**Given** the user sets `DC_PROXY_SOCKS5_BIND=0.0.0.0`  
**When** the proxy container starts  
**Then** a security warning MUST be logged  
**And** the warning MUST explain that SOCKS5 is accessible from network  
**And** the warning MUST recommend enabling authentication

#### Scenario: Documentation Security Section

**Given** the documentation includes SOCKS5 configuration  
**Then** a security section MUST be present  
**And** it MUST explain risks of exposing SOCKS5 without authentication  
**And** it MUST recommend using authentication for non-localhost bindings  
**And** it MUST explain firewall rules if needed

### Requirement: SOCKS5-HEALTH-001 - SOCKS5 Health Monitoring

When enabled, SOCKS5 service health MUST be monitored.

#### Scenario: SOCKS5 Process Monitoring

**Given** SOCKS5 is enabled  
**And** the proxy container is running  
**When** the socks5 process crashes  
**Then** s6-overlay MUST detect the failure  
**And** s6-overlay MUST restart the socks5 process automatically  
**And** the restart MUST be logged

#### Scenario: SOCKS5 in Health Check

**Given** SOCKS5 is enabled  
**When** Docker performs a health check  
**Then** SOCKS5 port MUST be checked (TCP connect)  
**And** health check MUST fail if SOCKS5 is not responding  
**And** container MUST be marked unhealthy

### Requirement: SOCKS5-TOOLS-001 - SOCKS5 Testing Tools

The system MUST provide tools to test SOCKS5 connectivity.

#### Scenario: SOCKS5 Test Command

**Given** SOCKS5 is enabled  
**When** the user runs `orodc proxy-socks5-test`  
**Then** the command MUST attempt to connect to SOCKS5 port  
**And** the command MUST perform a test request through SOCKS5  
**And** the command MUST report success or failure  
**And** on failure, troubleshooting steps MUST be provided

#### Scenario: SOCKS5 Status

**Given** the user runs `orodc proxy-status`  
**Then** the output MUST include SOCKS5 status (enabled/disabled)  
**And** if enabled, the output MUST show SOCKS5 port and bind address  
**And** if enabled, the output MUST show authentication status (on/off)

## MODIFIED Requirements

None - This is a new optional capability with no modifications to existing requirements.

## REMOVED Requirements

None - This is additive functionality only.

## Dependencies

- gost binary available in container (https://github.com/ginuerzh/gost)
- Access to dc_shared_net Docker network
- Port 1080 (or configured port) available on host
- Independent of ssl-certificate-management and dns-resolution (optional add-on)

## Testing Requirements

### Unit Tests
- gost configuration file generation is correct
- Authentication configuration works when credentials are provided
- Port and bind address configuration is correctly applied

### Integration Tests
- SOCKS5 accepts connections when enabled
- SOCKS5 rejects connections when disabled
- SOCKS5 routes traffic to Docker network correctly
- SOCKS5 authentication works (if configured)
- SOCKS5 process is restarted by s6-overlay on failure

### Manual Tests
- Configure Firefox to use SOCKS5 proxy (127.0.0.1:1080)
- Access http://container-internal-ip from browser
- Use curl with --socks5 to access container
- Connect DBeaver to PostgreSQL via SOCKS5
- Test with and without authentication

## Acceptance Criteria

- [ ] SOCKS5 is disabled by default
- [ ] SOCKS5 can be enabled via `DC_PROXY_SOCKS5_ENABLED=1`
- [ ] SOCKS5 uses gost for proxy service
- [ ] SOCKS5 binds to 127.0.0.1 by default (security)
- [ ] SOCKS5 port is configurable (default 1080)
- [ ] SOCKS5 supports optional authentication
- [ ] `orodc proxy-socks5-test` tests connectivity
- [ ] Documentation includes use cases and browser/tool configuration examples
- [ ] Security warnings for external binding
- [ ] Health monitoring restarts SOCKS5 on failure
- [ ] No impact on proxy functionality when SOCKS5 is disabled

