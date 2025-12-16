# Proposal: Add Mail STARTTLS Support

## Change ID
`add-mail-starttls-support`

## Status
Proposed

## Summary
Add STARTTLS/TLS encryption support to the mail service (mailhog/mailpit) to enable testing of encrypted SMTP connections. The mail service will automatically generate self-signed certificates on first start and share them via a shared volume, allowing PHP containers to send encrypted mail without manual certificate configuration.

## Why
Developers need to test SMTP TLS/STARTTLS functionality locally before deploying to production. Currently, the mail service only supports unencrypted connections, causing "encryption is not supported" errors when applications are configured with TLS. This creates a testing gap where encryption-related issues only surface in production. By adding automatic certificate generation and TLS support to mailpit, developers can test the complete email encryption workflow locally, matching production behavior and catching configuration issues early.

## Motivation

### Problem
Currently, the mail service (mailhog) only supports unencrypted SMTP connections on port 1025. This creates several issues:

1. **Testing Gap**: Developers cannot test STARTTLS/TLS functionality locally before deploying to production where encryption is required
2. **Security Warnings**: Applications configured with `ORO_MAILER_ENCRYPTION=tls` fail with "encryption is not supported" errors
3. **Configuration Mismatch**: Local development environment doesn't match production SMTP encryption requirements
4. **SwiftmailerTransportFactory Errors**: OroCommerce SwiftmailerTransportFactory rejects null encryption values, requiring `sendmail` workarounds

### User Impact
- Developers spending time debugging encryption-related issues that only appear in production
- Need to maintain different mailer configurations for local vs production environments  
- Inability to test email security features (TLS version requirements, certificate validation)
- Workarounds like using sendmail instead of SMTP for local development

### Desired Outcome
A mail service that:
- Automatically generates self-signed certificates on first start
- Supports both encrypted (STARTTLS on 587, TLS on 465) and unencrypted (1025) SMTP
- Shares certificates via shared volume so PHP containers can validate connections
- Provides a consistent development-to-production configuration path
- Works with both SwiftMailer and Symfony Mailer encryption settings

## Scope

### In Scope
1. **Certificate Generation**: Mail container generates self-signed certificates on first start
2. **Shared Volume**: Certificates stored in shared volume accessible to all containers
3. **SMTP Ports**: Support for port 1025 (no TLS), 587 (STARTTLS), 465 (TLS)
4. **Migration to Mailpit**: Replace mailhog with mailpit (actively maintained, better TLS support)
5. **PHP Container Integration**: Update msmtprc to support TLS connections
6. **Environment Configuration**: Add `ORO_MAILER_ENCRYPTION` support (tls/starttls/none)
7. **Documentation**: Update README with TLS configuration examples

### Out of Scope
- Custom CA certificate import (use existing proxy CA workflow)
- Let's Encrypt or production certificate support
- SMTP authentication (AUTH LOGIN/PLAIN) - mailpit doesn't require it for dev
- Email relay to external SMTP servers
- DKIM/SPF/DMARC testing features

### Dependencies
- Existing `ssl-certificate-management` spec patterns (certificate generation, volume sharing)
- Docker Compose volume configuration
- mailpit image (replaces cd2team/mailhog)

## Alternatives Considered

### Alternative 1: Continue Using Mailhog Without TLS
**Pros**: No changes required, simple setup
**Cons**: Testing gap, encryption errors, maintenance issues (mailhog is abandoned)
**Rejected**: Doesn't solve the core problem

### Alternative 2: Use External SMTP Service (Mailtrap, Gmail)
**Pros**: Real TLS implementation, production-like
**Cons**: Requires internet, API keys, rate limits, costs, slower tests
**Rejected**: Adds external dependencies and complexity

### Alternative 3: Generate Certificates in Each PHP Container
**Pros**: No shared volume needed
**Cons**: Certificate duplication, inconsistent certs across containers, harder to debug
**Rejected**: Violates single source of truth principle

