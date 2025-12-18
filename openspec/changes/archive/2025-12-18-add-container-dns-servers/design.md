## Context

Docker containers by default inherit DNS configuration from the host system. In some environments, the host DNS may be slow, unreliable, or blocked. Explicitly configuring DNS servers in containers ensures consistent external DNS resolution.

## Goals / Non-Goals

### Goals
- Configure reliable DNS servers (1.1.1.1 and 8.8.8.8) for all containers
- Ensure DNS configuration is consistent across all services
- Maintain backward compatibility (no breaking changes)
- Preserve Docker's internal DNS for container-to-container communication

### Non-Goals
- Customizable DNS servers (hardcoded to 1.1.1.1 and 8.8.8.8 for now)
- DNS server selection based on environment
- DNS caching configuration

## Decisions

### Decision: Use Docker Compose `dns` Directive

**What**: Configure DNS servers using the `dns` key in Docker Compose service definitions.

**Why**:
- Native Docker Compose feature, no custom scripts needed
- Works consistently across all platforms (Linux, macOS, Windows)
- Simple YAML configuration
- Docker handles DNS server ordering and fallback automatically

**Alternatives considered**:
- Custom entrypoint scripts: More complex, requires modifying container images
- Docker daemon configuration: Affects all containers system-wide, not project-specific
- Network-level DNS: Requires custom Docker networks, more complex setup

### Decision: Configure DNS at Service Level

**What**: Add `dns` configuration to each service definition rather than using global `x-dns` extension.

**Why**:
- Explicit and clear - each service shows its DNS configuration
- Easier to verify and debug
- Allows future per-service customization if needed
- Docker Compose doesn't support global DNS inheritance in a simple way

**Implementation**:
```yaml
services:
  fpm:
    dns:
      - 1.1.1.1
      - 8.8.8.8
```

### Decision: Use Cloudflare (1.1.1.1) and Google (8.8.8.8) DNS

**What**: Configure both 1.1.1.1 (Cloudflare) and 8.8.8.8 (Google) as DNS servers.

**Why**:
- 1.1.1.1: Fast, privacy-focused, reliable
- 8.8.8.8: Widely used, reliable fallback
- Redundancy: If one fails, the other provides backup
- Public DNS servers work from any network location

**Note**: These are hardcoded for now. Future enhancement could make them configurable via environment variables.

## Risks / Trade-offs

### Risk: DNS Server Availability
**Mitigation**: Using two public DNS servers (1.1.1.1 and 8.8.8.8) provides redundancy. Docker will automatically fallback if one is unavailable.

### Risk: Network Policy Restrictions
**Mitigation**: Most networks allow access to public DNS servers. If restricted, users can override via `.docker-compose.user.yml`.

### Trade-off: Hardcoded DNS Servers
**Impact**: DNS servers are not configurable via environment variables. This is acceptable for MVP as it provides reliable defaults. Future enhancement can add `DC_ORO_DNS_SERVERS` environment variable.

## Migration Plan

1. Add DNS configuration to all compose files
2. No data migration needed
3. Existing containers will get DNS configuration on next `orodc up`
4. No breaking changes - containers will continue to work with or without explicit DNS

## Open Questions

- Should DNS servers be configurable via environment variables? (Deferred to future enhancement)
- Should we add DNS search domains? (Not needed for current use case)

