ARG ALPINE_VERSION=3.21
ARG NODE_VERSION=18
ARG PHP_VERSION=8.4
ARG COMPOSER_VERSION=2

# Nodejs image
FROM node:${NODE_VERSION}-alpine${ALPINE_VERSION} AS app_node

# Composer image
FROM composer:${COMPOSER_VERSION} AS composer_app

# Use our base PHP image with all PHP modules pre-compiled
FROM ghcr.io/digitalspacestdio/orodc-php:${PHP_VERSION}-alpine

# Set up user environment variables (base image uses root)
ARG PHP_UID=1000
ENV PHP_UID=${PHP_UID}

ARG PHP_GID=1000
ENV PHP_GID=${PHP_GID}

ARG PHP_USER_NAME=developer
ENV PHP_USER_NAME=${PHP_USER_NAME}

ARG PHP_USER_GROUP=developer
ENV PHP_USER_GROUP=${PHP_USER_GROUP}

# Copy configuration files from shared
COPY shared/app.ini /usr/local/etc/php/conf.d/
COPY shared/app.opcache.ini /usr/local/etc/php/conf.d/
COPY shared/app.msmtp.ini /usr/local/etc/php/conf.d/
COPY shared/app.xdebug.ini /usr/local/etc/php/conf.d/
COPY shared/php-fpm.conf /usr/local/etc/php-fpm.conf

# Copy scripts from shared
COPY --chmod=0755 shared/docker-healthcheck.sh /usr/local/bin/docker-healthcheck
COPY --chmod=0755 shared/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
COPY --chmod=0755 shared/docker-sshd.sh /usr/local/bin/docker-sshd
COPY --chmod=0755 shared/docker-psql.sh /usr/local/bin/psql
COPY --chmod=0755 shared/docker-mysql.sh /usr/local/bin/mysql

ENTRYPOINT ["docker-entrypoint"]

# Install runtime dependencies for Node.js BEFORE copying binaries (ARM64 compatibility)
RUN apk add --no-cache libstdc++ gcompat

# Copy nodejs binaries
COPY --from=app_node /usr/local /usr/local
COPY --from=app_node /opt /opt

# Smoke test for Node.js
RUN node --version && npm --version && yarn --version

# Copy ofelia binary
COPY --from=mcuadros/ofelia:latest /usr/bin/ofelia /usr/bin/ofelia

# Install composer
# https://getcomposer.org/doc/03-cli.md#composer-allow-superuser
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV PATH="${PATH}:/root/.composer/vendor/bin"
COPY --from=composer_app /usr/bin/composer /usr/bin/composer

# Copy build script and run it (creates user and installs packages)
COPY --chmod=0755 8.4/build.sh /tmp/build.sh
ARG APP_DIR="/var/www"
ENV APP_DIR=${APP_DIR}
RUN /tmp/build.sh && rm /tmp/build.sh

# Copy additional configuration files from shared
COPY shared/zshrc /.zshrc

WORKDIR ${APP_DIR}
USER ${PHP_USER_NAME}

# Configure git to use HTTPS instead of SSH for GitHub and GitLab
RUN git config --global url."https://github.com/".insteadOf git@github.com: \
    && git config --global url."https://gitlab.com/".insteadOf git@gitlab.com:

VOLUME "/home/${PHP_USER_NAME}" "/root" "${APP_DIR}"
# No default CMD - each service defines its own command (php-fpm, consumer, docker-sshd, etc)