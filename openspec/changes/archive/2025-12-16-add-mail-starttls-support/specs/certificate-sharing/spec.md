# Spec Delta: certificate-sharing

## ADDED Requirements

### Requirement: CERT-SHARE-001 - Shared Certificate Volume

A shared Docker volume MUST be created to distribute mail certificates to all PHP containers.

#### Scenario: Volume Creation

**Given** the OroDC environment is being initialized  
**When** `docker-compose.yml` is processed  
**Then** a volume named `mail-certs` MUST be created  
**And** the volume driver MUST be `local`  
**And** the volume MUST persist across `docker-compose down` (not removed)

#### Scenario: Mail Container Volume Mount

**Given** the mail service is configured in docker-compose.yml  
**When** the mail container starts  
**Then** the `mail-certs` volume MUST be mounted at `/certs` with read-write permissions  
**And** the mail container MUST be able to create certificate files in `/certs`  
**And** the mail container MUST be able to modify file permissions in `/certs`

#### Scenario: PHP Container Volume Mount

**Given** PHP services (fpm, cli, consumer, websocket, ssh) are configured  
**When** any PHP container starts  
**Then** the `mail-certs` volume MUST be mounted at `/certs` with read-only permissions (`:ro`)  
**And** the PHP container MUST be able to read `/certs/mail.crt`  
**And** the PHP container MUST NOT be able to write to `/certs` directory  
**And** attempts to create files in `/certs` MUST fail with "Read-only file system" error

---

### Requirement: CERT-SHARE-002 - PHP Container msmtprc Configuration

PHP containers MUST dynamically configure msmtprc based on the `ORO_MAILER_ENCRYPTION` environment variable.

#### Scenario: No Encryption (Default)

**Given** a PHP container is starting  
**And** `ORO_MAILER_ENCRYPTION` is unset or empty string  
**When** the container entrypoint processes msmtprc  
**Then** the file `/.msmtprc` MUST be configured with:
```
account default
host mail
port 1025
tls off
auth off
from www-data@localhost
```
**And** the msmtprc MUST NOT reference `/certs/mail.crt`

#### Scenario: TLS Encryption (Implicit TLS on Port 465)

**Given** a PHP container is starting  
**And** `ORO_MAILER_ENCRYPTION=tls`  
**When** the container entrypoint processes msmtprc  
**Then** the file `/.msmtprc` MUST be configured with:
```
account default
host mail
port 465
tls on
tls_starttls off
tls_trust_file /certs/mail.crt
tls_certcheck off
auth off
from www-data@localhost
```

#### Scenario: STARTTLS Encryption (Port 587)

**Given** a PHP container is starting  
**And** `ORO_MAILER_ENCRYPTION=starttls`  
**When** the container entrypoint processes msmtprc  
**Then** the file `/.msmtprc` MUST be configured with:
```
account default
host mail
port 587
tls on
tls_starttls on
tls_trust_file /certs/mail.crt
tls_certcheck off
auth off
from www-data@localhost
```

---

### Requirement: CERT-SHARE-003 - msmtprc Template Management

The PHP container build MUST include msmtprc templates for all encryption modes.

#### Scenario: Template Files in Docker Image

**Given** the PHP container Dockerfile is being built  
**When** the shared files are copied into the image  
**Then** the following template files MUST exist:
- `/msmtprc-none.tmpl` (for unencrypted SMTP)
- `/msmtprc-tls.tmpl` (for implicit TLS)
- `/msmtprc-starttls.tmpl` (for STARTTLS)

**And** each template MUST be a valid msmtprc configuration  
**And** each template MUST differ only in port, tls, and tls_starttls settings

#### Scenario: Template Selection Logic

**Given** the PHP container entrypoint script is executing  
**When** `$ORO_MAILER_ENCRYPTION` is evaluated  
**Then** the entrypoint MUST select a template using this logic:
```
if [ "$ORO_MAILER_ENCRYPTION" = "tls" ]; then
    template="/msmtprc-tls.tmpl"
elif [ "$ORO_MAILER_ENCRYPTION" = "starttls" ]; then
    template="/msmtprc-starttls.tmpl"
else
    template="/msmtprc-none.tmpl"
fi
```
**And** the selected template MUST be copied to `/.msmtprc`  
**And** the entrypoint MUST log which template was selected

---

### Requirement: CERT-SHARE-004 - Certificate Availability Dependency

PHP containers MUST NOT start until the mail service healthcheck passes, ensuring certificates are available.

#### Scenario: Startup Order with Healthcheck

