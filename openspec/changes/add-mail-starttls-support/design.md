# Design: Add Mail STARTTLS Support

## Architecture Overview

### Component Interaction
```
┌─────────────────────────────────────────────────────────────────┐
│                        OroDC Environment                         │
│                                                                   │
│  ┌──────────────┐         ┌──────────────┐      ┌────────────┐ │
│  │ PHP Container│         │ Mail Service │      │   Shared   │ │
│  │  (FPM/CLI)   │         │  (mailpit)   │      │   Volume   │ │
│  │              │         │              │      │            │ │
│  │  ┌────────┐  │  SMTP   │ Port 1025 ━━━┓     │ mail-certs │ │
│  │  │msmtprc │━━━━━━━━━━━▶│ Port 587 ━━━━┫     │  ┌──────┐  │ │
│  │  │ (TLS)  │  │ 465/587 │ Port 465 ━━━━┫     │  │.crt  │  │ │
│  │  └────────┘  │         │              │     │  │.key  │  │ │
│  │      ▲       │         │  Entrypoint  │     │  └──────┘  │ │
│  │      │       │         │      │       │     │            │ │
│  │      │       │         │      ▼       │     │            │ │
│  │  /certs (ro) │         │ gen-certs.sh │────▶│  (rw)      │ │
│  └──────────────┘         └──────────────┘     └────────────┘ │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### Data Flow

#### Certificate Generation (First Start)
1. Mail container starts → entrypoint script runs
2. Check if `/certs/mail.crt` exists
3. If not exists: Run `openssl` to generate self-signed certificate
   - CN: `mail`
   - SAN: `DNS:mail`, `DNS:mail.*.docker.local`
   - Validity: 365 days
4. Save `mail.crt` and `mail.key` to `/certs` volume
5. mailpit reads certificates and starts SMTP listeners

#### SMTP Connection (PHP → Mail)
1. PHP application creates SMTP connection via msmtprc
2. msmtprc reads `ORO_MAILER_ENCRYPTION` environment variable
3. Based on encryption type:
   - `none` → Connect to port 1025 (plain)
   - `starttls` → Connect to port 587, issue STARTTLS command
   - `tls` → Connect to port 465 with immediate TLS handshake
4. If TLS: msmtprc reads `/certs/mail.crt` for validation
5. Email transmitted over encrypted/unencrypted channel
6. mailpit receives and stores email in memory

## Technical Decisions

### Decision 1: Mailpit vs Mailhog
**Context**: Need a mail testing service with TLS support

**Options**:
| Option | Pros | Cons |
|--------|------|------|
| mailhog | Currently used, familiar | Abandoned (no updates since 2019), no native TLS |
| mailpit | Active maintenance, native TLS, better UI | Migration required, new configuration |
| MailCatcher | Ruby-based, simple | No TLS support, performance issues |
| smtp4dev | .NET-based, Windows-friendly | Docker image size, .NET runtime overhead |

**Decision**: Use **mailpit**

**Rationale**:
- Actively maintained (last release 2024)
- Native TLS support via `MP_SMTP_TLS_CERT` env var
- Drop-in replacement for mailhog (same ports, API compatibility)
- Better UI with search, tagging, and attachments
- Lower memory footprint (Go vs Node.js)
- Official Docker image with ARM64 support

**Consequences**:
- Need to update docker-compose.yml image reference
- Environment variables change (MH_* → MP_*)
- API endpoints remain compatible (no app changes)

### Decision 2: Certificate Generation Location
**Context**: Where should certificates be generated?

**Options**:
| Option | Pros | Cons |
|--------|------|------|
| Mail container | Single source of truth, auto-renewal possible | Container restarts if generation fails |
| Init container | Isolated failure domain | Extra container, complexity |
| Host script | No container dependency | Platform-specific, breaks zero-config |
| PHP container | Already has openssl | Multiple cert copies, race conditions |

**Decision**: **Mail container entrypoint**

**Rationale**:
- Follows existing pattern from `ssl-certificate-management` spec
- Certificates only used by mail service (unlike proxy certs)
- Container healthcheck prevents dependent containers from starting before certs are ready
- Simplest implementation with no additional containers
- Errors are visible in container logs (`docker logs mail`)

**Consequences**:
- Mail container startup time +2-5 seconds on first run
- Subsequent starts skip generation (< 1 second overhead)
- PHP containers must wait for mail healthcheck (already required)

### Decision 3: Certificate Sharing Mechanism
**Context**: How should PHP containers access mail certificates?

**Options**:
| Option | Pros | Cons |
|--------|------|------|
| Shared volume | Docker-native, read-only mounts | Volume management overhead |
| Copy via init container | No volume needed | File sync complexity, stale certs |
| Docker secrets | Encrypted at rest | Swarm-only, overkill for dev |
| Environment variable | Simple | Size limits, not secure for keys |

**Decision**: **Shared Docker volume** (`mail-certs`)

**Rationale**:
- Consistent with existing volume strategy (appcode, home-user)
- Read-only mounts in PHP containers (security)
- Automatic propagation to all containers
- No sync scripts or additional orchestration
- Volume persists across container recreations

**Consequences**:
- One additional Docker volume per project
- Volume must be created in docker-compose.yml
- Mount point `/certs` reserved in mail and PHP containers

### Decision 4: msmtprc Configuration Strategy
**Context**: How should msmtprc support multiple TLS modes?

**Options**:
| Option | Pros | Cons |
|--------|------|------|
| Single static config | Simple, no logic | Can't switch encryption dynamically |
| Multiple config files | Clean separation | File duplication, complex selection |
| Environment-driven template | Flexible, DRY | Requires entrypoint processing |
| Runtime detection | Automatic | Hidden behavior, hard to debug |

**Decision**: **Environment-driven msmtprc** with `ORO_MAILER_ENCRYPTION`

**Rationale**:
- Matches existing OroPlatform environment variable pattern
- Single source of truth (`.env.orodc`)
- Supports all three modes: none, tls, starttls
- Easy to debug (`env | grep MAILER`)
- Consistent with `ORO_MAILER_*` naming convention

**Example Configuration**:
```bash
# .env.orodc
ORO_MAILER_DRIVER=smtp
ORO_MAILER_HOST=mail
ORO_MAILER_PORT=587           # or 465 for implicit TLS
ORO_MAILER_ENCRYPTION=starttls # or 'tls' or ''
```

**Generated msmtprc**:
```
account default
host mail
port 587
tls on
tls_starttls on              # Only if ENCRYPTION=starttls
tls_trust_file /certs/mail.crt
tls_certcheck off            # Dev environment, self-signed OK
auth off
from www-data@localhost
```

**Consequences**:
- Dockerfile must process `ORO_MAILER_ENCRYPTION` in entrypoint
- Need separate msmtprc for each encryption mode
- More complex than static config, but much more flexible

### Decision 5: SMTP Port Strategy
**Context**: Which SMTP ports should be exposed?

**Options**:
| Standard | Port | Encryption | Auth Required | Use Case |
|----------|------|------------|---------------|----------|
| SMTP | 25 | None | No | Mail relay (not for dev) |
| Submission | 587 | STARTTLS | Yes (prod) | Modern standard |
| SMTPS | 465 | Implicit TLS | Yes (prod) | Legacy but secure |
| Custom | 1025 | None | No | Current mailhog default |

**Decision**: Support **ports 1025, 587, and 465**

**Rationale**:
- **Port 1025**: Backward compatibility, unencrypted testing
- **Port 587**: Modern STARTTLS standard, matches production
- **Port 465**: Implicit TLS for older clients
- Skip port 25 (requires root, conflicts with host MTA)

**mailpit Configuration**:
```yaml
environment:
  - MP_SMTP_BIND_ADDR=0.0.0.0:1025   # Unencrypted
  - MP_SMTP_TLS_BIND_ADDR=:465       # Implicit TLS
  - MP_SMTP_TLS_CERT=/certs/mail.crt
  - MP_SMTP_TLS_KEY=/certs/mail.key
  - MP_SMTP_AUTH_ACCEPT_ANY=1        # Dev mode: accept without auth
