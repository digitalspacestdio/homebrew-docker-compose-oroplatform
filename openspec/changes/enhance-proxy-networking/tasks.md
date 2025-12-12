# Tasks: Enhance Proxy Networking

**Change ID:** enhance-proxy-networking

## Task Sequencing

Tasks are organized in phases to enable incremental delivery and testing. Tasks within a phase can be parallelized where indicated.

---

## Phase 1: Foundation & Certificate Management

### Task 1.1: Create Enhanced Proxy Dockerfile ✓ FOUNDATIONAL

**Description:** Create new Dockerfile for multi-service proxy container

**Work Items:**
- Create `compose/docker/proxy/Dockerfile` with multi-stage build
- Stage 1: Copy pre-built SOCKS5 binary from official image
  - Base: `serjs/go-socks5-proxy:latest`
  - Binary already compiled at `/socks5` path
  - No compilation needed, just reference for COPY
- Stage 2 (final): Clean Alpine image
  - Base image: `alpine:latest`
  - Download Traefik v3 latest binary: https://github.com/traefik/traefik/releases
  - Install s6-overlay v3 (~2-3MB): https://github.com/just-containers/s6-overlay
  - Copy pre-built `/socks5` binary from stage 1
  - Install Alpine packages: `ca-certificates`, `bash`, `openssl`, `xz`
  - Set up directory structure: `/certs`, `/etc/traefik`, `/etc/s6-overlay/s6-rc.d/`
  - Copy certificate generation scripts to `/usr/local/bin/`:
    - `local-ca-init.sh`
    - `local-ca-crtgen.sh`
    - `generate-certs.sh`
  - Copy OpenSSL CA config to `/usr/local/etc/`:
    - `localCA.cnf`
  - Copy traefik.yml to `/etc/traefik/`
  - Copy s6 service definitions to `/etc/s6-overlay/s6-rc.d/`
  - Make all scripts executable (chmod +x)
- Keep image minimal - all components as static binaries

**Validation:**
- Dockerfile builds successfully: `docker build -t orodc-proxy compose/docker/proxy/`
- Required binaries present and executable: `traefik`, `socks5`, `openssl`, `/init` (s6)
- `traefik version` shows v3.x
- `/usr/local/bin/socks5` is executable
- s6-overlay installed: `/init`, `/command/`, `/etc/s6-overlay/` directories exist
- Image size reasonable (~105-125MB: Alpine + Traefik v3 + s6-overlay ~2-3MB + socks5 ~2-3MB)
- Multi-arch support (amd64, arm64) via official images
- Build is faster (no Go compilation step for SOCKS5)

**Dependencies:** None

---

### Task 1.2: Certificate Generation Scripts (Based on digitalspace-local-ca) ✓ FOUNDATIONAL

**Description:** Implement proper CA structure with separate initialization and certificate generation scripts

**Work Items:**
- Create `compose/docker/proxy/localCA.cnf` - OpenSSL CA configuration:
  - CA directory structure definition: `/certs/localCA/{certs,newcerts,crl,private}`
  - CA policy for certificate signing
  - Extensions for CA and server certificates
  - Distinguished name templates
  - Serial and index.txt database configuration
- Create `compose/docker/proxy/local-ca-init.sh` - CA initialization:
  - Create directory structure: `localCA/{certs,newcerts,crl,private}`
  - Initialize CA database files: `serial`, `index.txt`, `index.txt.attr`
  - Generate Root CA certificate: 10-year validity, RSA 2048
  - Set proper permissions (600 for private keys)
  - Use OPENSSL_CONF environment variable
- Create `compose/docker/proxy/local-ca-crtgen.sh` - Domain certificate generation:
  - Accept domain name as parameter
  - Sanitize domain name (alphanumeric, dots, hyphens only)
  - Create domain-specific OpenSSL config with SAN
  - Generate private key and CSR
  - Sign CSR with Root CA using `openssl ca`
  - Clean up temporary files
  - Create symlinks in `/certs` root for Traefik compatibility
  - Log all generation steps
