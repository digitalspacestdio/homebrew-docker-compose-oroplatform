# OroDC Docker Images

This directory contains Docker image definitions for the OroDC (Oro Platform Docker Compose) project. The images are organized in a **multi-stage architecture** optimized for size, build speed, and maintainability.

## 📁 Directory Structure

```
compose/docker/
├── php/                          # Base PHP images (PHP only)
│   ├── Dockerfile.7.4.alpine     # PHP 7.4 base
│   ├── Dockerfile.8.1.alpine     # PHP 8.1 base
│   ├── Dockerfile.8.2.alpine     # PHP 8.2 base
│   ├── Dockerfile.8.3.alpine     # PHP 8.3 base
│   ├── Dockerfile.8.4.alpine     # PHP 8.4 base
│   └── Dockerfile.8.5.alpine     # PHP 8.5-rc base
│
├── php-node-symfony/             # Final images (PHP + Node.js + tools)
│   ├── Dockerfile.7.4.alpine     # PHP 7.4 + Node.js 18
│   ├── Dockerfile.8.1.alpine     # PHP 8.1 + Node.js 18
│   ├── Dockerfile.8.2.alpine     # PHP 8.2 + Node.js 18
│   ├── Dockerfile.8.3.alpine     # PHP 8.3 + Node.js 18
│   ├── Dockerfile.8.4.alpine     # PHP 8.4 + Node.js 20
│   ├── Dockerfile.8.5.alpine     # PHP 8.5-rc + Node.js 22
│   ├── build7.4.sh               # Build scripts (one per PHP version)
│   ├── build8.*.sh               # Consolidate RUN commands for layer optimization
│   ├── app.ini                   # PHP configuration
│   ├── app.opcache.ini           # OPcache settings
│   ├── app.msmtp.ini             # Mail (msmtp) configuration
│   ├── app.xdebug.ini            # Xdebug configuration
│   ├── php-fpm.conf              # PHP-FPM configuration
│   ├── docker-entrypoint.sh      # Container entrypoint
│   ├── docker-healthcheck.sh     # Health check script
│   ├── docker-sshd.sh            # SSH daemon management
│   ├── docker-psql.sh            # PostgreSQL wrapper
│   ├── docker-mysql.sh           # MySQL wrapper
│   ├── msmtprc                   # MSMTP runtime config
│   └── zshrc                     # Zsh shell configuration
│
├── project-php-node-symfony/     # Project-specific customization layer
│   └── Dockerfile.project        # Extends php-node-symfony with project code
│
├── nginx/                        # Nginx web server
│   ├── Dockerfile
│   ├── nginx.conf
│   └── entrypoint.sh
│
├── mysql/                        # MySQL database
│   ├── initdb.d/                 # Initialization scripts
│   └── my.cnf                    # MySQL configuration
│
├── pgsql/                        # PostgreSQL database
│   └── initdb.d/
│       └── 10-uuid-ossp.sql      # UUID extension
│
├── mongo/                        # MongoDB database
│   └── initdb.d/
│       └── 01_xhprof.js          # XHProf setup
│
└── xhgui/                        # XHGui profiler UI
    ├── config/
    │   └── config.default.php
    └── nginx.conf
```

## 🏗️ Multi-Stage Build Architecture

### Stage 1: Base PHP Images (`php/Dockerfile.*.alpine`)

**Purpose:** Pure PHP runtime with compiled extensions only.

**Characteristics:**
- Built on official `php:X.X-fpm-alpine` images
- Contains **ONLY** PHP and its extensions
- No user creation, no Composer, no Node.js
- Published as: `ghcr.io/digitalspacestdio/orodc-php:X.X-alpine`

**Installed PHP Extensions:**
- **Core:** bcmath, ctype, curl, dom, fileinfo, filter, gd, hash, iconv, intl, json, mbstring, opcache, pcntl, pdo, pdo_mysql, pdo_pgsql, pgsql, session, simplexml, soap, sockets, tokenizer, xml, xmlreader, xmlwriter, xsl, zip
- **IMAP:** 
  - PHP 7.4, 8.1-8.3: Built-in IMAP extension
  - PHP 8.4+: PECL imap (built-in removed from PHP 8.4)
