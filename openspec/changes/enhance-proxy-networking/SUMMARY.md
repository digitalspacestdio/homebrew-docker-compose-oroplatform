# Summary: Enhanced Proxy Networking Proposal

**Change ID:** `enhance-proxy-networking`  
**Status:** ✅ VALIDATED - Ready for Review  
**Created:** 2024-12-12

## Quick Overview

This OpenSpec proposal enhances the existing OroDC proxy server to provide a complete local development networking solution with:

1. **🔒 SSL/TLS Support** - Auto-generated certificates for HTTPS
2. **🌐 DNS Resolution** - **NEW APPROACH:** Auto /etc/hosts sync instead of DNS server
3. **🔌 SOCKS5 Proxy** - Optional direct container network access

### 🎯 Key Innovation: Auto /etc/hosts Sync

Instead of running a DNS server, we use a simple **bash script** that watches Docker events and automatically updates `/etc/hosts`. This approach is:
- **Simpler** - No DNS server, no port conflicts
- **More reliable** - Works everywhere (Linux, macOS, Windows)
- **Zero configuration** - Just install the service once
- **Inspired by** [DNS Proxy Server](https://stackoverflow.com/questions/37242217/access-docker-container-from-host-using-containers-name/63656003#63656003)

## Key Features

### Modern Stack
- ✅ **Traefik v3** - Latest version, always up-to-date from GitHub releases
- ✅ **Alpine-based** - Clean build from `alpine:latest` base
- ✅ **Multi-arch** - Supports amd64 and arm64 architectures
- ✅ **Static binaries** - All components as standalone executables

### Certificate Management
- ✅ Auto-generate self-signed CA on first start
- ✅ Wildcard certificate for *.docker.local
- ✅ Persistent certificate storage
- ✅ `orodc export-proxy-cert` command for system import
- ✅ HTTPS on port 8443 (HTTP on 8880 stays for backward compat)

### DNS Resolution
- ✅ **Auto /etc/hosts sync** - Primary solution (simple, reliable, no DNS server)
- ✅ Watches Docker events and updates /etc/hosts automatically
- ✅ Uses Docker label: `orodc.dns.hostname=app.docker.local`
- ✅ Runs as systemd service (Linux) or launchd daemon (macOS)
- ✅ `orodc proxy-dns-setup --install` - Install DNS sync service
- ✅ `orodc proxy-dns-setup --status` - Check sync status
- ✅ No DNS server, no port conflicts, works everywhere
- ✅ Inspired by [DNS Proxy Server approach](https://stackoverflow.com/questions/37242217/access-docker-container-from-host-using-containers-name/63656003#63656003)

### SOCKS5 Proxy (Optional)
- ✅ Disabled by default (opt-in via DC_PROXY_SOCKS5_ENABLED=1)
- ✅ Uses pre-built binary from [serjs/go-socks5-proxy](https://hub.docker.com/r/serjs/go-socks5-proxy) (~2-3MB)
- ✅ **Zero compilation:** Just copy from official Docker image
- ✅ Direct access to Docker network from browser
- ✅ Traffic flow: Browser → SOCKS5 (localhost:1080) → socks5 (in container) → Traefik → nginx
- ✅ No DNS setup needed - Docker internal DNS works automatically
- ✅ Browser/tool proxy support
- ✅ `orodc proxy-socks5-test` command
- ✅ Port 1080 (localhost only for security)

### Process Management (s6-overlay v3)
- 🔄 **Auto-restart** - Processes automatically restart on failure
- 📋 **Service Dependencies** - Ordered startup (certs → traefik → socks5)
- ⚡ **Lightweight** - Only ~2-3MB overhead
- 🐳 **Docker-native** - Built specifically for containers
- 📊 **Process Status** - Check with `s6-rc -a list` command inside container

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| DNS Method | **Auto /etc/hosts sync** | Simple, reliable, no DNS server, works everywhere |
| SSL Certs | Self-signed CA | Local dev only, no external deps |
| SOCKS5 | Opt-in | Advanced feature, not needed by most users |
| Backward Compat | Keep HTTP + add HTTPS | No breaking changes |
| Base Image | **alpine:latest** | Clean build, full control, small base |
| Traefik | **v3 latest** | Always current, downloaded from GitHub |
| Process Manager | **[s6-overlay v3](https://github.com/just-containers/s6-overlay)** | Lightweight ~2-3MB, actively maintained, Docker-native |
| SOCKS5 Binary | **[serjs/go-socks5-proxy](https://hub.docker.com/r/serjs/go-socks5-proxy)** | Pre-built ~2-3MB, zero compilation |
| Container | Simplified (Traefik + SOCKS5) | No DNS in container, minimal size |

## File Structure

```
openspec/changes/enhance-proxy-networking/
├── proposal.md               # Main proposal (this document's source)
├── design.md                 # Architectural decisions & diagrams
├── tasks.md                  # 28 implementation tasks in 5 phases
├── SUMMARY.md               # This file
└── specs/
    ├── ssl-certificate-management/
    │   └── spec.md          # 7 requirements, 15 scenarios
    ├── dns-resolution/
    │   └── spec.md          # 6 requirements, 15 scenarios  
    └── socks5-proxy/
        └── spec.md          # 7 requirements, 18 scenarios
```

## Implementation Timeline

**Total:** 28 tasks, ~10-15 days

- **Phase 1:** Foundation & Certificate Management (3-4 days)
- **Phase 2:** DNS Resolution (2-3 days, parallel with Phase 3)
- **Phase 3:** SOCKS5 Proxy (2-3 days, parallel with Phase 2)
- **Phase 4:** Documentation & Polish (2-3 days)
- **Phase 5:** Release Preparation (1-2 days)

## New Commands

```bash
orodc install-proxy                  # Enhanced with HTTPS, optional SOCKS5
orodc export-proxy-cert              # Export CA certificate for import
orodc proxy-dns-setup --install      # Install auto /etc/hosts sync service
orodc proxy-dns-setup --uninstall    # Uninstall DNS sync service
orodc proxy-dns-setup --status       # Show DNS sync status
orodc proxy-dns-setup --verify       # Test hostname resolution
orodc proxy-socks5-test              # Test SOCKS5 connectivity
orodc proxy-status                   # Show all proxy features status
```

## Environment Variables

```bash
# HTTPS
TRAEFIK_HTTPS_BIND_PORT=8443     # HTTPS port (new)

# Auto DNS Sync (no environment variables - controlled by service)
# Uses Docker labels: orodc.dns.hostname=app.docker.local

# SOCKS5
DC_PROXY_SOCKS5_ENABLED=0        # Enable SOCKS5 (default: 0)
DC_PROXY_SOCKS5_PORT=1080        # SOCKS5 port (default: 1080)
DC_PROXY_SOCKS5_BIND=127.0.0.1   # SOCKS5 bind (default: localhost only)
DC_PROXY_SOCKS5_USER=            # Optional auth username
DC_PROXY_SOCKS5_PASS=            # Optional auth password
```

## Affected Files

**New Files:**
- `compose/docker/proxy/Dockerfile` - Multi-stage: serjs/go-socks5-proxy + Alpine + Traefik v3 + s6-overlay
- `compose/docker/proxy/traefik.yml` - Traefik v3 config with TLS
- `compose/docker/proxy/generate-certs.sh` - SSL certificate generation
- `compose/docker/proxy/s6-rc.d/` - s6-overlay service definitions:
  - `init-certs/` - Oneshot certificate generation
  - `traefik/` - Longrun Traefik service
  - `socks5/` - Longrun SOCKS5 service (conditional)
- `bin/orodc-dns-sync` - DNS sync daemon script (NEW CORE COMPONENT)

**Modified Files:**
- `compose/docker-compose-proxy.yml` - Add build, volumes, ports (simplified, no DNS)
- `bin/orodc` - Add new commands (5-6 new command handlers)
- `README.md` - Document new features and auto /etc/hosts sync
- `AGENTS.md` - Update AI agent guidelines

**System Files (Installed):**
- `/etc/systemd/system/orodc-dns-sync.service` (Linux)
- `/Library/LaunchDaemons/com.orodc.dns-sync.plist` (macOS)
- `/usr/local/bin/orodc-dns-sync` (Both)

## Success Metrics

- [ ] ✅ OpenSpec validation passes (DONE)
- [ ] HTTPS endpoint works with valid certificate
- [ ] Certificate export and import documented per OS
- [ ] DNS resolves *.docker.local automatically
- [ ] SOCKS5 works when enabled
- [ ] No breaking changes to existing proxy
- [ ] CI tests pass on Linux and macOS
- [ ] Beta testing feedback positive

## Open Questions for Discussion

1. **DNS Approach:** ✅ RESOLVED - Bash script for /etc/hosts sync
   - Simple bash script, no DNS server needed
   - Inspired by StackOverflow solution

2. **SOCKS5 Default:** Should SOCKS5 be enabled by default?
   - **Proposal:** Disabled by default (opt-in for advanced users)

3. **Certificate Trust:** Auto-import CA or manual?
   - **Proposal:** Manual (provide clear instructions per OS)

4. **SSL Default:** Should HTTPS replace HTTP or be additional?
   - **Proposal:** Both (8880 HTTP + 8443 HTTPS for backward compat)

## Next Steps

1. ✅ Create OpenSpec proposal (DONE)
2. ✅ Validate proposal structure (DONE)
3. 📝 Review with team
4. 🔄 Address feedback and open questions
5. ✅ Approve proposal
6. 🚀 Begin Phase 1 implementation (Task 1.1)

## How to Review This Proposal

```bash
# View full proposal
openspec show enhance-proxy-networking

# View specific spec
openspec show enhance-proxy-networking/specs/ssl-certificate-management

# View with spec deltas only
openspec show enhance-proxy-networking --json --deltas-only

# List all requirements
rg -n "Requirement:|Scenario:" openspec/changes/enhance-proxy-networking/specs/

# Read detailed design
cat openspec/changes/enhance-proxy-networking/design.md

# Read implementation tasks
cat openspec/changes/enhance-proxy-networking/tasks.md
```

## Questions or Feedback?

Please provide feedback on:
- Architecture decisions (see design.md)
- Open questions (above)
- Task sequencing (see tasks.md)
- Requirements completeness (see specs/*.md)

---

**Validation Status:** ✅ `openspec validate enhance-proxy-networking --strict` PASSED