- Create `compose/docker/proxy/generate-certs.sh` - Main wrapper:
  - Check if certificates already exist
  - Copy localCA.cnf to `/certs` directory
  - Call `local-ca-init.sh` if CA doesn't exist
  - Call `local-ca-crtgen.sh docker.local` if domain cert doesn't exist
  - Support `CERT_DOMAIN` environment variable (default: docker.local)
  - Exit early if certificates exist (idempotent)

**Validation:**
- All scripts are executable and use `#!/bin/bash` shebang
- CA initialization creates proper directory structure
- `ls -la /certs/localCA/` shows: certs/, newcerts/, crl/, private/, serial, index.txt
- Root CA generated: `openssl x509 -in /certs/localCA/root_ca.crt -text -noout` shows CA:true
- Domain cert generated: `openssl x509 -in /certs/docker.local.crt -text -noout` shows SAN
- Symlinks created: `/certs/ca.crt -> localCA/root_ca.crt`
- Private keys have 600 permissions
- Scripts are idempotent (skip if certs exist)
- Can generate multiple domains: `local-ca-crtgen.sh example.docker.local`

**Dependencies:** Task 1.1

---

### Task 1.3: Container Entrypoint Script ✓ FOUNDATIONAL

**Description:** Create entrypoint that orchestrates service startup

**Work Items:**
- Certificate generation handled by s6-overlay oneshot service (init-certs)
- No separate entrypoint.sh needed - s6-overlay manages initialization
- Traefik configuration static (traefik.yml)
- s6-overlay services control startup order via dependencies
- `DC_PROXY_SOCKS5_ENABLED` env var checked in socks5 run script
- s6-overlay as PID 1 (/init) handles all process management
- s6-overlay handles signals (SIGTERM, SIGINT) gracefully

**Validation:**
- Container starts successfully with s6-overlay
- Certificates are generated on first run (init-certs oneshot)
- s6-overlay starts Traefik correctly (longrun service)
- `docker logs` show clear startup sequence with s6 logs
- `docker stop` performs graceful shutdown via s6-overlay
- `s6-rc -a list` (inside container) shows running services
- SOCKS5 service starts only when DC_PROXY_SOCKS5_ENABLED=1

**Dependencies:** Task 1.2

---

### Task 1.4: Traefik Configuration Template ✓ FOUNDATIONAL

**Description:** Create Traefik static configuration with TLS support

**Work Items:**
- Create `compose/docker/proxy/traefik.yml.template`
- Configure HTTP entrypoint on :80
- Configure HTTPS entrypoint on :443 with TLS
- Load certificates from `/certs/docker.local.{crt,key}`
- Enable Docker provider with label-based routing
- Enable API and dashboard
- Configure log level from env var
- Set trusted IPs for forwarded headers

**Validation:**
- Template renders correctly with test values
- Traefik starts with generated config
- `curl http://localhost:8880/api/rawdata` returns Traefik config
- TLS configuration present in API output

**Dependencies:** Task 1.2

---

### Task 1.5: s6-overlay Service Definitions ✓ FOUNDATIONAL

**Description:** Create s6-overlay service definitions for all processes

**Work Items:**
- Create `s6-rc.d/init-certs/` oneshot service:
  - `type` file contains "oneshot"
  - `up` script executes generate-certs.sh
  - Runs once on container start
- Create `s6-rc.d/traefik/` longrun service:
  - `type` file contains "longrun"
  - `run` script starts Traefik with config
  - `dependencies.d/init-certs` ensures certs exist first
  - Logs to stdout (captured by Docker)
- Create `s6-rc.d/socks5/` longrun service:
  - `type` file contains "longrun"
  - `run` script checks `DC_PROXY_SOCKS5_ENABLED` env var
  - If disabled, service stops itself via `s6-svc -d`
  - If enabled, starts socks5 with SOCKS_ADDR env var
  - `dependencies.d/traefik` ensures Traefik starts first
  - Logs to stdout (captured by Docker)
- All run scripts use `#!/command/with-contenv bash` shebang
- All run scripts use `exec` to replace shell with process