- **PECL Extensions:**
  - redis (with igbinary serialization support)
  - mongodb
  - xdebug (development only)

**Extension Version Management:**
- PHP 7.4, 8.1-8.4: Use stable release versions
- PHP 8.5-rc: Use git commit hashes (for RC/beta compatibility)

**Key Build Arguments:**
```dockerfile
ARG ALPINE_VERSION=3.21           # Alpine Linux version
ARG PHP_VERSION=8.3                # PHP version
ARG EXT_REDIS_VERSION=6.2.0        # Redis extension version
ARG EXT_IGBINARY_VERSION=3.2.15    # Igbinary version
ARG EXT_MONGODB_VERSION=1.21.0     # MongoDB driver version
ARG EXT_XDEBUG_VERSION=3.4.5       # Xdebug version
```

**Build Process:**
1. Install build dependencies
2. Compile PHP extensions
3. Install runtime dependencies
4. Clean up build artifacts
5. Verify PHP installation

**No Configuration Files:** Base images do NOT contain `app.ini`, `php-fpm.conf`, or scripts.

---

### Stage 2: Final Images (`php-node-symfony/Dockerfile.*.alpine`)

**Purpose:** Full development environment with PHP + Node.js + tools.

**Characteristics:**
- Based on: `ghcr.io/digitalspacestdio/orodc-php:X.X-alpine`
- Adds: Node.js, Composer, system tools, user creation
- Published as: `ghcr.io/digitalspacestdio/orodc-php-node-symfony:X.X-alpine`

**Multi-stage Build:**
```dockerfile
FROM node:${NODE_VERSION}-alpine AS app_node        # Node.js binaries
FROM composer:${COMPOSER_VERSION} AS composer_app   # Composer binary
FROM ghcr.io/digitalspacestdio/orodc-php:${PHP_VERSION}-alpine  # Base PHP
```

**Added Components:**

#### 1. **Node.js** (copied from `node:alpine`)
```dockerfile
COPY --from=app_node /usr/local /usr/local
COPY --from=app_node /opt /opt
```
- PHP 7.4, 8.1-8.3: Node.js 18
- PHP 8.4: Node.js 20
- PHP 8.5-rc: Node.js 22

#### 2. **Composer** (copied from `composer:2`)
```dockerfile
COPY --from=composer_app /usr/bin/composer /usr/bin/composer
ENV COMPOSER_ALLOW_SUPERUSER=1
```

#### 3. **Ofelia** (job scheduler, copied from official image)
```dockerfile
COPY --from=mcuadros/ofelia:latest /usr/bin/ofelia /usr/bin/ofelia
```

#### 4. **Configuration Files**
- `app.ini` - PHP runtime settings
- `app.opcache.ini` - OPcache configuration
- `app.msmtp.ini` - Mail relay settings
- `app.xdebug.ini` - Xdebug profiler settings
- `php-fpm.conf` - PHP-FPM pool configuration
- `msmtprc` - MSMTP runtime config
- `zshrc` - Zsh shell configuration

#### 5. **Helper Scripts**
- `docker-entrypoint.sh` - Container initialization
- `docker-healthcheck.sh` - Health monitoring
- `docker-sshd.sh` - SSH daemon manager
- `docker-psql.sh` - PostgreSQL client wrapper
- `docker-mysql.sh` - MySQL client wrapper

#### 6. **Build Scripts** (`buildX.X.sh`)

**Purpose:** Consolidate RUN commands to reduce Docker layers.

**What they do:**
1. **Install system packages:**
   ```bash
   apk add --no-cache acl ca-certificates curl bash fcgi file gettext git \
       nss-tools openssh msmtp jpegoptim pngquant optipng gifsicle \
       libstdc++ procps rsync vim micro postgresql-client mysql-client \
       util-linux patch
   ```

2. **PHP configuration setup:**
   ```bash
   mv php.ini-production php.ini  # Use production settings
   mkdir -p /var/run/php          # FPM socket directory
   ```

3. **Add edge repositories** (for latest packages):
   ```bash
   echo "http://dl-2.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories
   echo "http://dl-2.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories
   ```

