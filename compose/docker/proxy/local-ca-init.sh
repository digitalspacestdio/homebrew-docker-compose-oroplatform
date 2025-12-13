#!/bin/bash
# local-ca-init.sh
set -e

CERT_DIR="/certs"
CA_DIR="$CERT_DIR/localCA"

export OPENSSL_CONF="$CERT_DIR/localCA.cnf"

echo "[INFO] Initializing Local CA structure..."

# Create CA directory structure
mkdir -p "$CA_DIR/certs"
mkdir -p "$CA_DIR/newcerts"
mkdir -p "$CA_DIR/crl"
mkdir -p "$CA_DIR/private"

# Initialize CA database files
echo "01" > "$CA_DIR/serial"
echo "unique_subject = no" > "$CA_DIR/index.txt.attr"
echo -n "" > "$CA_DIR/index.txt"

# Generate Root CA certificate (10 years validity)
openssl req -x509 -sha256 -newkey rsa:2048 -nodes -days 3650 \
    -keyout "$CA_DIR/private/cakey.pem" \
    -out "$CA_DIR/root_ca.crt" \
    -subj "/C=US/ST=Local/L=Local/O=OroDC/OU=Development/CN=OroDC Local CA/emailAddress=root@localhost"

chmod 600 "$CA_DIR/private/cakey.pem"

echo "[INFO] Root CA certificate generated:"
echo "  Certificate: $CA_DIR/root_ca.crt"
echo "  Private Key: $CA_DIR/private/cakey.pem"