**Validation:**
- `s6-rc -a list` shows all services inside container
- Service logs appear in `docker logs traefik_docker_local`
- Killing a process triggers auto-restart by s6-overlay
- socks5 service only runs when `DC_PROXY_SOCKS5_ENABLED=1`
- Graceful shutdown on `docker stop` (s6-overlay handles SIGTERM)
- init-certs runs once, then traefik starts, then socks5 (if enabled)

**Dependencies:** Task 1.2

---

### Task 1.6: Update docker-compose-proxy.yml ✓ FOUNDATIONAL

**Description:** Update compose file for enhanced proxy

**Work Items:**
- Modify `compose/docker-compose-proxy.yml`
- Change image to custom build: `build: ./docker/proxy`
- Add named volume: `proxy_certs:/certs`
- Add HTTPS port: `${TRAEFIK_HTTPS_BIND_PORT:-8443}:443`
- Add DNS port: `${DC_PROXY_DNS_PORT:-8853}:53/udp` (conditional)
- Add SOCKS5 port: `${DC_PROXY_SOCKS5_PORT:-1080}:1080` (conditional)
- Add environment variables for feature toggles
- Update healthcheck to verify all enabled services
- Keep backward compatibility with existing env vars

**Validation:**
- `docker-compose -f compose/docker-compose-proxy.yml config` validates
- Ports are correctly mapped based on env vars
- Volume is created and persists across restarts
- Healthcheck passes when services are running

**Dependencies:** Task 1.1, Task 1.3, Task 1.4

---

### Task 1.7: Implement `orodc export-proxy-cert` Command

**Description:** Add command to export CA certificate

**Work Items:**
- Add command handler in `bin/orodc` after `install-proxy` section
- Check if proxy container is running
- Use `docker cp traefik_docker_local:/certs/ca.crt ~/orodc-proxy-ca.crt`
- Display exported certificate path
- Show OS-specific import instructions:
  - macOS: `sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ~/orodc-proxy-ca.crt`
  - Linux: Instructions for `update-ca-certificates`
  - Windows: Instructions for Certificate Manager
- Provide link to documentation for browser-specific import

**Validation:**
- Command exports certificate to correct location
- Certificate file is valid PEM format
- Instructions are displayed correctly
- Command fails gracefully if proxy not running

**Dependencies:** Task 1.6

---

### Task 1.8: Integration Test - HTTPS Endpoint

**Description:** Verify HTTPS endpoint works with generated certificates

**Work Items:**
- Create test script: `test-https-proxy.sh`
- Start proxy with `orodc install-proxy`
- Start test OroPlatform container with Traefik labels
- Wait for containers to be healthy
- Test HTTPS connection: `curl -k https://localhost:8443/`
- Verify certificate: `openssl s_client -connect localhost:8443 -servername test.docker.local`
- Check certificate issuer is OroDC-Local-CA
- Clean up test containers

**Validation:**
- HTTPS endpoint responds successfully
- Certificate is issued by OroDC-Local-CA
- Wildcard certificate covers *.docker.local
- HTTP endpoint (8880) still works

**Dependencies:** Task 1.7

---

## Phase 2: DNS Resolution via Auto /etc/hosts Sync

**Note:** These tasks can start after Phase 1 Task 1.6 is complete

### Task 2.1: Create orodc-dns-sync Script

**Description:** Create daemon script that watches Docker events and updates /etc/hosts

**Work Items:**
- Create `bin/orodc-dns-sync` script
- Watch Docker events API for container start/stop/die events
- Query containers for `orodc.dns.hostname` label
- Update /etc/hosts atomically between markers (`# OroDC Auto DNS - START/END`)
- Add logging for all DNS sync operations
- Handle edge cases: duplicate hostnames, invalid labels, permission errors
- Initial sync on startup for existing containers
- Graceful shutdown on SIGTERM/SIGINT

**Validation:**
- Script watches Docker events successfully
- /etc/hosts is updated when container with label starts
- /etc/hosts entry is removed when container stops
- No duplicate entries in /etc/hosts
- Markers correctly delimit OroDC entries
- Script handles permission errors gracefully

