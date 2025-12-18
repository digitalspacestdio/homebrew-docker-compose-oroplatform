# Spec Delta: mail-smtp-tls

## ADDED Requirements

### Requirement: MAIL-TLS-001 - Automatic Certificate Generation

The mail service MUST automatically generate a self-signed TLS certificate on first start when certificates do not exist in the shared volume.

#### Scenario: First Start With Empty Volume

**Given** the mail container is starting for the first time  
**And** the `/certs` volume is empty  
**When** the container entrypoint executes  
**Then** a self-signed certificate MUST be generated with:
- Common Name: `mail`
- Subject Alternative Names: `DNS:mail`, `DNS:mail.*.docker.local`, `DNS:localhost`
- Key type: RSA 2048 bit
- Validity: 365 days from generation date

**And** the following files MUST be created in `/certs`:
- `mail.crt` with permissions 644
- `mail.key` with permissions 600

**And** certificate generation logs MUST be visible in container output  
**And** the container MUST NOT start the SMTP service until certificates are generated

#### Scenario: Subsequent Starts With Existing Certificates

**Given** the mail container has previously generated certificates  
**And** `/certs/mail.crt` and `/certs/mail.key` exist  
**When** the container starts  
**Then** certificate generation MUST be skipped  
**And** a log message MUST indicate certificates already exist  
**And** container startup time MUST be under 2 seconds

---

### Requirement: MAIL-TLS-002 - Multi-Port SMTP Support

The mail service MUST support three SMTP endpoints with different encryption modes.

#### Scenario: Unencrypted SMTP on Port 1025

**Given** the mail service is running  
**When** a client connects to port 1025  
**Then** an unencrypted SMTP connection MUST be established  
**And** the connection MUST accept email without TLS negotiation  
**And** the connection MUST be compatible with existing msmtprc configurations

#### Scenario: Implicit TLS on Port 465

**Given** the mail service is running  
**And** TLS certificates have been generated  
**When** a client connects to port 465  
**Then** a TLS handshake MUST occur immediately  
**And** the server MUST present the `/certs/mail.crt` certificate  
**And** the connection MUST be encrypted before any SMTP commands  
**And** the server MUST accept email over the encrypted connection

#### Scenario: STARTTLS on Port 587

**Given** the mail service is running  
**And** TLS certificates have been generated  
**When** a client connects to port 587  
**Then** an unencrypted connection MUST be established initially  
**And** the server MUST advertise STARTTLS in EHLO response  
**When** the client issues STARTTLS command  
**Then** the connection MUST upgrade to TLS  
**And** the server MUST present the `/certs/mail.crt` certificate  
**And** the connection MUST accept email over the upgraded encrypted connection

**Note**: Port 587 uses the same bind address as port 1025; encryption is negotiated via STARTTLS command.

---

### Requirement: MAIL-TLS-003 - TLS Configuration via Environment Variables

The mail service MUST be configurable via environment variables for TLS behavior.

#### Scenario: Mailpit TLS Environment Variables

**Given** the mail service container is being configured  
**When** the following environment variables are set:
```yaml
MP_SMTP_BIND_ADDR: "0.0.0.0:1025"
MP_SMTP_TLS_BIND_ADDR: ":465"
MP_SMTP_TLS_CERT: "/certs/mail.crt"
MP_SMTP_TLS_KEY: "/certs/mail.key"
MP_SMTP_AUTH_ACCEPT_ANY: "1"
```
**Then** mailpit MUST bind port 1025 on all interfaces for unencrypted SMTP  
**And** mailpit MUST bind port 465 on all interfaces for implicit TLS  
**And** mailpit MUST use the specified certificate and key files  
**And** mailpit MUST accept emails without SMTP authentication (development mode)

#### Scenario: Port Binding Configuration