```

**Note**: Port 587 with STARTTLS uses same bind address as 1025 with TLS upgrade command.

**Consequences**:
- Three SMTP endpoints to test and document
- Healthcheck must verify all three ports
- Users can test production encryption locally

## Certificate Specification

### Certificate Properties
```
Subject: CN=mail
Issuer: CN=mail (self-signed)
Validity: 365 days from generation
Key: RSA 2048 bit
SAN:
  - DNS:mail
  - DNS:mail.*.docker.local
  - DNS:localhost
Usage: Digital Signature, Key Encipherment
Extended: TLS Web Server Authentication
```

### Generation Script (Embedded in Entrypoint)
```bash
#!/bin/sh
set -e

CERT_DIR="/certs"
CERT_FILE="$CERT_DIR/mail.crt"
KEY_FILE="$CERT_DIR/mail.key"

# Skip if certificates exist
if [ -f "$CERT_FILE" ] && [ -f "$KEY_FILE" ]; then
    echo "[INFO] Mail certificates exist, skipping generation"
    exit 0
fi

echo "[INFO] Generating self-signed mail certificate..."

# Create certificate directory
mkdir -p "$CERT_DIR"

# Generate certificate with SAN
openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout "$KEY_FILE" \
    -out "$CERT_FILE" \
    -days 365 \
    -subj "/CN=mail" \
    -addext "subjectAltName=DNS:mail,DNS:mail.*.docker.local,DNS:localhost"