**Dependencies:** Task 1.6

---

### Task 2.2: Systemd Service Configuration (Linux)

**Description:** Create systemd service for orodc-dns-sync

**Work Items:**
- Create `/etc/systemd/system/orodc-dns-sync.service`
- Set dependencies: `After=docker.service`, `Requires=docker.service`
- Configure auto-restart on failure
- Set proper user permissions (needs sudo for /etc/hosts)
- Add logging to systemd journal
- Create install/uninstall commands in `orodc`

**Validation:**
- Service starts on boot
- Service restarts on failure
- Logs appear in `journalctl -u orodc-dns-sync`
- Service can be controlled with `systemctl start/stop/status`

**Dependencies:** Task 2.1

---

### Task 2.3: LaunchDaemon Configuration (macOS)

**Description:** Create launchd daemon for orodc-dns-sync

**Work Items:**
- Create `/Library/LaunchDaemons/com.orodc.dns-sync.plist`
- Configure `RunAtLoad` and `KeepAlive`
- Set proper permissions for plist file
- Add logging to system.log
- Create install/uninstall commands in `orodc`

**Validation:**
- Daemon starts on boot
- Daemon restarts on failure
- Logs appear in Console.app
- Daemon can be controlled with `launchctl load/unload`

**Dependencies:** Task 2.1

---

### Task 2.4: Implement `orodc proxy-dns-setup` Command

**Description:** Create installer/manager for DNS sync service

**Work Items:**
- Add command handler in `bin/orodc`
- Detect operating system: `uname -s`
- **Install mode** (`orodc proxy-dns-setup --install`):
  - Copy `orodc-dns-sync` to `/usr/local/bin/`
  - For Linux: Install systemd service, enable and start
  - For macOS: Install launchd daemon, load it
  - Configure sudo permissions if needed
  - Verify installation successful
- **Uninstall mode** (`orodc proxy-dns-setup --uninstall`):
  - Stop and disable service
  - Remove service files
  - Clean up /etc/hosts entries (between markers)
- **Status mode** (`orodc proxy-dns-setup --status`):
  - Check if service is running
  - Show /etc/hosts entries managed by OroDC
  - Show number of synced containers
- Add `--verify` flag to test DNS resolution via /etc/hosts
- Add helpful output messages for each step

**Validation:**
- Command detects OS correctly
- Service installs and starts successfully
- Service uninstalls cleanly
- Status shows accurate information
- `--verify` tests hostname resolution

**Dependencies:** Task 2.2, Task 2.3

---

### Task 2.5: Docker Label Documentation

**Description:** Document how to add DNS labels to containers

**Work Items:**
- Document `orodc.dns.hostname` label in README.md
- Show examples in docker-compose.yml:
  ```yaml
  labels:
    - "orodc.dns.hostname=myapp.docker.local"
  ```
- Explain automatic /etc/hosts sync
- Provide examples for `orodc` CLI usage
- Document multiple hostnames (comma-separated)
- Explain troubleshooting: check service status, check labels

**Validation:**
- Documentation is clear and includes examples
- Examples are copy-pasteable and work
- Covers common use cases

**Dependencies:** Task 2.4

---

### Task 2.6: Integration Test - Auto /etc/hosts Sync

**Description:** End-to-end test of auto DNS functionality

**Work Items:**
- Create test script: `test-auto-dns-sync.sh`
- Install DNS sync service
- Start test container with `orodc.dns.hostname=test.docker.local` label
- Verify /etc/hosts contains entry
- Test resolution: `ping test.docker.local`
- Stop container
- Verify /etc/hosts entry is removed
- Start proxy with Traefik
- Start app container with hostname label
- Test browser access: `curl http://app.docker.local:8880`
- Verify HTTPS: `curl -k https://app.docker.local:8443`

**Validation:**
- /etc/hosts updates automatically on container start/stop
- Hostnames resolve correctly
- Traefik routes traffic based on hostname
- HTTP and HTTPS both work
- Clean cleanup when container stops

