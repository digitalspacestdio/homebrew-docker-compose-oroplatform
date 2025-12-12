# Design: Enhanced Proxy Networking

**Change ID:** enhance-proxy-networking

## Architecture Overview

### Option 1: Direct Access (Default - HTTP/HTTPS via port mapping)

```
┌─────────────────────────────────────────────────────────┐
│  Developer Host Machine                                 │
│                                                          │
│  ┌──────────────┐         ┌─────────────────────────┐  │
│  │   Browser    │────────▶│   System DNS Resolver   │  │
│  │              │         │   (*.docker.local →     │  │
│  │  HTTPS://    │         │    127.0.0.1)          │  │
│  │  app.docker  │         └─────────────────────────┘  │
│  │    .local    │                      │                │
│  └──────────────┘                      ▼                │
│         │                    ┌─────────────────────┐    │
│         │                    │   Port Mapping      │    │
│         └───────────────────▶│   8880 (HTTP)       │    │
│                              │   8443 (HTTPS)      │    │
│                              └─────────────────────┘    │
│                                       │                  │
└───────────────────────────────────────┼──────────────────┘
                                        ▼
                   ┌──────────────────────────────────────┐
                   │  Docker: traefik_docker_local        │
                   │                                       │
                   │  ┌─────────────────────────────────┐ │
                   │  │  Traefik (Reverse Proxy)        │ │
                   │  │  - HTTP :80 → containers        │ │
                   │  │  - HTTPS :443 → containers      │ │
                   │  └─────────────────────────────────┘ │
                   └───────────────────────────────────────┘
                                        │
                                        ▼
                            ┌───────────────────────┐
                            │   dc_shared_net       │
                            │                       │
                            │  ┌────────────────┐   │
                            │  │ nginx (app)    │   │
                            │  │ OroCommerce    │   │
                            │  └────────────────┘   │
                            └───────────────────────┘
```

### Option 2: SOCKS5 Proxy Access (When enabled - direct Docker network access)

```
┌─────────────────────────────────────────────────────────┐
│  Developer Host Machine                                 │
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │   Browser (configured with SOCKS5 proxy)         │   │
│  │   Proxy: 127.0.0.1:1080                          │   │
│  │                                                   │   │
│  │   Request: http://traefik_docker_local           │   │
│  │         or http://app.docker.local               │   │
│  └──────────────────────────────────────────────────┘   │
│                              │                           │
│                              │ SOCKS5                    │
│                              │ protocol                  │
│                              ▼                           │
│                   ┌──────────────────────┐               │
│                   │   Port 1080          │               │
│                   └──────────────────────┘               │
│                              │                           │
└──────────────────────────────┼───────────────────────────┘
                               ▼
          ┌────────────────────────────────────────────────┐
          │  Docker: traefik_docker_local                  │
          │                                                 │
          │  ┌───────────────────────────────────────────┐ │
          │  │  SOCKS5 Proxy (gost)                      │ │
          │  │  - Listen on :1080                        │ │
          │  │  - Has access to dc_shared_net            │ │
          │  │  - Can resolve Docker DNS names           │ │
          │  └───────────────────────────────────────────┘ │
          │                     │                           │
          │                     ▼                           │
          │  ┌───────────────────────────────────────────┐ │
          │  │  Traefik (Reverse Proxy)                  │ │
          │  │  - HTTP :80 → containers                  │ │
          │  │  - HTTPS :443 → containers                │ │
          │  │  - Docker DNS: traefik_docker_local       │ │
          │  └───────────────────────────────────────────┘ │
          └─────────────────────────────────────────────────┘
                               │
                               ▼
                   ┌───────────────────────┐
                   │   dc_shared_net       │
                   │                       │
                   │  ┌────────────────┐   │
                   │  │ nginx (app)    │   │
                   │  │ myapp_cli      │   │
                   │  │ PostgreSQL     │   │
                   │  │ Redis          │   │
                   │  └────────────────┘   │
                   └───────────────────────┘
```

### Complete System with All Services

