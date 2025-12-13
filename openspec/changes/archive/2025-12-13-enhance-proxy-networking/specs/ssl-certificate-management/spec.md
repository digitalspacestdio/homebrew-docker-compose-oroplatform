# Spec: SSL Certificate Management

**Capability:** ssl-certificate-management  
**Change ID:** enhance-proxy-networking  
**Type:** New Capability

## Overview

Automatic SSL/TLS certificate generation and management for local development, providing HTTPS support for all *.docker.local domains without manual certificate creation.

## ADDED Requirements

### Requirement: AUTO-CERT-GEN-001 - Automatic Certificate Generation on First Start

The proxy container MUST automatically generate a self-signed CA certificate and wildcard certificate for *.docker.local on first start when certificates do not exist.

#### Scenario: Fresh Installation

**Given** the proxy container is starting for the first time  
**And** the persistent certificate volume is empty  
**When** the entrypoint script executes  
**Then** the following certificates MUST be generated:
- Root CA certificate (ca.crt) with 10-year validity
- Root CA private key (ca.key)
- Wildcard certificate for *.docker.local (docker.local.crt) with 1-year validity
- Wildcard private key (docker.local.key)

**And** all certificates MUST be saved to the persistent volume `/certs`  
**And** certificate generation logs MUST be visible in container output  
**And** Traefik MUST be configured to use the generated wildcard certificate

#### Scenario: Subsequent Starts

**Given** the proxy container has generated certificates previously  
**And** certificates exist in the persistent volume  
**When** the container starts again  
**Then** certificate generation MUST be skipped  
**And** existing certificates MUST be reused  
**And** container startup time MUST be minimal (< 5 seconds)

### Requirement: AUTO-CERT-GEN-002 - HTTPS Endpoint Configuration

The proxy container MUST expose an HTTPS endpoint using the generated certificates.

#### Scenario: HTTPS Traffic Handling

**Given** the proxy container is running  
**And** certificates have been generated  
**When** a client makes an HTTPS request to https://app.docker.local:8443  
**Then** Traefik MUST terminate SSL using the wildcard certificate  
**And** the request MUST be proxied to the appropriate backend container via HTTP  
**And** the SSL certificate MUST be valid for *.docker.local  
**And** the certificate issuer MUST be "OroDC-Local-CA"

#### Scenario: Multiple Subdomains

**Given** multiple OroPlatform applications are running (app1.docker.local, app2.docker.local)  
**When** HTTPS requests are made to different subdomains  
**Then** all subdomains MUST use the same wildcard certificate  
**And** no certificate warnings MUST appear for valid *.docker.local domains

### Requirement: CERT-EXPORT-001 - Certificate Export Command

The system MUST provide a command to export the root CA certificate for importing into system trust stores.

#### Scenario: Export CA Certificate

**Given** the proxy container is running  
**And** certificates have been generated  
**When** the user runs `orodc export-proxy-cert`  
**Then** the CA certificate (ca.crt) MUST be copied from the container to the host  
**And** the certificate MUST be saved to `~/orodc-proxy-ca.crt`  
**And** the command output MUST display the certificate file path  
**And** the command output MUST include OS-specific instructions for importing the certificate

#### Scenario: Export Before Certificate Generation

**Given** the proxy container has not been started yet  
**When** the user runs `orodc export-proxy-cert`  
**Then** the command MUST display an error message  
**And** the error MUST indicate that the proxy must be installed first  
**And** the error MUST suggest running `orodc install-proxy`

### Requirement: CERT-PERSIST-001 - Certificate Persistence

Certificates MUST persist across container restarts and updates.

#### Scenario: Container Recreation

**Given** the proxy container is running  
**And** certificates have been generated  
**When** the user runs `docker-compose down` and then `docker-compose up`  
**Then** the same certificates MUST be reused  
**And** no new certificates MUST be generated  
**And** browser trust settings MUST remain valid

#### Scenario: Proxy Update

**Given** the proxy container is running with Traefik v2.11  
**And** certificates exist in the persistent volume  
**When** the user updates to Traefik v2.12  
**And** recreates the proxy container  
**Then** existing certificates MUST still be used  
**And** HTTPS connections MUST continue working without re-importing CA

### Requirement: CERT-SECURE-001 - Certificate Security

Certificate private keys MUST be protected and never exposed outside the container.

#### Scenario: Private Key Protection

**Given** certificates have been generated  
**When** inspecting the certificate volume  
**Then** the CA private key (ca.key) MUST have 600 permissions  
**And** the wildcard private key (docker.local.key) MUST have 600 permissions  
**And** only the root user MUST be able to read private keys

#### Scenario: Export Only Public Certificates

**Given** the user runs `orodc export-proxy-cert`  
**When** the certificate is exported  
**Then** only the CA public certificate (ca.crt) MUST be exported  
**And** private keys MUST NOT be accessible from the host  
**And** private keys MUST remain in the container volume only

### Requirement: CERT-COMPAT-001 - Backward Compatibility

The HTTPS endpoint MUST be additive and not break existing HTTP functionality.

#### Scenario: HTTP Still Works

**Given** the proxy container is running with HTTPS enabled  
**When** a client makes an HTTP request to http://app.docker.local:8880  
**Then** the request MUST be handled successfully  
**And** no redirect to HTTPS MUST occur (user choice)  
**And** existing applications using HTTP MUST continue working

#### Scenario: New Installations

**Given** a user is installing OroDC for the first time  
**When** they run `orodc install-proxy`  
**Then** both HTTP (8880) and HTTPS (8443) endpoints MUST be available  
**And** the user MUST be notified about both endpoints  
**And** instructions for importing the CA certificate MUST be displayed

## MODIFIED Requirements

None - This is a new capability with no modifications to existing requirements.

## REMOVED Requirements

None - This is additive functionality only.

## Dependencies

- Docker volume support for persistent storage
- OpenSSL available in container image
- Traefik v2.11+ with TLS configuration support

## Testing Requirements

### Unit Tests
- Certificate generation script produces valid certificates
- Certificate expiry dates are correct (10 years CA, 1 year wildcard)
- Certificate subject alternative names include *.docker.local

### Integration Tests
- HTTPS endpoint responds with valid certificate
- Certificate persists across container restarts
- Export command successfully copies CA certificate
- Multiple subdomains share wildcard certificate

### Manual Tests
- Import CA certificate into macOS Keychain
- Import CA certificate into Windows Certificate Store
- Import CA certificate into Linux ca-certificates
- Browser shows green lock icon for *.docker.local
- No certificate warnings in browser

## Acceptance Criteria

- [ ] Certificates auto-generate on first start
- [ ] HTTPS endpoint (8443) serves traffic with valid certificate
- [ ] `orodc export-proxy-cert` exports CA certificate with instructions
- [ ] Certificates persist in named Docker volume
- [ ] Private keys are never exposed to host
- [ ] HTTP endpoint (8880) continues working unchanged
- [ ] Documentation covers certificate import for major OS/browsers
- [ ] No breaking changes to existing proxy functionality

