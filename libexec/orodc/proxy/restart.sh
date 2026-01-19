#!/bin/bash
set -e
if [ "$DEBUG" ]; then set -x; fi

# Determine script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
source "${SCRIPT_DIR}/../lib/ui.sh"

# Restart proxy: down then up
msg_info "Restarting proxy services..."

# Stop proxy
"${SCRIPT_DIR}/down.sh" "$@" || {
  msg_error "Failed to stop proxy services"
  exit 1
}

# Start proxy
"${SCRIPT_DIR}/up.sh" "$@" || {
  msg_error "Failed to start proxy services"
  exit 1
}