**Dependencies:** Task 2.5

---

## Phase 3: SOCKS5 Proxy (Optional)

**Note:** These tasks are independent and can be done in parallel with Phase 2

### Task 3.1: SOCKS5 Service Configuration

**Description:** Configure s6-overlay service for SOCKS5 proxy

**Work Items:**
- SOCKS5 service already defined in Task 1.5 (s6-rc.d/socks5/)
- Implement conditional startup in `s6-rc.d/socks5/run` script:
  - Check `DC_PROXY_SOCKS5_ENABLED` env var (default: 0 or empty)
  - If not enabled (!=1), disable service with `s6-svc -d` and exit
  - If enabled, build SOCKS_ADDR from env vars
- Configure bind address from `DC_PROXY_SOCKS5_BIND` (default: 127.0.0.1)
- Configure port from `DC_PROXY_SOCKS5_PORT` (default: 1080)
- Set SOCKS_ADDR environment variable: `${BIND}:${PORT}`
- Log security warnings if binding to 0.0.0.0
- Export SOCKS_ADDR and exec socks5 binary

**Validation:**
- socks5 service starts when `DC_PROXY_SOCKS5_ENABLED=1`
- socks5 service doesn't start when `DC_PROXY_SOCKS5_ENABLED=0` (default)
- `s6-rc -a list` shows socks5 service status
- `curl --socks5 127.0.0.1:1080 http://example.com` works
- SOCKS_ADDR environment variable is correctly set

**Dependencies:** Task 1.6

---

### Task 3.2: SOCKS5 Docker Network Access

**Description:** Ensure SOCKS5 can route to Docker networks and containers using Docker DNS names

**Work Items:**
- Configure gost to run inside proxy container with dc_shared_net access
- Test connectivity using Docker DNS names: `curl --socks5 127.0.0.1:1080 http://traefik_docker_local`
- Test connectivity to app containers via Traefik: `curl --socks5 127.0.0.1:1080 http://app.docker.local`
- Verify Docker internal DNS resolution works through SOCKS5
- Document traffic flow: Browser → SOCKS5 (localhost:1080) → gost (in container) → Traefik → nginx
- Add examples for common use cases:
  - Browser proxy configuration for Docker network access
  - Database access via Docker DNS names (e.g., myapp_pgsql)
  - API testing with internal endpoints
  - Direct Traefik access without port mapping

**Validation:**
- Browser configured with SOCKS5 can access http://traefik_docker_local
- Browser configured with SOCKS5 can access http://app.docker.local (via Traefik)
- `curl --socks5 127.0.0.1:1080 http://myapp_cli` reaches container by DNS name
- Can connect to PostgreSQL via SOCKS5 using Docker DNS name (myapp_pgsql:5432)
- Docker internal DNS names resolve correctly through SOCKS5
- Traffic flows: host → SOCKS5 → gost (container) → Traefik (container) → app (container)
- No routing issues or timeouts

**Dependencies:** Task 3.1

---

### Task 3.3: Implement `orodc proxy-socks5-test` Command

**Description:** Create SOCKS5 connectivity test command

**Work Items:**
- Add command handler in `bin/orodc`
- Check if SOCKS5 is enabled
- Test TCP connection to SOCKS5 port
- Perform test HTTP request via SOCKS5
- Test container network access (if container running)
- Report results clearly
- Provide troubleshooting on failure

**Validation:**
- Command detects if SOCKS5 is disabled
- Command tests connectivity successfully
- Command detects connection failures
- Troubleshooting steps are helpful

**Dependencies:** Task 3.2

---

### Task 3.4: Implement `orodc proxy-status` Command

**Description:** Create status command showing all proxy features

**Work Items:**
- Add command handler in `bin/orodc`
- Check if proxy container is running
- Show HTTP/HTTPS endpoints and ports
- Show DNS status (enabled/disabled, port)
- Show SOCKS5 status (enabled/disabled, port, auth)
- Show certificate expiry dates
- Color-code output (green=ok, yellow=warning, red=error)
- Add health check status

