ARG MYSQL_VERSION=8.4

FROM mysql:${MYSQL_VERSION}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -eux; \
    if command -v microdnf >/dev/null 2>&1; then \
      microdnf install -y pv; \
      microdnf clean all; \
    elif command -v yum >/dev/null 2>&1; then \
      yum install -y pv; \
      yum clean all; \
    elif command -v apt-get >/dev/null 2>&1; then \
      apt-get update -yqq; \
      apt-get install -yqq --no-install-recommends pv; \
      apt-get clean; \
      rm -rf /var/lib/apt/lists/*; \
    else \
      echo "No supported package manager found for pv installation" >&2; \
      exit 1; \
    fi
