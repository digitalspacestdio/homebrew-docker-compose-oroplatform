# Proxy And Domains

Internal reference. Read this when `*.docker.local` domains do not open even though app containers are healthy.

Access via `https://<project>.docker.local` requires a reverse proxy and local DNS. Without proxy, project domains will not open in the browser.

Docker-based proxy management:

```bash
orodc proxy up -d            # Start proxy (key command when domains do not resolve)
orodc proxy install-certs    # Install local certificates for HTTPS
orodc proxy down             # Stop proxy, keep volumes
orodc proxy purge            # Remove proxy completely
```

Notes:

- `orodc proxy up -d` is the key command when `*.docker.local` does not resolve through the local proxy.
- Especially important on macOS and WSL2 with Docker Desktop.
- If the proxy is not running, access by custom project domains fails even if app containers are healthy.
- For full host infrastructure setup of Traefik, Dnsmasq, and local CA, see `references/installation.md` and `README.md`.
