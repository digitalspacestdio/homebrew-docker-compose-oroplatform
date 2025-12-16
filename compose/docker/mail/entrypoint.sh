#!/bin/sh
set -e

# Generate certificates if they don't exist
/usr/local/bin/generate-certs.sh

# Start mailpit
exec "$@"

