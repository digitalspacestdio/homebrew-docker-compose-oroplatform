# Stage 1: Copy SOCKS5 binary from ready-made image
FROM serjs/go-socks5-proxy:latest AS socks5-binary

# Stage 2: Final image
FROM alpine:latest

# Install system dependencies
RUN apk add --no-cache \
    ca-certificates \
    bash \
    openssl \
    curl \
    tzdata \
    xz

# Set architecture variables for multi-arch support
ARG TARGETARCH
ENV ARCH=${TARGETARCH:-amd64}

# Download Traefik v3 (latest)
RUN TRAEFIK_VERSION=$(curl -s https://api.github.com/repos/traefik/traefik/releases/latest | grep tag_name | cut -d '"' -f 4) && \
    wget -O /tmp/traefik.tar.gz \
    "https://github.com/traefik/traefik/releases/download/${TRAEFIK_VERSION}/traefik_${TRAEFIK_VERSION}_linux_${ARCH}.tar.gz" && \
    tar -xzf /tmp/traefik.tar.gz -C /usr/local/bin && \
    chmod +x /usr/local/bin/traefik && \
    rm /tmp/traefik.tar.gz

# Install s6-overlay v3
ARG S6_OVERLAY_VERSION=3.1.6.2
RUN case ${TARGETARCH} in \
        "amd64")  S6_ARCH=x86_64  ;; \
        "arm64")  S6_ARCH=aarch64 ;; \
        *)        S6_ARCH=x86_64  ;; \
    esac && \
    wget -O /tmp/s6-overlay-noarch.tar.xz \
        "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" && \
    wget -O /tmp/s6-overlay-arch.tar.xz \
        "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.xz" && \
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-arch.tar.xz && \
    rm /tmp/s6-overlay-*.tar.xz

# Copy pre-built SOCKS5 binary from serjs/go-socks5-proxy image
COPY --from=socks5-binary /socks5 /usr/local/bin/socks5
RUN chmod +x /usr/local/bin/socks5

# Create directories
RUN mkdir -p /certs /etc/traefik /usr/local/etc

# Copy CA configuration and certificate generation scripts
COPY localCA.cnf /usr/local/etc/localCA.cnf
COPY local-ca-init.sh /usr/local/bin/local-ca-init.sh
COPY local-ca-crtgen.sh /usr/local/bin/local-ca-crtgen.sh
COPY generate-certs.sh /usr/local/bin/generate-certs.sh
COPY dns-sync.sh /usr/local/bin/dns-sync.sh
RUN chmod +x /usr/local/bin/*.sh

# Copy Traefik configuration and s6 service definitions
COPY traefik.yml /etc/traefik/traefik.yml
COPY s6-rc.d/ /etc/s6-overlay/s6-rc.d/

# Expose ports
EXPOSE 80 443

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD traefik healthcheck --ping || exit 1

# s6-overlay as init system (PID 1)
ENTRYPOINT ["/init"]

