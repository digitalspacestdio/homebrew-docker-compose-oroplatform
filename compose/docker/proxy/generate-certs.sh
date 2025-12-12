#!/bin/bash
# generate-certs.sh - Main entrypoint for certificate generation
set -e

CERT_DIR="/certs"
CA_DIR="$CERT_DIR/localCA"
DOMAIN="${CERT_DOMAIN:-docker.local}"

echo "[INFO] Certificate Generation for OroDC Proxy"
echo "[INFO] Domain: ${DOMAIN}"

# Check if CA already exists
if [[ -f "$CA_DIR/root_ca.crt" ]] && [[ -f "$CERT_DIR/${DOMAIN}.crt" ]]; then
    echo "[INFO] Certificates already exist, skipping generation"
    exit 0
fi

# Copy OpenSSL config to certs directory
cp /usr/local/etc/localCA.cnf "$CERT_DIR/localCA.cnf"

# Initialize CA if not exists
if [[ ! -f "$CA_DIR/root_ca.crt" ]]; then
    echo "[INFO] Initializing Certificate Authority..."
    /usr/local/bin/local-ca-init.sh
fi

# Generate domain certificate if not exists
if [[ ! -f "$CERT_DIR/${DOMAIN}.crt" ]]; then
    echo "[INFO] Generating certificate for *.${DOMAIN}..."
    /usr/local/bin/local-ca-crtgen.sh "${DOMAIN}"
fi

echo "[INFO] Certificate setup complete"
echo "[INFO] Root CA: $CERT_DIR/ca.crt"
echo "[INFO] Domain cert: $CERT_DIR/${DOMAIN}.crt"
echo "[INFO] Domain key: $CERT_DIR/${DOMAIN}.key"

