---
name: orodc-docker-build-php-node
description: Build custom OroDC PHP+Node.js images for new PHP or Node versions not yet in GHCR. Use when adding a new PHP version, rebuilding php-node-symfony locally, or prebuilt image is missing.
license: MIT
metadata:
  author: local
  scope: project
---

# Custom PHP + Node.js Images

Two-stage build: base PHP (`orodc-php`) → final dev image (`orodc-php-node-symfony`).

## Prebuilt Versions

PHP in tap: `7.1`–`7.4`, `8.1`–`8.5` (Alpine).

Image tag format:

```
ghcr.io/digitalspacestdio/orodc-php-node-symfony:{PHP}-node{NODE}-composer{COMPOSER}-alpine
```

Example: `8.5-node24-composer2-alpine`

## Quick Build (Existing PHP Version)

Set versions in `.env.orodc`:

```bash
DC_ORO_PHP_VERSION=8.5
DC_ORO_NODE_VERSION=24
DC_ORO_COMPOSER_VERSION=2
DC_ORO_PHP_DIST=alpine
```

From project root:

```bash
orodc image build
# or without cache:
orodc image build --no-cache
```

Builds:
1. `ghcr.io/digitalspacestdio/orodc-php:{PHP}-alpine`
2. `ghcr.io/digitalspacestdio/orodc-php-node-symfony:{PHP}-node{NODE}-composer{COMPOSER}-alpine`
3. Project images (`fpm`, `cli`, `ssh`, …) if `.env.orodc` present

## Add New PHP Version to Tap

When `Dockerfile.{VERSION}.alpine` does not exist:

### Step 1 — Base PHP image

Copy nearest version:

```bash
cp compose/docker/php/Dockerfile.8.5.alpine compose/docker/php/Dockerfile.8.6.alpine
```

Edit:
- `ARG PHP_VERSION=8.6`
- `ARG ALPINE_VERSION` — match official `php:8.6-fpm-alpine` base
- PECL extension versions — use git commits for RC/beta PHP (see `8.5` Dockerfile)
- PHP 8.4+: IMAP via PECL, not built-in

### Step 2 — Final PHP+Node image

```bash
cp -r compose/docker/php-node-symfony/8.5 compose/docker/php-node-symfony/8.6
```

Edit `8.6/Dockerfile`:
- `ARG PHP_VERSION=8.6`
- `ARG NODE_VERSION` default
- `COPY 8.6/build.sh` path
- pnpm branch in `npm install -g` RUN if Node 24+

Edit `8.6/build.sh` — usually copy from previous version unchanged.

Shared configs live in `compose/docker/php-node-symfony/shared/` — do not duplicate.

### Step 3 — Build and test

```bash
DC_ORO_PHP_VERSION=8.6 DC_ORO_NODE_VERSION=22 orodc image build --no-cache
docker run --rm ghcr.io/digitalspacestdio/orodc-php:8.6-alpine php -v
docker run --rm ghcr.io/digitalspacestdio/orodc-php-node-symfony:8.6-node22-composer2-alpine node -v
```

### Step 4 — Project use

```bash
# .env.orodc
DC_ORO_PHP_VERSION=8.6
DC_ORO_NODE_VERSION=22
DC_ORO_PHP_IMAGE=ghcr.io/digitalspacestdio/orodc-php-node-symfony:8.6-node22-composer2-alpine
```

```bash
orodc down
orodc image build
orodc up -d
```

### Step 5 — Tap release

Bump `Formula/docker-compose-oroplatform.rb` revision.

```bash
brew reinstall digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform
```

## Node.js Version Mapping

Set `DC_ORO_NODE_VERSION` in `.env.orodc`. Dockerfile pulls `node:${NODE_VERSION}-alpine`.

| Node | Notes |
|------|-------|
| 18 | PHP 7.x–8.3 default |
| 20 | PHP 8.4 typical |
| 22 | PHP 8.5 typical |
| 24 | pnpm 10.x branch in Dockerfile |

## Manual Docker Build

```bash
# Stage 1
docker build -f compose/docker/php/Dockerfile.8.5.alpine \
  -t ghcr.io/digitalspacestdio/orodc-php:8.5-alpine \
  compose/docker/php/

# Stage 2
docker build \
  --build-arg PHP_VERSION=8.5 \
  --build-arg NODE_VERSION=24 \
  --build-arg COMPOSER_VERSION=2 \
  --build-arg PHP_IMAGE=ghcr.io/digitalspacestdio/orodc-php:8.5-alpine \
  -f compose/docker/php-node-symfony/8.5/Dockerfile \
  -t ghcr.io/digitalspacestdio/orodc-php-node-symfony:8.5-node24-composer2-alpine \
  compose/docker/php-node-symfony/
```

## Troubleshooting

| Problem | Action |
|---------|--------|
| Dockerfile not found | Add `php/Dockerfile.X.alpine` and `php-node-symfony/X/` directory |
| PECL build fails on new PHP | Pin git commit hashes like `8.5` Dockerfile |
| Built image not used | Set `DC_ORO_PHP_IMAGE` in `.env.orodc`, rebuild project images |
| Low disk space | Need ~5 GB free; `orodc image build` warns below threshold |

## Do Not

- Manually `docker build` project `Dockerfile.project` — use `orodc image build` or `orodc up`
- Use `docker compose build --progress=plain` on Compose v5 (known panic bug)

## References

- `compose/docker/README.md` — multi-stage architecture
- `libexec/orodc/image/build.sh` — `orodc image build` implementation
- `openspec/changes/archive/2025-12-15-add-manual-image-building/design.md`