# Set permissions
chmod 644 "$CERT_FILE"
chmod 600 "$KEY_FILE"

echo "[INFO] Certificate generation complete"
echo "[INFO]   Certificate: $CERT_FILE"
echo "[INFO]   Private key: $KEY_FILE"
```

### Security Considerations
- **Private Key Protection**: 600 permissions, never exposed outside container
- **Self-Signed OK**: Dev environment, certificate validation disabled in msmtprc
- **No CA Chain**: Not needed for point-to-point SMTP
- **Expiry Monitoring**: Add warning log 30 days before expiry (future enhancement)

## Integration Points

### 1. docker-compose.yml Changes
```yaml
volumes:
  mail-certs:
    driver: local

services:
  mail:
    image: axllent/mailpit:latest
    container_name: ${DC_ORO_NAME:-unnamed}_mail
    volumes:
      - mail-certs:/certs
    environment:
      - MP_SMTP_BIND_ADDR=0.0.0.0:1025
      - MP_SMTP_TLS_BIND_ADDR=:465
      - MP_SMTP_TLS_CERT=/certs/mail.crt
      - MP_SMTP_TLS_KEY=/certs/mail.key
      - MP_SMTP_AUTH_ACCEPT_ANY=1
      - MP_WEBROOT=/mailbox
    ports:
      - "${DC_ORO_MAIL_BIND_HOST:-127.0.0.1}:${DC_ORO_PORT_MAIL_SMTP:-1025}:1025"
      - "${DC_ORO_MAIL_BIND_HOST:-127.0.0.1}:${DC_ORO_PORT_MAIL_SMTPS:-465}:465"
    entrypoint: /bin/sh
    command: |
      -c "
      # Certificate generation script (inline or separate file)
      /usr/local/bin/generate-certs.sh
      # Start mailpit
      exec /mailpit
      "
    healthcheck:
      test: "nc -zv localhost 1025 && nc -zv localhost 465"
      start_period: 10s
      interval: 5s
      retries: 18

  fpm:
    volumes:
      - mail-certs:/certs:ro
    depends_on:
      mail:
        condition: service_healthy
```

### 2. PHP Container Dockerfile Changes
```dockerfile
# Add msmtprc template
COPY shared/msmtprc.tmpl /.msmtprc.tmpl

