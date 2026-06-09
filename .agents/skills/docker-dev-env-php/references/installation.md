# Installing `orodc`

Internal reference. Read this only when `orodc` is missing or when the user asks to install, set up, or bootstrap the local environment.

## 1. Check whether `orodc` is already installed

```bash
orodc help
```

If the command is not found, install it. Do not run `orodc`-based steps as if the command exists.

## 2. Requirements

- Docker must be installed and running (Docker Desktop on macOS / WSL2, native Docker on Linux/WSL2).
- Homebrew must be available.

## 3. Install via Homebrew

```bash
brew install digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform
```

Verify:

```bash
orodc help
orodc --version
```

## 4. Bootstrap a project

`orodc` runs from a project root. Either clone an app or create an empty project directory.

Oro / OroCommerce:

```bash
git clone --single-branch --branch 6.1.4 https://github.com/oroinc/orocommerce-application.git ~/orocommerce
cd ~/orocommerce
orodc install && orodc up -d
```

Generic project (Magento, Symfony, Laravel, etc.):

```bash
mkdir ~/myproject && cd ~/myproject
orodc init && orodc up -d
```

For CMS-specific install steps, run `orodc agents installation` from the project root and follow it step by step.

## 5. Optional: `*.docker.local` domains (Traefik + Dnsmasq + SSL)

Custom domains require reverse proxy + local DNS. Without this you can still use `http://localhost:<port>`.

Install infrastructure from the `ngdev` tap:

```bash
brew tap digitalspacestdio/ngdev
brew install digitalspace-traefik digitalspace-dnsmasq digitalspace-local-ca
brew install digitalspace-allutils
```

### Linux / WSL2 (native Docker)

Traefik runs on the host and connects directly to containers.

```bash
cp $(brew --prefix)/etc/traefik/traefik.toml $(brew --prefix)/etc/traefik/traefik.override.toml
# Edit traefik.override.toml and uncomment the [providers.docker] section.

digitalspace-dnsmasq-start
digitalspace-traefik-start
digitalspace-supctl status
```

Architecture: `Browser -> Traefik (host) -> Nginx (container)`

### macOS / WSL2 + Docker Desktop

Two-stage setup: host Traefik forwards into Docker, where a second Traefik routes to containers.

```bash
brew install digitalspace-traefik
digitalspace-dnsmasq-start
digitalspace-traefik-start
digitalspace-traefik-enable-docker-proxy

orodc proxy up -d
orodc proxy install-certs
```

Architecture: `Browser -> Traefik (host) -> Traefik (docker) -> Nginx (container)`

For full host infrastructure and CA details, see `README.md`.