**Validation:**
- Command shows all proxy features clearly
- Status is accurate for each feature
- Color coding helps readability
- Works when proxy is not running (shows error)

**Dependencies:** Task 3.3

---

### Task 3.5: SOCKS5 Documentation and Examples

**Description:** Document SOCKS5 usage with practical examples and correct traffic flow

**Work Items:**
- Add SOCKS5 section to README.md
- Explain what SOCKS5 is used for and how it works
- Document traffic flow: Browser → SOCKS5 (localhost:1080) → gost (container) → Traefik (container) → app (container)
- Explain benefit: Access Docker network without port mapping, use Docker DNS names
- Document enabling SOCKS5
- Provide browser configuration examples:
  - Firefox: Manual proxy settings (SOCKS5, 127.0.0.1, port 1080)
  - Chrome: --proxy-server flag
  - Explain accessing http://app.docker.local through SOCKS5
- Provide command-line examples:
  - `curl --socks5 127.0.0.1:1080 http://traefik_docker_local`
  - `curl --socks5 127.0.0.1:1080 http://app.docker.local`
  - `curl --socks5 127.0.0.1:1080 http://myapp_cli`
- Provide database client examples:
  - DBeaver SOCKS proxy configuration to access myapp_pgsql:5432
  - pgAdmin with SOCKS proxy to access PostgreSQL by Docker DNS name
  - No need for port forwarding or exposing ports
- Add security warnings section
- Document authentication setup
- Explain DNS advantage: No need to configure system DNS when using SOCKS5

**Validation:**
- Examples are copy-pasteable and work
- Traffic flow diagram is clear and accurate
- Use cases are clearly explained
- Security implications are clear
- Examples work with default port (1080)
- DNS-less advantage is explained

**Dependencies:** Task 3.4

---

## Phase 4: Documentation & Polish

**Note:** These tasks finalize the feature

### Task 4.1: Update Main README

**Description:** Comprehensive documentation update

**Work Items:**
- Add "Enhanced Proxy Networking" section to README.md
- Document `orodc install-proxy` with new features
- Document all new commands:
  - `export-proxy-cert`
  - `proxy-dns-setup`
  - `proxy-socks5-test`
  - `proxy-status`
- Document all new environment variables
- Add troubleshooting section for common issues
- Add OS-specific setup guides
- Update existing proxy section

**Validation:**
- Documentation is clear and comprehensive
- All commands have examples
- Environment variables are explained
- Troubleshooting covers common issues

**Dependencies:** All Phase 1, 2, 3 tasks

---

### Task 4.2: Update AGENTS.md

**Description:** Update AI agent guidelines for new features

**Work Items:**
- Add section on enhanced proxy features
- Document when to use HTTPS vs HTTP
- Document DNS setup recommendations per OS
- Add SOCKS5 use case examples
- Update troubleshooting workflows
- Add common error messages and solutions

**Validation:**
- AGENTS.md accurately describes new features
- Guidelines help AI assistants use features correctly
- Examples are relevant to OroDC workflows

**Dependencies:** Task 4.1

---

### Task 4.3: Environment Variable Defaults

**Description:** Document and set sensible defaults

**Work Items:**
- Create `.env.orodc.example` with all proxy variables
- Document each variable in comments
- Set defaults in `bin/orodc`:
  - `DC_PROXY_DNS_ENABLED=1`
  - `DC_PROXY_DNS_PORT=8853`
  - `DC_PROXY_SOCKS5_ENABLED=0`
  - `DC_PROXY_SOCKS5_PORT=1080`
  - `DC_PROXY_SOCKS5_BIND=127.0.0.1`
  - `TRAEFIK_HTTPS_BIND_PORT=8443`
- Ensure backward compatibility with existing vars

**Validation:**
- Defaults are sensible and secure
- Documented in .env.orodc.example
- Variables can be overridden
- Backward compatibility maintained

**Dependencies:** Task 4.2

---

### Task 4.4: CI/CD Integration Tests

**Description:** Add GitHub Actions workflow for proxy testing