**Given** a user wants to customize external port mappings  
**When** the user sets environment variables in `.env.orodc`:
```
DC_ORO_PORT_MAIL_SMTP=30125
DC_ORO_PORT_MAIL_SMTPS=30465
```
**Then** port 1025 inside the container MUST map to `30125` on the host  
**And** port 465 inside the container MUST map to `30465` on the host  
**And** the default host bind address MUST be `127.0.0.1` (localhost only)

---

### Requirement: MAIL-TLS-004 - Health Check for TLS Ports

The mail service MUST implement a health check that verifies all SMTP ports are listening.

#### Scenario: Successful Health Check

**Given** the mail service container is running  
**And** certificate generation has completed  
**When** the healthcheck executes  
**Then** port 1025 MUST be listening and accepting connections  
**And** port 465 MUST be listening and accepting connections  
**And** the container status MUST transition to `healthy` within 10 seconds

#### Scenario: Failed Health Check During Startup

**Given** the mail service container is starting  
**And** certificate generation is in progress  
**When** the healthcheck executes during the `start_period`  
**Then** healthcheck failures MUST be ignored  
**And** the container MUST NOT be marked as unhealthy  
**When** the `start_period` expires  
**And** ports are still not listening  
**Then** the container MUST be marked as unhealthy after 18 retries

---

### Requirement: MAIL-TLS-005 - Certificate Persistence

TLS certificates MUST persist across container restarts and updates.

#### Scenario: Container Restart

**Given** the mail service is running  
**And** certificates exist in the `mail-certs` volume  
**When** the user runs `orodc restart mail`  
**Then** the existing certificates MUST be reused  
**And** certificate generation MUST be skipped  
**And** all SMTP ports MUST use the same certificates as before restart

#### Scenario: Container Recreate

**Given** the mail service has generated certificates  
**When** the user runs `orodc down` followed by `orodc up -d`  
**Then** the `mail-certs` volume MUST persist  
**And** the new container MUST mount the existing volume  
**And** certificates MUST NOT be regenerated  
**And** SMTP connections MUST work immediately without certificate trust updates

---

### Requirement: MAIL-TLS-006 - Mailpit Migration from Mailhog

The mail service MUST migrate from `cd2team/mailhog` to `axllent/mailpit` while maintaining API compatibility.

#### Scenario: Backward Compatible API

**Given** an application was using mailhog API endpoints  
**When** the mail service is upgraded to mailpit  
**Then** the `/api/v1/messages` endpoint MUST remain functional  
**And** the web UI MUST be accessible at the same `/mailbox` path  
**And** existing Traefik routing rules MUST continue working  
**And** the web UI port (8025) MUST remain the same

#### Scenario: Docker Image Migration

**Given** `docker-compose.yml` previously used `image: cd2team/mailhog`  
**When** the configuration is updated  
**Then** the mail service MUST use a custom build from `compose/docker/mail/Dockerfile`  
**And** the Dockerfile MUST be based on `axllent/mailpit:latest`  
**And** the container name format MUST remain `${DC_ORO_NAME}_mail`

---

### Requirement: MAIL-TLS-007 - Certificate Security

Certificate private keys MUST be protected and never exposed outside the mail container.

#### Scenario: Private Key File Permissions

**Given** certificates have been generated  
**When** inspecting the `/certs` volume from the mail container  
**Then** `/certs/mail.crt` MUST have permissions 644 (world-readable)  
**And** `/certs/mail.key` MUST have permissions 600 (owner read-write only)  
**And** `/certs/mail.key` MUST NOT be readable by non-root users

#### Scenario: Certificate Validation Properties

**Given** a certificate has been generated  
**When** inspecting the certificate with OpenSSL  
**Then** the certificate MUST contain:
- Subject: `CN=mail`
- Issuer: `CN=mail` (self-signed)
- Key Usage: `Digital Signature, Key Encipherment`
- Extended Key Usage: `TLS Web Server Authentication`
- Subject Alternative Names as specified in MAIL-TLS-001

**And** the certificate MUST be valid for at least 364 days from generation  
**And** the certificate MUST NOT be expired


