---
name: orodc-docker-proxy-setup
description: Configure and troubleshoot the local OroDC Traefik proxy container for *.docker.local domains, HTTPS, SOCKS5, and dashboard access. Use when domains do not open, proxy is not running, SSL warnings appear, or user asks about proxy/Traefik setup on macOS/WSL2/Linux.
license: MIT
metadata:
  author: local
  scope: project
  internal: true
---

# Local Proxy Container Setup

OroDC runs Traefik inside Docker (`proxy` container) on shared network `dc_shared_net`. Required for `https://<project>.docker.local` on macOS and WSL2 + Docker Desktop.

## When to Use

- `*.docker.local` does not open but `orodc ps` shows healthy containers
- Browser shows SSL certificate warning
- Need Traefik dashboard or SOCKS5 access to containers
- Setting up proxy for the first time

## Quick Start

```bash
orodc proxy up -d
orodc proxy install-certs
orodc up -d
```

Open: `https://<project-name>.docker.local`

## Commands

| Command | Action |
|---------|--------|
| `orodc proxy up -d` | Start proxy (detached) |
| `orodc proxy up` | Start with logs (foreground) |
| `orodc proxy down` | Stop proxy, keep volumes |
| `orodc proxy restart` | Restart proxy |
| `orodc proxy install-certs` | Install CA to system trust store |

Non-interactive defaults: `TRAEFIK_BIND_ADDRESS=127.0.0.1`, `DC_PROXY_SOCKS5_PORT=1080`.

```bash
export TRAEFIK_BIND_ADDRESS=127.0.0.1
export DC_PROXY_SOCKS5_PORT=1080
orodc proxy up -d
```

## Architecture

**macOS / WSL2 + Docker Desktop (dual proxy):**

```
Browser → Traefik (host, dnsmasq) → Traefik (docker :8880) → Nginx container
```

Host infrastructure (optional but recommended):

```bash
brew tap digitalspacestdio/ngdev
brew install digitalspace-traefik digitalspace-dnsmasq digitalspace-local-ca
digitalspace-dnsmasq-start
digitalspace-traefik-start
digitalspace-traefik-enable-docker-proxy   # macOS/WSL2 only
orodc proxy up -d
```

**Linux native Docker:**

Host Traefik can route directly to containers. Docker proxy (`orodc proxy up -d`) is optional.

## Ports and URLs

| Service | Default |
|---------|---------|
| HTTP | `http://127.0.0.1:8880` |
| HTTPS | `https://127.0.0.1:8443` |
| SOCKS5 | `127.0.0.1:1080` |
| Dashboard | `http://127.0.0.1:8880/traefik/dashboard/` |

Via SOCKS5 in browser: `http://proxy.docker.local`, `http://traefik.docker.local`

## Environment Variables

Set in shell, `.env.orodc`, or `~/.orodc/<project>/.env.orodc`:

```bash
TRAEFIK_BIND_ADDRESS=127.0.0.1      # 0.0.0.0 for WSL2/Lima VM host access
TRAEFIK_BIND_PORT=8880
TRAEFIK_HTTPS_BIND_PORT=8443
DC_PROXY_SOCKS5_PORT=1080
DC_PROXY_SOCKS5_ENABLED=1
DC_PROXY_DNS_SYNC_ENABLED=1
TRAEFIK_LOG_LEVEL=INFO              # DEBUG with DEBUG=1 orodc proxy up -d
CERT_DOMAIN=docker.local
ORODC_PROXY_IMAGE=ghcr.io/digitalspacestdio/orodc-proxy:latest
```

Bind address guide:
- `127.0.0.1` — native Docker on macOS/Linux (secure default)
- `0.0.0.0` — WSL2, Lima VM (host must reach Docker VM)

## HTTPS Certificates

Proxy auto-generates wildcard cert for `*.docker.local` in volume `proxy_certs`.

```bash
orodc proxy up -d          # proxy must be running
orodc proxy install-certs  # exports CA from container, installs to OS trust store
```

- **macOS:** System Keychain
- **Linux:** `/usr/local/share/ca-certificates/` + NSS for Chrome
- **WSL2:** Linux store + manual Windows CA install (command prints steps)

## How Routing Works

1. Project nginx containers have `traefik.enable=true` labels on `dc_shared_net`
2. Proxy watches Docker socket, discovers routers automatically
3. `dns-sync` inside proxy updates `/etc/hosts` from Traefik labels
4. Access `*.docker.local` via host dnsmasq → proxy → nginx

Extra project hosts:

```bash
DC_ORO_EXTRA_HOSTS=api,admin
orodc up -d
# api.docker.local, admin.docker.local
```

## Verify

```bash
docker ps --filter name=proxy
docker inspect proxy --format '{{.State.Health.Status}}'
curl -s http://127.0.0.1:8880/traefik/dashboard/
nslookup myproject.docker.local
orodc status
```

Project must be on `dc_shared_net` — `orodc up -d` connects automatically.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Domain not found | Start host dnsmasq + `orodc proxy up -d` |
| Connection refused :8880 | `orodc proxy up -d`; check `TRAEFIK_BIND_ADDRESS` |
| SSL warning | `orodc proxy install-certs`, restart browser |
| HTTPS redirect loop (Oro/Symfony) | Proxy `traefik.yml` has `forwardedHeaders.trustedIPs` for dual-proxy — rebuild proxy image if missing |
| 404 from Traefik | Check nginx has `traefik.enable=true`, project on `dc_shared_net` |
| Dashboard empty | Wait for dns-sync; `DEBUG=1 orodc proxy up` |
| Port 1080 busy | `DC_PROXY_SOCKS5_PORT=9999 orodc proxy up -d` |

Logs:

```bash
docker logs proxy
DEBUG=1 orodc proxy up -d
```

## Rebuild Proxy Image (Tap Maintainers)

After editing `compose/docker/proxy/`:

```bash
orodc docker-build proxy
# or
orodc docker-build proxy --no-cache --push
```

Bump `Formula/docker-compose-oroplatform.rb`, then:

```bash
brew reinstall digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform
orodc proxy restart
```

Key files:
- `compose/docker-compose-proxy.yml` — ports, env, labels
- `compose/docker/proxy/traefik.yml` — entrypoints, docker provider
- `compose/docker/proxy/dynamic.yml` — TLS certs
- `compose/docker/proxy/dns-sync.sh` — hostname sync
- `libexec/orodc/proxy/up.sh` — startup prompts

## Full Removal

```bash
orodc proxy down
docker volume rm proxy_certs
docker network rm dc_shared_net   # only if no projects use it
```

## References

- `.agents/skills/orodc-docker-dev-env/references/proxy.md`
- `.agents/skills/orodc-docker-dev-env/references/installation.md` — host infrastructure
- `README.md` — Infrastructure Setup section
