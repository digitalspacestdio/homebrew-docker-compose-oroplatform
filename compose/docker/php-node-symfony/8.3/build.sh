#!/bin/ash
set -ex

echo "=== OroDC PHP 8.3 Final Image Build Script ==="

# Install additional packages for full OroDC functionality
apk add --no-cache \
    acl \
    ca-certificates \
    curl \
    bash \
    fcgi \
    file \
    gettext \
    git \
    nss-tools \
    openssh \
    msmtp-openrc \
    msmtp \
    jpegoptim \
    pngquant \
    optipng \
    gifsicle \
    libxext \
    libxrender \
    libxtst \
    libxi \
    freetype \
    procps \
    rsync \
    vim \
    micro \
    postgresql-client \
    mysql-client \
    util-linux \
    patch

# PHP configuration setup
rm -f /usr/local/etc/php/conf.d/app.prod.ini
if [ -f "/usr/local/etc/php/php.ini" ]; then
    mv "/usr/local/etc/php/php.ini" "/usr/local/etc/php/php.ini-production"
fi
if [ -f "/usr/local/etc/php/php.ini-development" ]; then
    mv "/usr/local/etc/php/php.ini-development" "/usr/local/etc/php/php.ini"
fi

# Create /var/run/php directory
mkdir -p /var/run/php

# Add edge repositories for additional packages
echo "http://dl-2.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories
echo "http://dl-2.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories

# Install packages from edge repositories
apk add --no-cache \
    shadow \
    htop \
    btop \
    su-exec

# Install sudo and configure permissions
apk add --no-cache sudo
echo "developer ALL=(ALL) ALL" >> /etc/sudoers

# Install and configure Zsh + Starship
apk add --no-cache zsh

# Install Starship prompt
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="x86_64-unknown-linux-musl" ;;
    aarch64) ARCH="aarch64-unknown-linux-musl" ;;
    *) echo "Unsupported arch: $ARCH" && exit 1 ;;
esac

mkdir -p /tmp/starship && cd /tmp/starship
wget -q "https://github.com/starship/starship/releases/latest/download/starship-${ARCH}.tar.gz"
tar -xzf "starship-${ARCH}.tar.gz"
install starship /usr/local/bin/starship
rm -rf /tmp/starship
cd /

# Setup bash completion
mkdir -p /etc/bash_completion.d
if command -v composer >/dev/null 2>&1; then
    composer completion bash > /etc/bash_completion.d/composer 2>/dev/null || true
fi
if command -v npm >/dev/null 2>&1; then
    npm completion > /etc/bash_completion.d/npm 2>/dev/null || true
fi

# Create symlinks for image optimization tools
ln -s /usr/bin/pngquant /usr/local/bin/
ln -s /usr/bin/jpegoptim /usr/local/bin/

# Create developer user with configurable UID/GID
echo "=== Creating developer user ==="
addgroup -g $PHP_GID ${PHP_USER_GROUP}
adduser -u $PHP_UID -G ${PHP_USER_GROUP} -s /bin/sh -D ${PHP_USER_NAME}
rm -rf /var/www/*
chown ${PHP_USER_NAME}:${PHP_USER_GROUP} /var/www

echo "=== Build completed successfully ==="
