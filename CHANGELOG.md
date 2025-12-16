# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- TLS/STARTTLS support for mail service
- Ports 465 (implicit TLS) and 587 (STARTTLS) for encrypted SMTP connections
- `ORO_MAILER_ENCRYPTION` environment variable to configure encryption mode (none/tls/starttls)
- Automatic self-signed certificate generation for mail service TLS
- `mail-certs` Docker volume for sharing certificates between containers

### Changed
- Replaced MailHog with Mailpit (actively maintained, better TLS support)
- Mail service now supports multiple SMTP ports: 1025 (unencrypted), 465 (TLS), 587 (STARTTLS)
- PHP containers dynamically configure msmtprc based on `ORO_MAILER_ENCRYPTION` environment variable

### Migration Notes
- **Existing projects**: No changes required, fully backward compatible
  - Default behavior unchanged: unencrypted SMTP on port 1025
  - Mailpit API is compatible with MailHog, web UI accessible at same paths
- **New projects**: TLS encryption available via environment variables
  - Set `ORO_MAILER_PORT=587` and `ORO_MAILER_ENCRYPTION=starttls` for STARTTLS
  - Set `ORO_MAILER_PORT=465` and `ORO_MAILER_ENCRYPTION=tls` for implicit TLS
- **Breaking changes**: None (MailHog → Mailpit migration is API compatible)