**Work Items:**
- Create `.github/workflows/test-enhanced-proxy.yml`
- Test matrix: Ubuntu, macOS (if available)
- Install OroDC from current branch
- Run `orodc install-proxy`
- Verify all services start
- Test HTTP endpoint
- Test HTTPS endpoint
- Test DNS resolution (inside container)
- Test SOCKS5 (if enabled)
- Export and verify certificate
- Run with Goss validation

**Validation:**
- Workflow runs on PR and main branch
- All tests pass on supported platforms
- Failures are clear and actionable

**Dependencies:** Task 4.3

---

### Task 4.5: User Acceptance Testing

**Description:** Manual testing by real users

**Work Items:**
- Deploy to test environment
- Recruit 2-3 beta testers (Linux, macOS)
- Provide testing checklist:
  - Install proxy
  - Configure HTTPS and import certificate
  - Set up DNS
  - Test browser access to *.docker.local
  - Enable SOCKS5 and test
  - Export certificate and import to browser
- Collect feedback on:
  - Installation clarity
  - Documentation quality
  - Command usability
  - Error messages
- Address major issues before release

**Validation:**
- Beta testers successfully complete checklist
- No major blockers reported
- Feedback incorporated into docs

**Dependencies:** Task 4.4

---

## Phase 5: Release Preparation

### Task 5.1: Version Bump and Changelog

**Description:** Prepare for release

**Work Items:**
- Update version in `Formula/docker-compose-oroplatform.rb`
- Add changelog entry with new features:
  - HTTPS support with auto-generated certificates
  - DNS resolution for *.docker.local
  - Optional SOCKS5 proxy
  - New commands: export-proxy-cert, proxy-dns-setup, proxy-status
- Update version in README.md

**Validation:**
- Version number follows semver
- Changelog is comprehensive
- All new features mentioned

**Dependencies:** Task 4.5

---

### Task 5.2: Migration Guide

**Description:** Help existing users upgrade

**Work Items:**
- Create MIGRATION.md for existing proxy users
- Explain what changed
- Explain what stays compatible
- Document upgrade steps:
  - Pull latest OroDC
  - Restart proxy: `docker-compose -f compose/docker-compose-proxy.yml down && orodc install-proxy`
  - Export certificate: `orodc export-proxy-cert`
  - Import certificate to browser/system
  - Configure DNS: `orodc proxy-dns-setup`
- Document rollback procedure
- Explain environment variable changes

**Validation:**
- Migration path is clear
- Rollback is documented
- No data loss scenarios

**Dependencies:** Task 5.1

---

### Task 5.3: Release PR

**Description:** Create pull request for review

**Work Items:**
- Create feature branch from main
- Ensure all tasks are complete
- Run all tests locally
- Create PR with:
  - Detailed description
  - Link to design document
  - Screenshots/demos of features
  - Testing checklist
- Request reviews
- Address feedback
- Merge after approval

**Validation:**
- All CI checks pass
- Code review approved
- Documentation reviewed
- No breaking changes

**Dependencies:** Task 5.2

---

## Summary

**Total Tasks:** 28 tasks across 5 phases

**Estimated Timeline:**
- Phase 1 (Foundation): 3-4 days
- Phase 2 (DNS): 2-3 days  
- Phase 3 (SOCKS5): 2-3 days
- Phase 4 (Documentation): 2-3 days
- Phase 5 (Release): 1-2 days

**Total:** ~10-15 days for complete implementation

**Parallelization Opportunities:**
- Phase 2 and Phase 3 can run concurrently after Phase 1
- Documentation tasks can start early
- Testing can happen incrementally

**Critical Path:**
1. Phase 1: Tasks 1.1 → 1.2 → 1.3 → 1.6 → 1.7
2. Phase 2: Tasks 2.1 → 2.2 → 2.3 → 2.5
3. Phase 4: Tasks 4.1 → 4.2 → 4.3 → 4.4
4. Phase 5: All tasks sequential

**Risk Mitigation:**
- Early testing after each phase
- Beta testing before final release
- Comprehensive documentation
- Backward compatibility maintained
- Rollback procedure documented

