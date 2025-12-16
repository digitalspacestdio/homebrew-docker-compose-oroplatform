FROM axllent/mailpit:latest

# Install openssl for certificate generation
RUN apk add --no-cache openssl

# Copy certificate generation script
COPY generate-certs.sh /usr/local/bin/generate-certs.sh
RUN chmod +x /usr/local/bin/generate-certs.sh

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/mailpit"]

