ARG MYSQL_VERSION=8.4

FROM mysql:${MYSQL_VERSION}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -eux; \
    if command -v microdnf >/dev/null 2>&1; then \
      # Oracle Linux - enable EPEL for pv package
      microdnf install -y oracle-epel-release-el8 || microdnf install -y oracle-epel-release-el9 || true; \
      microdnf install -y pv || echo "pv not available, skipping"; \
      microdnf clean all; \
    elif command -v yum >/dev/null 2>&1; then \
      yum install -y epel-release || true; \
      yum install -y pv || echo "pv not available, skipping"; \
      yum clean all; \
    elif command -v apt-get >/dev/null 2>&1; then \
      apt-get update -yqq; \
      apt-get install -yqq --no-install-recommends pv || echo "pv not available, skipping"; \
      apt-get clean; \
      rm -rf /var/lib/apt/lists/*; \
    else \
      echo "No supported package manager found, skipping pv installation" >&2; \
    fi
