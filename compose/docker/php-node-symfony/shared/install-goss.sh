#!/bin/sh
# Install Goss into /usr/local/bin for orodc doctor checks.
# Pin version: goss v0.4.10+ ships goreleaser archives (goss_<ver>_linux_<arch>.tar.gz).
set -eu

GOSS_VERSION="${GOSS_VERSION:-0.4.10}"

ARCH="$(uname -m)"
case "${ARCH}" in
  x86_64) GOSS_ARCH="x86_64" ;;
  aarch64 | arm64) GOSS_ARCH="arm64" ;;
  armv7l | armv6l) GOSS_ARCH="armv6" ;;
  *) GOSS_ARCH="x86_64" ;;
esac

echo "Installing Goss ${GOSS_VERSION} for architecture: ${ARCH} (goss_${GOSS_VERSION}_linux_${GOSS_ARCH}.tar.gz)"
apk add --no-cache curl ca-certificates tar
curl -fsSL "https://github.com/goss-org/goss/releases/download/v${GOSS_VERSION}/goss_${GOSS_VERSION}_linux_${GOSS_ARCH}.tar.gz" \
  | tar -xz -C /usr/local/bin goss
chmod +x /usr/local/bin/goss
goss --version