**Given** the mail service is starting and generating certificates  
**And** PHP containers have `depends_on: mail: condition: service_healthy`  
**When** docker-compose starts all services  
**Then** the mail container MUST complete certificate generation  
**And** the mail healthcheck MUST pass (ports 1025 and 465 listening)  
**And** only after the healthcheck passes MUST PHP containers start  
**And** PHP containers MUST be able to read `/certs/mail.crt` immediately upon start

#### Scenario: Failed Certificate Generation

**Given** the mail service fails to generate certificates  
**And** the healthcheck never passes within the configured retry period  
**When** the healthcheck reaches maximum retries (18)  
**Then** the mail container status MUST be `unhealthy`  
**And** PHP containers MUST NOT start  
**And** `docker ps` MUST NOT show PHP containers running  
**And** the user MUST see error logs from the mail container

---

### Requirement: CERT-SHARE-005 - Environment Variable Defaults

The docker-compose.yml MUST provide sensible defaults for mailer configuration that support both encrypted and unencrypted modes.

#### Scenario: Default Environment Variables

**Given** a user has not customized mailer settings  
**When** docker-compose.yml is processed  
**Then** the following environment variable defaults MUST be applied to PHP containers:
```yaml
ORO_MAILER_DRIVER: ${ORO_MAILER_DRIVER:-smtp}
ORO_MAILER_HOST: ${ORO_MAILER_HOST:-mail}
ORO_MAILER_PORT: ${ORO_MAILER_PORT:-1025}
ORO_MAILER_ENCRYPTION: ${ORO_MAILER_ENCRYPTION:-}  # Empty string (unencrypted)
ORO_MAILER_USER: ${ORO_MAILER_USER:-}
ORO_MAILER_PASSWORD: ${ORO_MAILER_PASSWORD:-}
```
**And** these defaults MUST maintain backward compatibility with existing projects

#### Scenario: User Override via .env.orodc

**Given** a user wants to use TLS encryption  
**When** the user adds to `.env.orodc`:
```
ORO_MAILER_ENCRYPTION=tls
ORO_MAILER_PORT=465
```
**Then** these values MUST override the docker-compose defaults  
**And** PHP containers MUST receive `ORO_MAILER_ENCRYPTION=tls`  
**And** PHP containers MUST receive `ORO_MAILER_PORT=465`  
**And** msmtprc MUST be configured with `port 465` and `tls on`

---

### Requirement: CERT-SHARE-006 - Certificate File Accessibility

PHP containers MUST be able to verify certificate file accessibility before attempting SMTP connections.

#### Scenario: Certificate File Verification

**Given** a PHP container has started successfully  
**And** the `mail-certs` volume is mounted at `/certs:ro`  
**When** a PHP process attempts to read `/certs/mail.crt`  
**Then** the file MUST be readable  
**And** the file MUST contain a valid PEM-encoded X.509 certificate  
**And** the certificate MUST start with `-----BEGIN CERTIFICATE-----`

#### Scenario: Missing Certificate Handling

**Given** the mail service failed to generate certificates  
**And** the `/certs/mail.crt` file does not exist  
**When** a PHP process running msmtp attempts to send email with TLS  
**Then** msmtp MUST fail with an error message containing "certificate"  
**And** the error MUST be logged to container output  
**And** the email MUST NOT be sent  
**And** the PHP application MUST receive a mail sending failure exception

---

### Requirement: CERT-SHARE-007 - Multi-Container Certificate Consistency

All PHP containers MUST use the same certificate from the shared volume, ensuring consistent TLS behavior.

#### Scenario: Same Certificate Across Containers

**Given** multiple PHP containers are running (fpm, cli, consumer)  
**And** each container has mounted the `mail-certs` volume  
**When** each container reads `/certs/mail.crt`  
**Then** the certificate content MUST be identical across all containers  
**And** the certificate serial number MUST be the same  
**And** all containers MUST successfully connect to the mail service with TLS

#### Scenario: Certificate Update Propagation

**Given** the mail service regenerates certificates (e.g., after expiry)  
**And** PHP containers are running with old certificates cached  
**When** the mail service overwrites `/certs/mail.crt` and `/certs/mail.key`  
**Then** new PHP container instances MUST use the updated certificate  
**And** existing PHP containers MUST use the updated certificate on next mail send  
**And** msmtp MUST NOT cache the old certificate in memory

## MODIFIED Requirements

None - This is a new capability with no modifications to existing requirements.

## REMOVED Requirements

None - This change is purely additive.