```
┌─────────────────────────────────────────────────────────┐
│  Docker: traefik_docker_local (Proxy Container)         │
│                                                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │  SOCKS5 Proxy (gost) - Port :1080 (optional)   │    │
│  │  ↓ Provides access to Docker network           │    │
│  └─────────────────────────────────────────────────┘    │
│                     │                                    │
│                     ▼                                    │
│  ┌─────────────────────────────────────────────────┐    │
│  │  Traefik (Reverse Proxy)                        │    │
│  │  - HTTP :80, HTTPS :443                         │    │
│  │  - Routes by Host header                        │    │
│  │  - SSL termination                              │    │
│  └─────────────────────────────────────────────────┘    │
│                                                          │
│  Volume: proxy_certs                                     │
│    - ca.crt, ca.key                                      │
│    - docker.local.crt, *.key                             │
└──────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  Host Machine                                            │
│                                                          │
│  orodc-dns-sync (bash script daemon)                    │
│  ├─ Watches Docker events                               │
│  ├─ Updates /etc/hosts automatically                    │
│  └─ Runs as systemd/launchd service                     │
│                                                          │
│  /etc/hosts:                                             │
│    # OroDC Auto DNS - START                             │
│    127.0.0.1 app.docker.local                           │
│    # OroDC Auto DNS - END                               │
└──────────────────────────────────────────────────────────┘

**Traffic Flow with SOCKS5:**
Browser → SOCKS5 (localhost:1080) → gost (in container) → 
Traefik (in container, :80/:443) → nginx (app container)

**Traffic Flow without SOCKS5:**
Browser → localhost:8443 → Traefik (in container) → nginx (app container)
```

## Design Decisions

### 1. DNS Resolution Strategy

**Decision: Auto /etc/hosts Sync via Bash Script**

Provide automatic /etc/hosts management using simple bash script that watches Docker events.