4. **Install advanced tools:**
   ```bash
   apk add --no-cache shadow htop btop  # User management + monitoring
   apk add --no-cache sudo              # Privilege escalation
   apk add --no-cache zsh               # Modern shell
   ```

5. **Install Starship prompt** (modern shell prompt):
   ```bash
   wget "https://github.com/starship/starship/releases/latest/download/starship-${ARCH}.tar.gz"
   install starship /usr/local/bin/starship
   ```

6. **Setup shell completions:**
   ```bash
   composer completion bash > /etc/bash_completion.d/composer
   npm completion > /etc/bash_completion.d/npm
   ```

7. **Create developer user:**
   ```bash
   addgroup -g $PHP_GID ${PHP_USER_GROUP}
   adduser -u $PHP_UID -G ${PHP_USER_GROUP} -s /bin/sh -D ${PHP_USER_NAME}
   chown ${PHP_USER_NAME}:${PHP_USER_GROUP} /var/www
   ```

**Why separate build scripts?**
- ✅ Reduces Docker layers (one `RUN` instead of 10+)
- ✅ Easier to maintain and debug
- ✅ Conditional logic (e.g., check if composer exists)
- ✅ Better error messages with `set -ex`

**User Creation:**
- **Base images:** No user creation (pure PHP only)
- **Final images:** User created in `buildX.X.sh`
- Configurable UID/GID via build args (default: 1000)

#### 7. **Default User**
```dockerfile
USER ${PHP_USER_NAME}  # Switch to non-root user (developer)
WORKDIR ${APP_DIR}     # Set working directory (/var/www)
```

#### 8. **Git Configuration**
```dockerfile
RUN git config --global url."https://github.com/".insteadOf git@github.com: \
    && git config --global url."https://gitlab.com/".insteadOf git@gitlab.com:
```
Forces HTTPS for Git operations (Docker-friendly).

---

### Stage 3: Project Image (`project-php-node-symfony/Dockerfile.project`)

**Purpose:** Project-specific customization layer.

**Characteristics:**
- Based on: `ghcr.io/digitalspacestdio/orodc-php-node-symfony:X.X-alpine`
- Adds: Project source code, vendor dependencies, custom configuration
- Built locally, not published to registry

**Typical Usage:**
```dockerfile
FROM ghcr.io/digitalspacestdio/orodc-php-node-symfony:8.3-alpine

# Copy project files
COPY --chown=developer:developer . /var/www

# Install dependencies
RUN composer install --no-dev --optimize-autoloader
RUN npm ci --production
```

---

## 🔧 Build Process

### Local Build (Single Architecture)

**Base PHP Image:**
```bash
cd compose/docker/php
docker build -f Dockerfile.8.3.alpine -t orodc-php:8.3-alpine .
```

**Final Image:**
```bash
cd compose/docker/php-node-symfony
docker build -f Dockerfile.8.3.alpine -t orodc-php-node-symfony:8.3-alpine .
```

### CI/CD Build (Multi-Architecture)

**Architecture:** GitHub Actions workflow (`build-docker-images.yml`)

**Process:**
1. **Build Base Images** (PHP only)
   - AMD64 runner builds `linux/amd64`
   - ARM64 runner builds `linux/arm64`
   - Tags: `X.X-alpine-amd64`, `X.X-alpine-arm64`

2. **Create Multi-Arch Manifests** (Base)
   - Combine AMD64 + ARM64 images
   - Tag: `X.X-alpine` (platform-agnostic)

3. **Build Final Images** (PHP + Node.js)
   - Uses base manifest `X.X-alpine`
   - AMD64 and ARM64 runners build separately
   - Tags: `X.X-alpine-amd64`, `X.X-alpine-arm64`

4. **Create Multi-Arch Manifests** (Final)
   - Combine AMD64 + ARM64 images
   - Tag: `X.X-alpine` (platform-agnostic)

**Publishing:**
- Registry: `ghcr.io/digitalspacestdio/`
- Base images: `orodc-php:X.X-alpine`
- Final images: `orodc-php-node-symfony:X.X-alpine`

---

## 🐛 Critical Build Nuances