### Alternative 4: Manual Certificate Provisioning
**Pros**: User controls certificate properties
**Cons**: Poor developer experience, error-prone, breaks "zero configuration" goal
**Rejected**: Against OroDC philosophy

## Implementation Strategy

### Phase 1: Certificate Infrastructure
1. Create shared `mail-certs` Docker volume
2. Add certificate generation script to mail service entrypoint
3. Generate self-signed certificate with 1-year validity

### Phase 2: Mail Service Configuration
1. Replace mailhog with mailpit image
2. Configure mailpit with:
   - `MP_SMTP_TLS_CERT=/certs/mail.crt`
   - `MP_SMTP_TLS_KEY=/certs/mail.key`
   - Enable ports 1025 (plain), 587 (STARTTLS), 465 (TLS)
3. Add healthcheck for SMTP ports

### Phase 3: PHP Container Integration
1. Mount `mail-certs` volume in PHP containers (readonly)
2. Update msmtprc template to support TLS modes
3. Add environment variable handling for encryption type

### Phase 4: Documentation & Testing
1. Update README with TLS configuration examples
2. Add test scenarios for all three SMTP modes
3. Document certificate troubleshooting

## Success Criteria

### Functional Requirements
- [ ] Mail service generates certificates automatically on first start
- [ ] Certificates persist across container restarts
- [ ] PHP containers can send email via TLS (port 465)
- [ ] PHP containers can send email via STARTTLS (port 587)
- [ ] Unencrypted SMTP (port 1025) continues working
- [ ] `ORO_MAILER_ENCRYPTION=tls` works without errors
- [ ] msmtprc automatically uses correct TLS settings

### Non-Functional Requirements
- [ ] Certificate generation adds < 5 seconds to initial startup
- [ ] Existing projects continue working without changes
- [ ] Clear error messages if certificate generation fails
- [ ] Documentation includes TLS troubleshooting guide

### Testing Validation
- [ ] Send test email via each SMTP port (1025, 465, 587)
- [ ] Verify certificate properties (validity, CN, SAN)
- [ ] Test with `ORO_MAILER_ENCRYPTION` set to: none, tls, starttls
- [ ] Verify certificate persistence after `orodc restart`
- [ ] Test with multiple concurrent PHP containers

## Risks & Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| mailpit breaking changes | High | Low | Pin to specific version, test before upgrade |
| Certificate validation failures | Medium | Medium | Use permissive settings (tls_trust_file) |
| Port conflicts (465, 587) | Low | Low | Document port binding, add conflict detection |
| Volume mount performance | Low | Low | Certificates are read once per container start |
| Backward compatibility | Medium | Low | Keep port 1025 as default, TLS is opt-in |

## Open Questions

1. **Certificate CN/SAN**: Should certificate use `mail` or `mail.${DC_ORO_NAME}.docker.local`?
   - **Recommendation**: Use both as SAN entries for maximum compatibility
   
2. **Certificate Validity**: 1 year vs 10 years vs self-renewing?
   - **Recommendation**: 1 year, same as domain certs, with warning before expiry
   
3. **msmtprc Configuration**: Single template vs environment-based?
   - **Recommendation**: Environment-based to support all three modes dynamically

4. **Default Encryption**: Should new projects default to TLS or unencrypted?
   - **Recommendation**: Default to `tls` for new projects, document migration path

## Related Work
- Depends on: `ssl-certificate-management` (existing spec)
- Related to: `docker-image-management` (PHP container configuration)
- Enables: Future SMTP authentication testing (if needed)

## Approval Checklist
- [ ] All open questions resolved
- [ ] Design document reviewed
- [ ] Tasks list created with verification steps
- [ ] Spec deltas validated with `openspec validate --strict`
- [ ] Breaking changes identified and documented
- [ ] Migration guide drafted (if needed)

