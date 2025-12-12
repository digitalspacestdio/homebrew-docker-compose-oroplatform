# Proposal: Enhance Proxy Networking

**Change ID:** enhance-proxy-networking  
**Status:** Draft  
**Author:** System  
**Date:** 2024-12-12

## Summary

Enhance the existing Traefik reverse proxy server to provide a complete local development networking solution that includes SSL/TLS certificate management, DNS resolution for *.docker.local domains, and optional SOCKS5 proxy support for seamless container access.

## Background

Currently, OroDC includes a basic Traefik reverse proxy (`orodc install-proxy`) that:
- Provides HTTP reverse proxy on port 8880
- Uses docker labels for service discovery
- Requires manual /etc/hosts entries for *.docker.local domains
- Lacks SSL/TLS support
- Only accessible via HTTP

This creates friction for developers who need:
- HTTPS for testing SSL-dependent features
- Automatic DNS resolution without manual /etc/hosts management
- Direct network access to containers from host machine
- Browser-friendly certificate trust

## Objectives

1. **SSL/TLS Certificate Management**: Auto-generate self-signed CA and service certificates on first start
2. **DNS Resolution**: Resolve all *.docker.local domains via automatic /etc/hosts sync
3. **Certificate Export**: Provide `orodc export-proxy-cert` command for importing CA into system trust store
4. **SOCKS5 Proxy** (optional): Enable direct container network access for advanced use cases
5. **Backward Compatibility**: Keep existing HTTP-only mode working

## Proposed Solution

### 1. Enhanced Proxy Container

Extend `docker-compose-proxy.yml` to include:
- Traefik with SSL/TLS entrypoint (port 443)
- Optional SOCKS5 proxy service (serjs/socks5-server)
- Named volume for persistent certificates

External bash script service:
- `orodc-dns-sync` watches Docker events
- Automatically updates /etc/hosts
- Runs as systemd/launchd service

### 2. Certificate Generation

On first start:
- Generate root CA certificate + key
- Store in named volume `proxy_certs`
- Configure Traefik to use generated certificates
- Auto-generate certificates for *.docker.local wildcard

### 3. DNS Resolution Options

**Option A: Auto /etc/hosts Sync (PRIMARY, RECOMMENDED)**
- Lightweight daemon watches Docker events
- Automatically updates /etc/hosts when containers start/stop
- Uses Docker labels: `orodc.dns.hostname=app.docker.local`
- No DNS server, no port conflicts, works everywhere
- Inspired by [DNS Proxy Server](https://stackoverflow.com/questions/37242217/access-docker-container-from-host-using-containers-name/63656003#63656003)
- Runs as systemd service (Linux) or launchd daemon (macOS)

**Option B: SOCKS5 (No DNS setup needed)**
- Use SOCKS5 proxy for zero-config access
- Docker internal DNS resolves everything
- Perfect for advanced users

**Option C: Manual /etc/hosts (Fallback)**
- Document manual /etc/hosts editing
- Simplest but requires manual updates

### 4. SOCKS5 Proxy

- Optional service (disabled by default)
- Uses lightweight ready-made server (serjs/socks5-server, ~2-3MB)
- Runs inside proxy container with access to Docker network
- Browser configures SOCKS5 → traffic flows through socks5-server → Traefik → containers
- Allows access to Docker network using container DNS names
- No DNS configuration needed when using SOCKS5 (Docker internal DNS works)
- Useful for testing multi-container scenarios without port mapping

## Affected Components

- `compose/docker-compose-proxy.yml` - Enhanced service definition
- `bin/orodc` - New commands: `export-proxy-cert`, `proxy-dns-setup`
- `compose/docker/proxy/` - New Dockerfile for multi-service proxy
- `compose/docker/proxy/entrypoint.sh` - Certificate generation logic
- `README.md` - Documentation updates

## Open Questions

1. **DNS Approach**: ✅ RESOLVED - Use auto /etc/hosts sync
   - Primary: Auto /etc/hosts sync daemon (simple, reliable, no DNS server)
   - Alternative: SOCKS5 (zero-config for advanced users)
   - Fallback: Manual /etc/hosts

2. **SOCKS5 Default**: Enable by default or opt-in?
   - Enable: more features out of box
   - Opt-in: simpler default, advanced users enable

3. **Certificate Trust**: Auto-import CA cert or manual user action?
   - Auto: requires root, platform-specific
   - Manual: user exports and imports themselves

4. **SSL by Default**: Replace HTTP (port 8880) or add HTTPS (port 8443)?
   - Replace: simpler, forces HTTPS
   - Add both: backward compatible, user choice

## Success Criteria

- [ ] Traefik serves HTTPS on port 8443 with auto-generated certificates
- [ ] `orodc export-proxy-cert` exports CA certificate for import
- [ ] `orodc-dns-sync` bash script automatically updates /etc/hosts
- [ ] *.docker.local domains resolve via /etc/hosts (no DNS server needed)
- [ ] SOCKS5 proxy available (when enabled) for direct container access
- [ ] Existing `orodc install-proxy` continues working
- [ ] Documentation covers certificate import for major OS/browsers
- [ ] Zero manual /etc/hosts editing required (fully automated)

## Non-Goals

- Public CA certificates (Let's Encrypt) - local development only
- Production-grade HA proxy setup
- Certificate rotation/renewal automation
- DNS server for non-.docker.local domains

## Dependencies

- Docker 20.10+
- docker-compose v2+
- Traefik v3 (latest, downloaded from GitHub releases)
- s6-overlay v3 (~2-3MB, container init system)
- serjs/go-socks5-proxy (pre-built SOCKS5 binary)
- Bash (for orodc-dns-sync script)
- systemd (Linux) or launchd (macOS) for service management
- sudo access for /etc/hosts modification

## Timeline

See `tasks.md` for detailed implementation steps.