### 1. **Alpine Version Pinning & Node.js Compatibility**

**Problem:** Different PHP versions require different Alpine versions, and Node.js base image MUST match the PHP Alpine version to avoid `libstdc++` incompatibility (especially on ARM64).

**Solution:**
- PHP 7.4: Alpine 3.15
- PHP 8.1-8.2: Alpine 3.18
- PHP 8.3-8.5: Alpine 3.21

**CRITICAL:** The `php-node-symfony` Dockerfiles MUST use the SAME Alpine version as the base PHP image:

```dockerfile
# ✅ CORRECT - Alpine versions match
# In Dockerfile.8.5.alpine (base PHP)
ARG ALPINE_VERSION=3.21
FROM php:${PHP_VERSION}-fpm-alpine${ALPINE_VERSION}

# In php-node-symfony/8.5/Dockerfile (final image)
ARG ALPINE_VERSION=3.21
FROM node:${NODE_VERSION}-alpine${ALPINE_VERSION} AS app_node
FROM ghcr.io/digitalspacestdio/orodc-php:${PHP_VERSION}-alpine

# ❌ WRONG - Mismatched Alpine versions
# Base uses 3.21, but Node stage uses 3.18
# Causes: Error relocating /usr/local/bin/node: symbol not found
```

**Why this matters:**
- Node.js binaries are compiled against specific `libstdc++` versions
- ARM64 is particularly sensitive to C++ ABI compatibility
- Mismatched Alpine versions = incompatible `libstdc++` = Node.js crashes
- **CRITICAL:** `libstdc++` and `gcompat` MUST be installed BEFORE copying Node.js binaries (see fix below)

**Alpine Version Matrix:**

| PHP Version | Alpine Version | Base Dockerfile | Node Dockerfile |
|-------------|----------------|-----------------|-----------------|
| 7.4         | 3.15           | `Dockerfile.7.4.alpine` | `php-node-symfony/7.4/Dockerfile` |
| 8.1         | 3.18           | `Dockerfile.8.1.alpine` | `php-node-symfony/8.1/Dockerfile` |
| 8.2         | 3.18           | `Dockerfile.8.2.alpine` | `php-node-symfony/8.2/Dockerfile` |
| 8.3         | 3.21           | `Dockerfile.8.3.alpine` | `php-node-symfony/8.3/Dockerfile` |
| 8.4         | 3.21           | `Dockerfile.8.4.alpine` | `php-node-symfony/8.4/Dockerfile` |
| 8.5-rc      | 3.21           | `Dockerfile.8.5.alpine` | `php-node-symfony/8.5/Dockerfile` |

**Dockerfile Build Order Fix (ARM64):**

After splitting base and final images, Node.js ARM64 builds started failing with:
```
Error relocating /usr/local/bin/node: symbol not found
```

**Root Cause:** In the new architecture, Node.js binaries were copied BEFORE installing `libstdc++` and `gcompat`, causing the smoke test (`node --version`) to fail on ARM64.

**Solution:** Install runtime dependencies BEFORE copying Node.js binaries:

```dockerfile
# ✅ CORRECT ORDER
# 1. Install C++ runtime libraries FIRST
RUN apk add --no-cache libstdc++ gcompat

# 2. THEN copy Node.js binaries
COPY --from=app_node /usr/local /usr/local
COPY --from=app_node /opt /opt

# 3. NOW smoke test will work
RUN node --version && npm --version && yarn --version

# ❌ WRONG ORDER (old broken version)
# Copy Node.js first, then install libs later in build.sh
# Smoke test fails because libstdc++ not available yet
```

This fix was applied to ALL PHP versions (7.4, 8.1, 8.2, 8.3, 8.4, 8.5).

### 2. **IMAP Extension Handling**

**Problem:** PHP 8.4 removed built-in IMAP support.

**Solution:**
- PHP 7.4, 8.1-8.3: `docker-php-ext-install imap`
- PHP 8.4+: `pecl install imap` (PECL version)

```dockerfile
# PHP 8.3 and below
RUN docker-php-ext-install imap

# PHP 8.4+
RUN pecl install imap && docker-php-ext-enable imap
```

