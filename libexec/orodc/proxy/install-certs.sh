#!/bin/bash
set -e
if [ "$DEBUG" ]; then set -x; fi

# Determine script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${SCRIPT_DIR}/../lib/ui.sh"

# Resolve Docker binary
DOCKER_BIN=$(resolve_bin "docker" "Docker is required. Install from https://docs.docker.com/get-docker/")

msg_info "Installing CA certificate to system trust store..."

# Check if proxy container is running
if ! ${DOCKER_BIN} ps --filter "name=proxy" --format "{{.Names}}" | grep -q "^proxy$"; then
  msg_error "Proxy container is not running. Start it first with: orodc proxy up -d"
  exit 1
fi

# Wait for container to be healthy
msg_info "Waiting for proxy container to be healthy..."
for i in {1..30}; do
  if ${DOCKER_BIN} ps --filter "name=proxy" --filter "health=healthy" --format "{{.Names}}" | grep -q "^proxy$"; then
    break
  fi
  sleep 1
done

INSTALL_DATE=$(date +%Y%m%d_%H%M%S)
CERT_OUTPUT_PATH="${HOME}/root_ca_docker_local_${INSTALL_DATE}.crt"

# Export certificate content (not symlink)
${DOCKER_BIN} exec proxy cat /certs/ca.crt > "${CERT_OUTPUT_PATH}" 2>/dev/null

if [[ ! -f "${CERT_OUTPUT_PATH}" ]] || [[ ! -s "${CERT_OUTPUT_PATH}" ]]; then
  msg_error "Failed to export certificate from proxy container"
  exit 1
fi

msg_info "CA certificate exported to: ${CERT_OUTPUT_PATH}"

# Detect OS
IS_WSL=false
if grep -qi microsoft /proc/version 2>/dev/null || grep -qi wsl /proc/version 2>/dev/null; then
  IS_WSL=true
fi

# Install certificate based on OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  msg_info "Installing certificate to macOS System Keychain..."
  if sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "${CERT_OUTPUT_PATH}" 2>/dev/null; then
    msg_ok "Certificate installed to macOS System Keychain"
    rm -f "${CERT_OUTPUT_PATH}"
  else
    msg_warning "Failed to install certificate automatically. Manual installation required:"
    msg_info "  sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ${CERT_OUTPUT_PATH}"
  fi
  
elif [[ "$IS_WSL" == "true" ]]; then
  # WSL2 - install to Linux and show Windows instructions
  msg_info "Installing certificate to Linux (WSL)..."
  
  if [[ -f "/etc/debian_version" ]]; then
    # Debian/Ubuntu
    sudo cp "${CERT_OUTPUT_PATH}" /usr/local/share/ca-certificates/ 2>/dev/null && \
    sudo update-ca-certificates 2>/dev/null && \
    msg_ok "Certificate installed to Linux trust store"
  fi
  
  # NSS database for Chrome/Node.js
  if command -v certutil >/dev/null 2>&1; then
    msg_info "Installing certificate to NSS database (Chrome/Node.js)..."
    mkdir -p "${HOME}/.pki/nssdb" 2>/dev/null
    certutil -d sql:"${HOME}/.pki/nssdb" -A -t "C,," -n "OroDC Docker Local CA" -i "${CERT_OUTPUT_PATH}" 2>/dev/null && \
    msg_ok "Certificate installed to NSS database"
  else
    msg_info "For Chrome/Node.js support, install libnss3-tools:"
    msg_info "  sudo apt install libnss3-tools"
    msg_info "  mkdir -p \$HOME/.pki/nssdb"
    msg_info "  certutil -d sql:\$HOME/.pki/nssdb -N"
    msg_info "  certutil -d sql:\$HOME/.pki/nssdb -A -t \"C,,\" -n \"OroDC Docker Local CA\" -i ${CERT_OUTPUT_PATH}"
  fi
  
  msg_warning "WSL2 detected. Certificate saved to: ${CERT_OUTPUT_PATH}"
  msg_info ""
  msg_info "To trust HTTPS in Windows host:"
  msg_info "  1. Copy certificate to Windows: ${CERT_OUTPUT_PATH}"
  msg_info "  2. Double-click the .crt file in Windows Explorer"
  msg_info "  3. Click 'Install Certificate'"
  msg_info "  4. Select 'Local Machine' and click Next"
  msg_info "  5. Select 'Place all certificates in the following store'"
  msg_info "  6. Click 'Browse' and select 'Trusted Root Certification Authorities'"
  msg_info "  7. Click Next and Finish"
  msg_info ""
  
else
  # Linux (non-WSL)
  msg_info "Installing certificate to Linux trust store..."
  
  if [[ -f "/etc/debian_version" ]]; then
    # Debian/Ubuntu
    if sudo cp "${CERT_OUTPUT_PATH}" /usr/local/share/ca-certificates/ 2>/dev/null && \
       sudo update-ca-certificates 2>/dev/null; then
      msg_ok "Certificate installed to system trust store"
      rm -f "${CERT_OUTPUT_PATH}"
    else
      msg_warning "Failed to install certificate automatically. Manual installation required:"
      msg_info "  sudo cp ${CERT_OUTPUT_PATH} /usr/local/share/ca-certificates/"
      msg_info "  sudo update-ca-certificates"
    fi
  elif [[ -f "/etc/redhat-release" ]]; then
    # RHEL/CentOS/Fedora
    if sudo cp "${CERT_OUTPUT_PATH}" /etc/pki/ca-trust/source/anchors/ 2>/dev/null && \
       sudo update-ca-trust 2>/dev/null; then
      msg_ok "Certificate installed to system trust store"
      rm -f "${CERT_OUTPUT_PATH}"
    else
      msg_warning "Failed to install certificate automatically. Manual installation required:"
      msg_info "  sudo cp ${CERT_OUTPUT_PATH} /etc/pki/ca-trust/source/anchors/"
      msg_info "  sudo update-ca-trust"
    fi
  fi
  
  # NSS database for Chrome/Node.js
  if command -v certutil >/dev/null 2>&1; then
    msg_info "Installing certificate to NSS database (Chrome/Node.js)..."
    mkdir -p "${HOME}/.pki/nssdb" 2>/dev/null
    
    # Initialize NSS DB if it doesn't exist
    if [[ ! -f "${HOME}/.pki/nssdb/cert9.db" ]]; then
      certutil -d sql:"${HOME}/.pki/nssdb" -N --empty-password 2>/dev/null
    fi
    
    if certutil -d sql:"${HOME}/.pki/nssdb" -A -t "C,," -n "OroDC Docker Local CA" -i "${CERT_OUTPUT_PATH}" 2>/dev/null; then
      msg_ok "Certificate installed to NSS database"
      rm -f "${CERT_OUTPUT_PATH}"
    fi
  else
    msg_info "For Chrome/Node.js support, install libnss3-tools:"
    msg_info "  sudo apt install libnss3-tools"
    msg_info "  mkdir -p \$HOME/.pki/nssdb"
    msg_info "  certutil -d sql:\$HOME/.pki/nssdb -N"
    msg_info "  certutil -d sql:\$HOME/.pki/nssdb -A -t \"C,,\" -n \"OroDC Docker Local CA\" -i ${CERT_OUTPUT_PATH}"
  fi
fi

msg_ok "Certificate installation complete!"
