#!/bin/sh
set -e

CERT_DIR="/certs"
CERT_FILE="$CERT_DIR/mail.crt"
KEY_FILE="$CERT_DIR/mail.key"

# Skip if certificates exist
if [ -f "$CERT_FILE" ] && [ -f "$KEY_FILE" ]; then
    echo "[INFO] Mail certificates exist, skipping generation"
    exit 0
fi

echo "[INFO] Generating self-signed mail certificate..."

# Create certificate directory
mkdir -p "$CERT_DIR"

# Generate certificate with SAN
openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout "$KEY_FILE" \
    -out "$CERT_FILE" \
    -days 365 \
    -subj "/CN=mail" \
    -addext "subjectAltName=DNS:mail,DNS:mail.*.docker.local,DNS:localhost"

# Set permissions
chmod 644 "$CERT_FILE"
chmod 600 "$KEY_FILE"

echo "[INFO] Certificate generation complete"
echo "[INFO]   Certificate: $CERT_FILE"
echo "[INFO]   Private key: $KEY_FILE"