### 3. **Extension Version Pinning**

**Problem:** PECL extensions may break with PHP RC versions.

**Solution:**
- **Stable PHP:** Use release versions
  ```dockerfile
  RUN pecl install redis-6.2.0
  ```
- **RC/Beta PHP:** Use git commit hashes
  ```dockerfile
  RUN git clone https://github.com/phpredis/phpredis.git && \
      cd phpredis && git checkout abc123 && phpize && ./configure && make install
  ```

### 4. **Python 2 Removal**

**Problem:** Alpine 3.18+ removed `python2` package (deprecated).

**Solution:**
- PHP 7.4 (Alpine 3.16): `apk add python2` works
- PHP 8.1+ (Alpine 3.18+): Remove `python2` from build scripts

**Note:** Node.js node-sass modules may fail without Python 2, but modern projects use Dart Sass.

### 5. **User Creation Timing**

**Problem:** User must exist before `chown` operations.

**Solution:** Create user at the END of `buildX.X.sh`:
```bash
# All package installations first
apk add --no-cache ...

# User creation last
addgroup -g $PHP_GID ${PHP_USER_GROUP}
adduser -u $PHP_UID -G ${PHP_USER_GROUP} -s /bin/sh -D ${PHP_USER_NAME}
chown ${PHP_USER_NAME}:${PHP_USER_GROUP} /var/www
```

### 6. **Build Context and File Paths**

**Problem:** `COPY` commands require files in build context.

**Base images:**
```bash
cd compose/docker/php
docker build -f Dockerfile.8.3.alpine .
# No COPY commands, no files needed
```

**Final images:**
```bash
cd compose/docker/php-node-symfony
docker build -f Dockerfile.8.3.alpine .
# COPY requires app.ini, buildX.X.sh, etc. in current directory
```

### 9. **Working Directory for npm completion**

**Problem:** `npm completion` fails if run from deleted directory.

**Solution:** `cd /` before running npm completion:
```bash
rm -rf /tmp/starship
cd /                    # Reset working directory
npm completion > /etc/bash_completion.d/npm
```

### 10. **Composer in Base vs Final**

**Critical Rule:**
- **Base images (`php/`):** NO Composer (pure PHP only)
- **Final images (`php-node-symfony/`):** Composer via multi-stage build

```dockerfile
# ❌ WRONG: Composer in base image
FROM php:8.3-fpm-alpine
RUN curl -sS https://getcomposer.org/installer | php

# ✅ CORRECT: Composer in final image
FROM composer:2 AS composer_app
FROM ghcr.io/digitalspacestdio/orodc-php:8.3-alpine
COPY --from=composer_app /usr/bin/composer /usr/bin/composer
```

---

## 📋 Supported PHP Versions

| PHP Version | Alpine | Node.js | Status | Notes |
|-------------|--------|---------|--------|-------|
| 7.4 | 3.16 | 18 | Legacy | Built-in IMAP, Python 2 available |
| 8.1 | 3.18 | 18 | Stable | Built-in IMAP, no Python 2 |
| 8.2 | 3.18 | 18 | Stable | Built-in IMAP, no Python 2 |
| 8.3 | 3.18 | 18 | Stable | Built-in IMAP, no Python 2 |
| 8.4 | 3.18 | 20 | Stable | PECL IMAP, no Python 2 |
| 8.5 | 3.21 | 22 | RC/Beta | PECL IMAP, git commit versions |

---

## 🧪 Testing Images Locally

### Quick Test (Smoke Test)
```bash
docker run --rm ghcr.io/digitalspacestdio/orodc-php:8.3-alpine php --version
docker run --rm ghcr.io/digitalspacestdio/orodc-php-node-symfony:8.3-alpine node --version
```

### Interactive Shell
```bash
docker run --rm -it ghcr.io/digitalspacestdio/orodc-php-node-symfony:8.3-alpine zsh
```

### Test PHP Extensions
```bash
docker run --rm ghcr.io/digitalspacestdio/orodc-php:8.3-alpine php -m | grep -E '(redis|mongodb|xdebug|imap)'
```

### Inspect Image Size
```bash
docker images | grep orodc-php
```