# Entrypoint will process template based on ORO_MAILER_ENCRYPTION
```

### 3. Environment Variables
| Variable | Default | Values | Purpose |
|----------|---------|--------|---------|
| `ORO_MAILER_DRIVER` | `smtp` | smtp, sendmail | Transport method |
| `ORO_MAILER_HOST` | `mail` | hostname | SMTP server |
| `ORO_MAILER_PORT` | `587` | 1025, 465, 587 | SMTP port |
| `ORO_MAILER_ENCRYPTION` | `starttls` | none, tls, starttls | Encryption type |
| `ORO_MAILER_USER` | `` | string | Username (unused in dev) |
| `ORO_MAILER_PASSWORD` | `` | string | Password (unused in dev) |

## Testing Strategy

### Unit Tests (Goss)
```yaml
# mailpit-tls.yaml
port:
  tcp:1025:
    listening: true
    ip: ["0.0.0.0"]
  tcp:465:
    listening: true
    ip: ["0.0.0.0"]

file:
  /certs/mail.crt:
    exists: true
    mode: "0644"
  /certs/mail.key:
    exists: true
    mode: "0600"

command:
  cert-validity:
    exec: "openssl x509 -in /certs/mail.crt -noout -checkend 0"
    exit-status: 0
  cert-subject:
    exec: "openssl x509 -in /certs/mail.crt -noout -subject"
    stdout: ["CN=mail"]
```

### Integration Tests (Manual)
```bash
# Test 1: Unencrypted SMTP (port 1025)
echo "Subject: Test Plain\n\nUnencrypted" | msmtp -C /.msmtprc-plain -t test@example.com

# Test 2: STARTTLS (port 587)
echo "Subject: Test STARTTLS\n\nSTARTTLS" | msmtp -C /.msmtprc-starttls -t test@example.com

# Test 3: Implicit TLS (port 465)
echo "Subject: Test TLS\n\nImplicit TLS" | msmtp -C /.msmtprc-tls -t test@example.com

# Verify in mailpit UI
curl http://localhost:8025/api/v1/messages | jq '.messages | length'
# Expected: 3
```

### Performance Benchmarks
- Certificate generation: < 3 seconds
- Container startup (with cert gen): < 8 seconds
- Container startup (certs exist): < 2 seconds
- Email send (TLS): < 100ms
- Email send (plain): < 50ms

## Rollback Plan

If issues occur after deployment:

1. **Immediate**: Revert docker-compose.yml to use mailhog
   ```bash
   git revert <commit-hash>
   orodc down && orodc up -d
   ```

2. **Partial**: Keep mailpit, disable TLS
   ```yaml
   # Remove TLS environment variables
   # Use only port 1025
   ```

3. **Data Preservation**: Email storage is ephemeral (RAM), no data loss

## Future Enhancements

### Phase 2 (Not in Current Scope)
- SMTP authentication testing (AUTH LOGIN/PLAIN)
- Certificate auto-renewal (warn at 30 days, regenerate at 7 days)
- Custom CA certificate import (use proxy CA)
- SMTP relay to external services (Gmail, SendGrid)
- Multiple mail service instances (separate projects)

### Monitoring & Observability
- Certificate expiry warnings in container logs
- Prometheus metrics for email counts by encryption type
- Health endpoint reporting TLS status
- Dashboard widget showing mail service status

## References

### External Documentation
- [Mailpit Documentation](https://mailpit.axllent.org/)
- [Mailpit TLS Configuration](https://mailpit.axllent.org/docs/configuration/smtp/)
- [Mailpit Certificates](https://mailpit.axllent.org/docs/configuration/certificates/)
- [msmtp TLS Options](https://marlam.de/msmtp/msmtp.html#TLS)
- [RFC 3207 - SMTP STARTTLS](https://www.rfc-editor.org/rfc/rfc3207)
- [RFC 8314 - SMTPS on Port 465](https://www.rfc-editor.org/rfc/rfc8314)

### Internal References
- `openspec/specs/ssl-certificate-management/spec.md` - Certificate generation patterns
- `openspec/specs/docker-image-management/spec.md` - Image build conventions
- `compose/docker/proxy/generate-certs.sh` - Existing cert generation example