**Rationale:**
- **Simplest possible solution:** Pure bash script, no dependencies
- Uses Docker Events API to watch container start/stop
- No DNS server needed, no port conflicts, no additional services
- Inspired by [DNS Proxy Server approach](https://stackoverflow.com/questions/37242217/access-docker-container-from-host-using-containers-name/63656003#63656003)
- **With SOCKS5:** Docker's internal DNS works automatically as alternative
- Works everywhere: Linux, macOS, Windows (WSL)

**Why bash script over DNS server:**
| Approach | Pros | Cons |
|----------|------|------|
| **Bash /etc/hosts sync (CHOSEN)** | **Simple, reliable, no DNS server, works everywhere, no dependencies** | Requires sudo for /etc/hosts |
| DNS server (dnsmasq) | DNS protocol | Complex, port conflicts, requires DNS server software |
| Manual /etc/hosts | No automation | User must update manually |
| SOCKS5 only | No DNS setup | Browser proxy config required |

**Implementation:**
- Simple bash script `orodc-dns-sync` watches Docker events
- Automatically adds/removes entries to /etc/hosts when containers start/stop
- Uses Docker labels to identify containers: `orodc.dns.hostname=app.docker.local`
- Runs as systemd service (Linux) or launchd daemon (macOS)
- `orodc proxy-dns-setup --install` installs and starts the service
- No additional software dependencies beyond Docker and bash

**Auto /etc/hosts Process:**
1. `orodc-dns-sync` daemon watches Docker events
2. Container starts with label `orodc.dns.hostname=myapp.docker.local`
3. Service adds `127.0.0.1 myapp.docker.local` to /etc/hosts
4. Container stops → entry removed
5. Traefik routes traffic based on Host header

**DNS with SOCKS5:**
When using SOCKS5, browser traffic goes through proxy container which has access to Docker's internal DNS:
- `app.docker.local` → resolved by Docker DNS to container IP
- `traefik_docker_local` → resolved by Docker DNS
- No host DNS configuration needed
- Works immediately after enabling SOCKS5

### 2. SSL Certificate Management

**Decision: Self-signed CA with persistent storage**

**Rationale:**
- Local development doesn't need public CA
- Self-signed gives full control and no external dependencies
- Persistent volume survives container recreation
- One-time CA import to system trust store

**Certificate Structure:**
```
proxy_certs/
├── ca.crt              # Root CA certificate (user imports this)
├── ca.key              # Root CA private key
├── docker.local.crt    # Wildcard cert for *.docker.local
└── docker.local.key    # Private key for wildcard cert
```

**Generation Strategy:**
1. Check if certificates exist in volume
2. If not, generate:
   - Root CA (10 year validity)
   - Wildcard certificate for *.docker.local (1 year validity)
   - Save to volume
3. Configure Traefik to use generated certificates

**Alternative Considered:**
- mkcert: Too opinionated, requires installation on host
- certbot: Overkill for local development
- Per-service certs: More complex, wildcard simpler

### 3. SOCKS5 Proxy

**Decision: Optional, disabled by default**

**Rationale:**
- Advanced feature not needed by most users
- Adds complexity and attack surface
- Enables browser to access Docker network directly using container DNS names
- Can be enabled via environment variable

**How it works:**
When browser is configured to use SOCKS5 proxy (127.0.0.1:1080):
1. Browser sends request to app.docker.local through SOCKS5
2. SOCKS5 (gost) running inside proxy container receives request
3. gost has access to dc_shared_net Docker network
4. gost resolves app.docker.local using Docker's DNS
5. Request goes to Traefik container → nginx container
6. Response flows back: nginx → Traefik → gost → browser

**Key benefit:** Browser can use Docker internal DNS names and IPs directly, no port mapping needed

**Implementation:**
- Use `gost` (lightweight, Go-based)
- Enable via `DC_PROXY_SOCKS5_ENABLED=1`
- Bind to 127.0.0.1:1080 by default
- gost runs inside proxy container with access to dc_shared_net
- Document use cases (browser proxy, curl --socks5, database clients)

**Alternatives:**
- microsocks: Even lighter but less features
- dante: Full-featured but heavyweight
- ssh -D: Already possible but not integrated

### 4. Simplified Proxy Container

**Decision: Traefik + Optional SOCKS5 in single container**

**Rationale:**
- DNS now handled by external daemon (orodc-dns-sync), not in container
- Only Traefik and optional SOCKS5 in container
- Simpler than before: no dnsmasq, no DNS server complexity
- SOCKS5 and Traefik are lightweight, can share container

**Trade-offs:**
| Approach | Pros | Cons |
|----------|------|------|
| Traefik + SOCKS5 (chosen) | Simple, no DNS complexity | Multi-process needed for SOCKS5 |
| Separate containers | Pure Docker best practice | Overkill for optional SOCKS5 |

## Process Manager Selection

For managing Traefik + socks5 processes, we need to choose a process manager:

| Manager | Size | Pros | Cons | Verdict |
|---------|------|------|------|---------|
| **s6-overlay v3** | **~2-3MB** | ✅ Lightweight, Docker-native, active support, proper signals | execlineb syntax | ✅ **BEST** |
| ochinchina/supervisord | ~10-15MB | Easy INI config, Web GUI | **Unmaintained** (last update 2021) | ❌ Outdated |
| Python supervisord | ~50MB | Well-known, standard | Heavy (Python deps), 50MB | ❌ Too heavy |
| tini + bash | ~100KB | Minimal | No auto-restart, manual | ❌ Too manual |
| bash only | 0 | No deps | No supervision | ❌ Unreliable |

**Decision: Use [s6-overlay v3](https://github.com/just-containers/s6-overlay)**

**Rationale:**
- **Lightweight**: Only ~2-3MB vs 10-15MB ochinchina/supervisord
- **Actively maintained**: Regular updates, v3 is modern
- **Docker-first design**: Built specifically for containers
- **Proper signal handling**: Graceful shutdown (SIGTERM)
- **Auto-restart**: Process supervision and automatic restarts
- **No runtime deps**: Static binaries, no scripting language runtime
- **Popular**: Used by linuxserver.io and many production containers
- **Simple services**: Despite execlineb, service definitions are straightforward

**Why not ochinchina/supervisord:**
- ❌ **Last release 2021** (v0.7.3) - unmaintained for 3+ years
- ❌ No active development or security updates
- s6-overlay is smaller AND actively maintained

**Implementation:**
- Custom Dockerfile starts from `alpine:latest`
- Download Traefik v3 latest from GitHub releases (~50-60MB)
- Install s6-overlay v3 (~2-3MB)
- Copy SOCKS5 from serjs/go-socks5-proxy (~2-3MB)
- Simple s6 service definitions (run scripts)
- Multi-arch support (amd64, arm64)
- Entrypoint: certificate generation + s6-overlay init

### 5. Backward Compatibility

**Decision: Keep HTTP, add HTTPS**

**Rationale:**
- Existing users depend on port 8880
- HTTPS adds value but shouldn't break existing setups
- Users can migrate gradually

**Ports:**
- 8880: HTTP (existing, unchanged)
- 8443: HTTPS (new)
- 1080: SOCKS5 (new, optional, disabled by default)

**Environment Variables:**
```bash
TRAEFIK_BIND_PORT=8880              # HTTP port (backward compat)
TRAEFIK_HTTPS_BIND_PORT=8443        # HTTPS port (new)
DC_PROXY_SOCKS5_ENABLED=0           # SOCKS5 disabled by default
DC_PROXY_SOCKS5_PORT=1080           # SOCKS5 port
```

## Component Design

### Proxy Container (Clean Build from Alpine)

**Base Image:** `alpine:latest` (clean Alpine Linux base)

**Downloaded Components:**
- **Traefik v3** (~50-60MB) - Latest version from GitHub releases
- **s6-overlay v3** (~2-3MB) - Container-native process supervision
- **socks5** (~2-3MB) - From serjs/go-socks5-proxy Docker image
- **Alpine packages:** `ca-certificates`, `bash`, `openssl`

**File Structure:**
```
compose/docker/proxy/
├── Dockerfile                 # Multi-stage build
├── traefik.yml                # Traefik v3 static config
├── localCA.cnf                # OpenSSL CA configuration
├── local-ca-init.sh           # Initialize CA structure
├── local-ca-crtgen.sh         # Generate domain certificates
├── generate-certs.sh          # Main certificate wrapper
└── s6-rc.d/                   # s6-overlay service definitions
    ├── init-certs/            # One-shot: Generate certificates on first start
    │   ├── type               # "oneshot"
    │   └── up                 # Execute generate-certs.sh
    ├── traefik/               # Long-run: Traefik process
    │   ├── type               # "longrun"
    │   ├── run                # Start Traefik
    │   └── dependencies.d/
    │       └── init-certs     # Wait for certs
    └── socks5/                # Long-run: SOCKS5 (optional, enabled via env)
        ├── type               # "longrun"
        ├── run                # Start socks5
        └── dependencies.d/
            └── traefik        # Wait for Traefik

# Inside container after build:
/certs/                        # Volume mount point
  ├── localCA.cnf             # OpenSSL config (copied at runtime)
  └── localCA/                # CA structure (created by local-ca-init.sh)
      ├── certs/              # Issued certificates
      ├── newcerts/           # Certificate copies (by serial)
      ├── crl/                # Certificate revocation lists
      ├── private/            # Private keys
      ├── root_ca.crt         # Root CA certificate
      ├── serial              # Next serial number
      ├── index.txt           # Certificate database
      └── index.txt.attr      # Database attributes
```

### DNS Sync Service (External, runs on host)

**Base:** Shell script with Docker API

**File Structure:**
```
bin/
├── orodc                      # Updated with DNS sync commands
└── orodc-dns-sync             # Daemon script

# Linux
/etc/systemd/system/orodc-dns-sync.service

# macOS
/Library/LaunchDaemons/com.orodc.dns-sync.plist
```

**Functionality:**
- Watches Docker events API
- Detects containers with `orodc.dns.hostname` label
- Updates /etc/hosts atomically
- Manages entries between markers

### Certificate Generation Scripts (Based on digitalspace-local-ca approach)

Inspired by [digitalspace-local-ca](https://github.com/digitalspacestdio/homebrew-ngdev/blob/main/Formula/digitalspace-local-ca.rb), we implement a proper CA structure with separate initialization and certificate generation scripts.

**Script Structure:**
```
compose/docker/proxy/
├── local-ca-init.sh         # Initialize CA structure (run once)
├── local-ca-crtgen.sh       # Generate domain certificates
├── localCA.cnf              # OpenSSL CA configuration
└── generate-certs.sh        # Wrapper that calls init + crtgen
```

#### Script 1: local-ca-init.sh

Initializes the CA directory structure and generates root CA certificate.

```bash
#!/bin/bash
# local-ca-init.sh
set -e

CERT_DIR="/certs"
CA_DIR="$CERT_DIR/localCA"

export OPENSSL_CONF="$CERT_DIR/localCA.cnf"

echo "[INFO] Initializing Local CA structure..."

# Create CA directory structure
mkdir -p "$CA_DIR/certs"
mkdir -p "$CA_DIR/newcerts"
mkdir -p "$CA_DIR/crl"
mkdir -p "$CA_DIR/private"

# Initialize CA database files
echo "01" > "$CA_DIR/serial"
echo "unique_subject = no" > "$CA_DIR/index.txt.attr"
echo -n "" > "$CA_DIR/index.txt"

# Generate Root CA certificate (10 years validity)
openssl req -x509 -sha256 -newkey rsa:2048 -nodes -days 3650 \
    -keyout "$CA_DIR/private/cakey.pem" \
    -out "$CA_DIR/root_ca.crt" \
    -subj "/C=US/ST=Local/L=Local/O=OroDC/OU=Development/CN=OroDC Local CA/emailAddress=root@localhost"

chmod 600 "$CA_DIR/private/cakey.pem"

echo "[INFO] Root CA certificate generated:"
echo "  Certificate: $CA_DIR/root_ca.crt"
echo "  Private Key: $CA_DIR/private/cakey.pem"
```

#### Script 2: local-ca-crtgen.sh

Generates wildcard certificates for specified domains using the CA.

```bash
#!/bin/bash
# local-ca-crtgen.sh
set -e

if [[ -z $1 ]]; then
    echo "Usage: $0 <domain>"
    echo "Example: $0 docker.local"
    exit 1
fi

CERT_DIR="/certs"
CA_DIR="$CERT_DIR/localCA"
DOMAIN="$1"

# Sanitize domain name
DOMAIN_SAFE=$(echo "$DOMAIN" | sed -e 's/[^A-Za-z0-9._-]/_/g')

if [[ "$DOMAIN_SAFE" != "$DOMAIN" ]]; then
    echo "[ERROR] Invalid domain name: $DOMAIN"
    exit 1
fi

echo "[INFO] Generating certificate for *.${DOMAIN}..."

# Create domain-specific OpenSSL config
cat > "$CA_DIR/${DOMAIN}.cnf" <<EOM
[ req ]
prompt = no
distinguished_name = server_distinguished_name
req_extensions = v3_req

[ server_distinguished_name ]
commonName = *.${DOMAIN}
stateOrProvinceName = Local
countryName = US
emailAddress = root@${DOMAIN}
organizationName = OroDC
organizationalUnitName = Development

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[ alt_names ]
DNS.0 = *.${DOMAIN}
DNS.1 = ${DOMAIN}
EOM

# Generate private key and certificate request
export OPENSSL_CONF="$CA_DIR/${DOMAIN}.cnf"
openssl req -newkey rsa:2048 \
    -keyout "$CA_DIR/private/${DOMAIN}_key.pem" \
    -keyform PEM \
    -out "$CA_DIR/${DOMAIN}_req.pem" \
    -outform PEM \
    -nodes

# Extract clean key (without extra headers)
openssl rsa < "$CA_DIR/private/${DOMAIN}_key.pem" > "$CA_DIR/private/${DOMAIN}.key"
chmod 600 "$CA_DIR/private/${DOMAIN}.key"

# Sign certificate with CA
export OPENSSL_CONF="$CERT_DIR/localCA.cnf"
openssl ca -batch \
    -in "$CA_DIR/${DOMAIN}_req.pem" \
    -out "$CA_DIR/certs/${DOMAIN}.crt"

# Cleanup temporary files
rm -f "$CA_DIR/${DOMAIN}_req.pem"
rm -f "$CA_DIR/private/${DOMAIN}_key.pem"

echo "[INFO] Certificate generated successfully:"
echo "  Certificate: $CA_DIR/certs/${DOMAIN}.crt"
echo "  Private Key: $CA_DIR/private/${DOMAIN}.key"

# Create symlinks in /certs root for Traefik compatibility
ln -sf "$CA_DIR/root_ca.crt" "$CERT_DIR/ca.crt"
ln -sf "$CA_DIR/private/cakey.pem" "$CERT_DIR/ca.key"
ln -sf "$CA_DIR/certs/${DOMAIN}.crt" "$CERT_DIR/${DOMAIN}.crt"
ln -sf "$CA_DIR/private/${DOMAIN}.key" "$CERT_DIR/${DOMAIN}.key"
```

#### Script 3: localCA.cnf

OpenSSL configuration for CA operations.

```ini
# localCA.cnf - OpenSSL CA configuration for OroDC

[ ca ]
default_ca = local_ca

[ local_ca ]
dir             = /certs/localCA
certs           = $dir/certs
crl_dir         = $dir/crl
database        = $dir/index.txt
new_certs_dir   = $dir/newcerts
certificate     = $dir/root_ca.crt
crlnumber       = $dir/crlnumber
private_key     = $dir/private/cakey.pem
serial          = $dir/serial

default_crl_days = 365
default_days     = 398
default_md       = sha256

policy            = local_ca_policy
x509_extensions   = local_ca_extensions
copy_extensions   = copy

[ local_ca_policy ]
commonName             = supplied
stateOrProvinceName    = supplied
countryName            = supplied
emailAddress           = supplied
organizationName       = supplied
organizationalUnitName = supplied

[ local_ca_extensions ]
basicConstraints = CA:false
keyUsage = nonRepudiation, digitalSignature, keyEncipherment

[ req ]
default_bits    = 2048
default_keyfile = /certs/localCA/private/cakey.pem
default_md      = sha256
prompt          = no
distinguished_name = root_ca_distinguished_name
x509_extensions    = root_ca_extensions

[ root_ca_distinguished_name ]
commonName             = OroDC Local CA
stateOrProvinceName    = Local
countryName            = US
emailAddress           = root@localhost
organizationName       = OroDC
organizationalUnitName = Development

[ root_ca_extensions ]
basicConstraints = CA:true
keyUsage = keyCertSign, cRLSign
```

#### Script 4: generate-certs.sh

Main wrapper script called by s6-overlay to ensure certificates exist.

```bash
#!/bin/bash
# generate-certs.sh - Main entrypoint for certificate generation
set -e

CERT_DIR="/certs"
CA_DIR="$CERT_DIR/localCA"
DOMAIN="${CERT_DOMAIN:-docker.local}"

echo "[INFO] Certificate Generation for OroDC Proxy"
echo "[INFO] Domain: ${DOMAIN}"

# Check if CA already exists
if [[ -f "$CA_DIR/root_ca.crt" ]] && [[ -f "$CERT_DIR/${DOMAIN}.crt" ]]; then
    echo "[INFO] Certificates already exist, skipping generation"
    exit 0
fi

# Copy OpenSSL config to certs directory
cp /usr/local/etc/localCA.cnf "$CERT_DIR/localCA.cnf"

# Initialize CA if not exists
if [[ ! -f "$CA_DIR/root_ca.crt" ]]; then
    echo "[INFO] Initializing Certificate Authority..."
    /usr/local/bin/local-ca-init.sh
fi

# Generate domain certificate if not exists
if [[ ! -f "$CERT_DIR/${DOMAIN}.crt" ]]; then
    echo "[INFO] Generating certificate for *.${DOMAIN}..."
    /usr/local/bin/local-ca-crtgen.sh "${DOMAIN}"
fi

echo "[INFO] Certificate setup complete"
echo "[INFO] Root CA: $CERT_DIR/ca.crt"
echo "[INFO] Domain cert: $CERT_DIR/${DOMAIN}.crt"
echo "[INFO] Domain key: $CERT_DIR/${DOMAIN}.key"
```

**Benefits of this approach:**
- ✅ **Proper CA structure**: Industry-standard CA directory layout
- ✅ **Certificate tracking**: index.txt tracks all issued certificates
- ✅ **Reusable CA**: Can generate multiple domain certificates from same CA
- ✅ **Standard OpenSSL**: Uses well-documented OpenSSL CA features
- ✅ **Auditable**: Serial numbers and database for certificate management
- ✅ **Extensible**: Easy to add new domains or regenerate certificates

### Traefik v3 Configuration

**Static Configuration (traefik.yml):**
```yaml
# Traefik v3 configuration
global:
  checkNewVersion: false
  sendAnonymousUsage: false

# Entry points
entryPoints:
  http:
    address: ":80"
    # Optional: HTTP to HTTPS redirect
    # http:
    #   redirections:
    #     entryPoint:
    #       to: https
    #       scheme: https
  
  https:
    address: ":443"
    http:
      tls:
        # Default certificate for *.docker.local
        certificates:
          - certFile: /certs/docker.local.crt
            keyFile: /certs/docker.local.key

# API and Dashboard
api:
  dashboard: true
  insecure: false  # Access via Traefik routing, not separate port

# Ping endpoint for health checks
ping:
  entryPoint: http

# Providers
providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
    network: "dc_shared_net"

# Logging
log:
  level: INFO
  format: common

# Access logs (optional)
# accessLog:
#   format: common
```

**Key changes in Traefik v3:**
- ✅ Better structured configuration
- ✅ `ping` section for health checks
- ✅ Improved TLS configuration
- ✅ More granular control over providers

### DNS Configuration via Auto /etc/hosts Sync

**orodc-dns-sync Service:**

This service watches Docker events and automatically updates /etc/hosts when containers start/stop.

**Script: `bin/orodc-dns-sync`**
```bash
#!/bin/bash
# Watches Docker events and updates /etc/hosts

HOSTS_FILE="/etc/hosts"
MARKER_START="# OroDC Auto DNS - START"
MARKER_END="# OroDC Auto DNS - END"

update_hosts() {
    # Get all containers with orodc.dns.hostname label
    entries=$(docker ps --format '{{.ID}}' | while read container_id; do
        hostname=$(docker inspect -f '{{index .Config.Labels "orodc.dns.hostname"}}' "$container_id" 2>/dev/null)
        if [[ -n "$hostname" ]]; then
            echo "127.0.0.1 $hostname"
        fi
    done)
    
    # Update /etc/hosts atomically
    sudo sed -i "/$MARKER_START/,/$MARKER_END/d" "$HOSTS_FILE"
    echo "$MARKER_START" | sudo tee -a "$HOSTS_FILE" > /dev/null
    echo "$entries" | sudo tee -a "$HOSTS_FILE" > /dev/null
    echo "$MARKER_END" | sudo tee -a "$HOSTS_FILE" > /dev/null
}

# Initial sync
update_hosts

# Watch Docker events
docker events --filter 'type=container' --format '{{.Status}}' | while read status; do
    if [[ "$status" == "start" || "$status" == "stop" || "$status" == "die" ]]; then
        update_hosts
    fi
done
```

**Systemd Service: `/etc/systemd/system/orodc-dns-sync.service`**
```ini
[Unit]
Description=OroDC DNS Sync - Auto update /etc/hosts for Docker containers
After=docker.service
Requires=docker.service

[Service]
Type=simple
ExecStart=/usr/local/bin/orodc-dns-sync
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

**macOS LaunchDaemon: `/Library/LaunchDaemons/com.orodc.dns-sync.plist`**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.orodc.dns-sync</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/orodc-dns-sync</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
```

**Container Labels in docker-compose.yml:**
```yaml
services:
  nginx:
    image: nginx
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myapp.rule=Host(`myapp.docker.local`)"
      - "orodc.dns.hostname=myapp.docker.local"  # Auto /etc/hosts sync
```

**Benefits of Bash Script Approach:**
- No DNS server software required
- No port conflicts (no port 53)
- Works with standard /etc/hosts mechanism
- Simple to debug (just check /etc/hosts file)
- Fast: no DNS lookup overhead
- Compatible with all tools and applications

### Ready-to-use SOCKS5 Server

Using pre-built binary from [serjs/go-socks5-proxy](https://hub.docker.com/r/serjs/go-socks5-proxy) Docker image.

**Why use pre-built image:**
- ✅ **Zero compilation:** Just copy binary from official image
- ✅ **Always up-to-date:** Use `latest` tag or pin specific version
- ✅ **Tiny size:** ~2-3MB static binary at `/socks5`
- ✅ **Verified build:** Official image from maintainer
- ✅ **No build dependencies:** No Go compiler, no git clone needed

**Configuration via environment variables:**
```bash
# Binary from serjs/go-socks5-proxy image (in Dockerfile)
COPY --from=serjs/go-socks5-proxy:latest /socks5 /usr/local/bin/socks5

# Environment variable for socks5 binary
# SOCKS_ADDR controls bind address and port
export SOCKS_ADDR="127.0.0.1:1080"
```

**Benefits:**
- ✅ **Fastest build:** No compilation step, just copy binary
- ✅ **Reliable:** Official pre-built binary
- ✅ **Simple:** Minimal configuration via env vars
- ✅ **No auth overhead:** Perfect for internal Docker network
- ✅ **Logging:** Outputs to stdout (s6-overlay captures)
- ✅ **Multi-arch:** Available for amd64 and arm64

**Dockerfile for clean Alpine build with Traefik v3 + s6-overlay:**
```dockerfile
# Stage 1: Copy SOCKS5 binary from ready-made image
FROM serjs/go-socks5-proxy:latest AS socks5-binary

# Stage 2: Final image
FROM alpine:latest

# Install system dependencies
RUN apk add --no-cache \
    ca-certificates \
    bash \
    openssl \
    curl \
    tzdata \
    xz

# Set architecture variables for multi-arch support
ARG TARGETARCH
ENV ARCH=${TARGETARCH:-amd64}

# Download Traefik v3 (latest)
RUN TRAEFIK_VERSION=$(curl -s https://api.github.com/repos/traefik/traefik/releases/latest | grep tag_name | cut -d '"' -f 4) && \
    wget -O /tmp/traefik.tar.gz \
    "https://github.com/traefik/traefik/releases/download/${TRAEFIK_VERSION}/traefik_${TRAEFIK_VERSION}_linux_${ARCH}.tar.gz" && \
    tar -xzf /tmp/traefik.tar.gz -C /usr/local/bin && \
    chmod +x /usr/local/bin/traefik && \
    rm /tmp/traefik.tar.gz

# Install s6-overlay v3
ARG S6_OVERLAY_VERSION=3.1.6.2
RUN case ${TARGETARCH} in \
        "amd64")  S6_ARCH=x86_64  ;; \
        "arm64")  S6_ARCH=aarch64 ;; \
        *)        S6_ARCH=x86_64  ;; \
    esac && \
    wget -O /tmp/s6-overlay-noarch.tar.xz \
        "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" && \
    wget -O /tmp/s6-overlay-arch.tar.xz \
        "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.xz" && \
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-arch.tar.xz && \
    rm /tmp/s6-overlay-*.tar.xz

# Copy pre-built SOCKS5 binary from serjs/go-socks5-proxy image
COPY --from=socks5-binary /socks5 /usr/local/bin/socks5
RUN chmod +x /usr/local/bin/socks5

# Create directories
RUN mkdir -p /certs /etc/traefik /usr/local/etc

# Copy CA configuration and certificate generation scripts
COPY localCA.cnf /usr/local/etc/localCA.cnf
COPY local-ca-init.sh /usr/local/bin/local-ca-init.sh
COPY local-ca-crtgen.sh /usr/local/bin/local-ca-crtgen.sh
COPY generate-certs.sh /usr/local/bin/generate-certs.sh
RUN chmod +x /usr/local/bin/*.sh

# Copy Traefik configuration and s6 service definitions
COPY traefik.yml /etc/traefik/traefik.yml
COPY s6-rc.d/ /etc/s6-overlay/s6-rc.d/

# Expose ports
EXPOSE 80 443

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD traefik healthcheck --ping || exit 1

# s6-overlay as init system (PID 1)
ENTRYPOINT ["/init"]
```

**Key improvements with pre-built binary:**
- ✅ **Fastest build:** No Go compilation, just copy pre-built binary
- ✅ **Official binary:** From serjs/go-socks5-proxy Docker Hub
- ✅ **Smaller binary:** ~2-3MB static binary with stripped symbols
- ✅ **Multi-arch ready:** Official images support amd64 and arm64
- ✅ **Always current:** Use `latest` tag or pin specific version
- ✅ **Zero dependencies:** No Go compiler, git, or build tools needed
- ✅ **Faster CI/CD:** Significantly faster Docker builds

**Key improvements with Alpine base:**
- ✅ Always latest Traefik v3 (fetched from GitHub releases)
- ✅ Multi-arch support (amd64, arm64) via TARGETARCH
- ✅ Full control over all components and versions
- ✅ Clean, reproducible build
- ✅ Smaller base image (~5MB Alpine vs ~40MB Traefik image)
- ✅ Easy to update any component independently

**Web GUI Access:**
- Built-in web interface on http://localhost:9001
- Start/stop/restart processes via web UI
- View process logs in real-time
- Prometheus metrics on http://localhost:9001/metrics

## Security Considerations

1. **Self-signed CA**: Private key must stay in volume, never committed
2. **SOCKS5 Proxy**: Bind to localhost only, no external access
3. **DNS Port 53**: Requires privileges, document security implications
4. **Certificate Export**: User must manually trust CA, document risks
5. **Volume Permissions**: Certificates must be readable only by root/docker

## Testing Strategy

1. **Unit Tests**: Certificate generation script
2. **Integration Tests**: 
   - Start proxy, verify HTTPS endpoint
   - Export cert, verify format
   - DNS resolution (if enabled)
   - SOCKS5 connectivity (if enabled)
3. **Manual Tests**:
   - Browser certificate trust workflow
   - DNS configuration per OS
   - Multi-project isolation

## Migration Path

For existing users:
1. `orodc install-proxy` continues working (HTTP only)
2. Documentation explains HTTPS upgrade benefits
3. `orodc install-proxy --with-https` enables new mode
4. User runs `orodc export-proxy-cert` and imports CA
5. User configures DNS (guided by `orodc proxy-dns-setup`)

## Performance Implications

- Additional services: +50-100MB memory
- DNS lookups: minimal overhead
- SSL termination: negligible for local development
- Volume I/O: one-time cert generation, then cached

## Alternatives Considered

### Alternative 1: Separate Proxy Service

Use Caddy instead of Traefik
- Caddy has automatic HTTPS built-in
- But requires different Docker label syntax
- Breaking change for existing users
- Still needs /etc/hosts sync for DNS

### Alternative 2: No DNS Solution

Document manual /etc/hosts management
- Simpler implementation
- But worse developer experience

### Alternative 3: Use mkcert

Integrate mkcert for certificate management
- Better trust store integration
- But adds host dependency
- Doesn't work in CI/containerized environments

## Open Issues

1. **Windows Support**: DNS configuration on Windows differs significantly
2. **Docker Desktop**: Port binding behavior varies by platform
3. **M1/ARM64**: Ensure all components work on ARM architecture
4. **Certificate Expiry**: No automatic renewal, 1-year validity sufficient?

## Future Enhancements

- Automatic certificate renewal
- HTTP/2 and HTTP/3 support
- Custom domain support beyond .docker.local
- Integration with external DNS services
- mDNS/Avahi support for true zero-config

