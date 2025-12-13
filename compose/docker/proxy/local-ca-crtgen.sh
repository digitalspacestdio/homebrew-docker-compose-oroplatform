#!/bin/bash
# local-ca-crtgen.sh
set -e

if [[ -z $1 ]]; then
    echo "Usage: $0 <domain>"
    echo "Example: $0 docker.local"
    exit 1
fi

CERT_DIR="/certs"
CA_DIR="$CERT_DIR/localCA"
DOMAIN="$1"

# Sanitize domain name
DOMAIN_SAFE=$(echo "$DOMAIN" | sed -e 's/[^A-Za-z0-9._-]/_/g')

if [[ "$DOMAIN_SAFE" != "$DOMAIN" ]]; then
    echo "[ERROR] Invalid domain name: $DOMAIN"
    exit 1
fi

echo "[INFO] Generating certificate for *.${DOMAIN}..."

# Create domain-specific OpenSSL config
cat > "$CA_DIR/${DOMAIN}.cnf" <<EOM
[ req ]
prompt = no
distinguished_name = server_distinguished_name
req_extensions = v3_req

[ server_distinguished_name ]
commonName = *.${DOMAIN}
stateOrProvinceName = Local
countryName = US
emailAddress = root@${DOMAIN}
organizationName = OroDC
organizationalUnitName = Development

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[ alt_names ]
DNS.0 = *.${DOMAIN}
DNS.1 = ${DOMAIN}
EOM

# Generate private key and certificate request
export OPENSSL_CONF="$CA_DIR/${DOMAIN}.cnf"
openssl req -newkey rsa:2048 \
    -keyout "$CA_DIR/private/${DOMAIN}_key.pem" \
    -keyform PEM \
    -out "$CA_DIR/${DOMAIN}_req.pem" \
    -outform PEM \
    -nodes

# Extract clean key (without extra headers)
openssl rsa < "$CA_DIR/private/${DOMAIN}_key.pem" > "$CA_DIR/private/${DOMAIN}.key"
chmod 600 "$CA_DIR/private/${DOMAIN}.key"

# Sign certificate with CA
export OPENSSL_CONF="$CERT_DIR/localCA.cnf"
openssl ca -batch \
    -in "$CA_DIR/${DOMAIN}_req.pem" \
    -out "$CA_DIR/certs/${DOMAIN}.crt"

# Cleanup temporary files
rm -f "$CA_DIR/${DOMAIN}_req.pem"
rm -f "$CA_DIR/private/${DOMAIN}_key.pem"

echo "[INFO] Certificate generated successfully:"
echo "  Certificate: $CA_DIR/certs/${DOMAIN}.crt"
echo "  Private Key: $CA_DIR/private/${DOMAIN}.key"

# Create symlinks in /certs root for Traefik compatibility
ln -sf "$CA_DIR/root_ca.crt" "$CERT_DIR/ca.crt"
ln -sf "$CA_DIR/private/cakey.pem" "$CERT_DIR/ca.key"
ln -sf "$CA_DIR/certs/${DOMAIN}.crt" "$CERT_DIR/${DOMAIN}.crt"
ln -sf "$CA_DIR/private/${DOMAIN}.key" "$CERT_DIR/${DOMAIN}.key"

