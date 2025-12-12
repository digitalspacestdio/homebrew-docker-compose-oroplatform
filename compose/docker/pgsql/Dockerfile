ARG PG_VERSION=15.1

FROM postgres:${PG_VERSION}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install PostgreSQL extensions if available for this version
# The script automatically detects the major version and installs the appropriate packages
# hadolint ignore=DL3008
RUN set -eux; \
    apt-get update -yqq; \
    # Extract major version from pg_config
    PG_MAJOR=$(pg_config --version | sed 's/^PostgreSQL \([0-9]\+\).*/\1/'); \
    echo "Detected PostgreSQL major version: $PG_MAJOR"; \
    # Try to install pgpool2 for this version
    if apt-cache show "postgresql-${PG_MAJOR}-pgpool2" >/dev/null 2>&1; then \
        echo "Installing postgresql-${PG_MAJOR}-pgpool2..."; \
        apt-get install -yqq --no-install-recommends "postgresql-${PG_MAJOR}-pgpool2"; \
        echo "postgresql-${PG_MAJOR}-pgpool2 installed successfully"; \
    else \
        echo "postgresql-${PG_MAJOR}-pgpool2 not available in repository, skipping..."; \
    fi; \
    # Try to install pg_repack for this version
    if apt-cache show "postgresql-${PG_MAJOR}-repack" >/dev/null 2>&1; then \
        echo "Installing postgresql-${PG_MAJOR}-repack..."; \
        apt-get install -yqq --no-install-recommends "postgresql-${PG_MAJOR}-repack"; \
        echo "postgresql-${PG_MAJOR}-repack installed successfully"; \
    else \
        echo "postgresql-${PG_MAJOR}-repack not available in repository, skipping..."; \
    fi; \
    # Clean up
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# Preserve the original entrypoint
ENTRYPOINT ["docker-entrypoint.sh"]

# Default command
CMD ["postgres"]