**Expected Sizes:**
- Base PHP images: ~150-200 MB
- Final images: ~400-500 MB

---

## 🔍 Troubleshooting

### Build Fails: "package not found"

**Cause:** Alpine version mismatch or package name changed.

**Fix:** Check Alpine package database:
```bash
docker run --rm alpine:3.18 apk search <package-name>
```

### Build Fails: "composer: not found"

**Cause:** Composer not copied from multi-stage build.

**Fix:** Verify `COPY --from=composer_app` line exists.

### Build Fails: "addgroup: group 'developer' in use"

**Cause:** User creation runs twice (cached layer).

**Fix:** Add `--no-cache` flag:
```bash
docker build --no-cache -f Dockerfile.8.3.alpine .
```

### Build Fails: "failed to compute cache key"

**Cause:** Missing file in build context (e.g., `app.ini`).

**Fix:** Check build context:
```bash
cd compose/docker/php-node-symfony  # Correct directory
docker build -f Dockerfile.8.3.alpine .
```

### Build Fails: "wget: bad address 'github.com'"

**Cause:** Transient DNS issue in Docker builder.

**Fix:** Retry build (usually resolves itself).

---

## 🚀 Performance Optimization

### 1. **Layer Caching**

**Strategy:** Order `RUN` commands from least to most frequently changed.

```dockerfile
# ✅ GOOD: System packages first (rarely change)
RUN apk add --no-cache curl git
RUN composer install          # Changes often

# ❌ BAD: Composer first (breaks cache on every change)
RUN composer install
RUN apk add --no-cache curl git
```

### 2. **Multi-Stage Builds**

**Benefit:** Reduce final image size by excluding build tools.

```dockerfile
# Build stage (large, with build tools)
FROM php:8.3-fpm-alpine AS builder
RUN apk add --no-cache build-base
RUN pecl install redis

# Final stage (small, runtime only)
FROM php:8.3-fpm-alpine
COPY --from=builder /usr/local/lib/php/extensions /usr/local/lib/php/extensions
```

### 3. **BuildKit Cache Mounts**

**Not currently used** but can speed up builds:
```dockerfile
RUN --mount=type=cache,target=/root/.composer/cache \
    composer install
```

### 4. **Parallel Builds**

CI workflow builds multiple PHP versions simultaneously:
```yaml
strategy:
  matrix:
    php: ["8.1", "8.2", "8.3", "8.4"]
  max-parallel: 4
```

---

## 📚 Additional Resources

- **Official PHP Docker Images:** https://hub.docker.com/_/php
- **Alpine Linux Packages:** https://pkgs.alpinelinux.org/packages
- **PECL Extensions:** https://pecl.php.net/
- **Docker Multi-Platform:** https://docs.docker.com/build/building/multi-platform/
- **GitHub Actions:** `.github/workflows/build-docker-images.yml`

---

## 🛠️ Maintenance

### Adding a New PHP Version

1. **Create base Dockerfile:**
   ```bash
   cp compose/docker/php/Dockerfile.8.4.alpine compose/docker/php/Dockerfile.8.6.alpine
   ```

2. **Update version variables:**
   ```dockerfile
   ARG PHP_VERSION=8.6
   ARG ALPINE_VERSION=3.22  # Check PHP official image
   ```

3. **Create final Dockerfile:**
   ```bash
   cp compose/docker/php-node-symfony/Dockerfile.8.4.alpine compose/docker/php-node-symfony/Dockerfile.8.6.alpine
   ```

4. **Create build script:**
   ```bash
   cp compose/docker/php-node-symfony/build8.4.sh compose/docker/php-node-symfony/build8.6.sh
   ```

5. **Update CI workflow:**
   - Add `8.6` to matrix in `.github/workflows/build-docker-images.yml`

### Updating PHP Extension Versions

1. **Check latest versions:** https://pecl.php.net/
2. **Update in Dockerfile:**
   ```dockerfile
   ARG EXT_REDIS_VERSION=6.3.0  # Updated from 6.2.0
   ```
3. **Test build locally**
4. **Commit and push**

---

**Last Updated:** 2025-10-01  
**Maintained by:** OroDC Team

