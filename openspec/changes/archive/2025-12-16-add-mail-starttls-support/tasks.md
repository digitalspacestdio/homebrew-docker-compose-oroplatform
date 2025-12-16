# Tasks: Add Mail STARTTLS Support

## Task List

### Phase 1: Certificate Infrastructure (3 tasks)

#### Task 1.1: Create mail-certs shared volume - [x]
**Objective**: Add Docker volume for certificate storage

**Steps**:
1. Add `mail-certs` volume definition to `compose/docker-compose.yml`
2. Add `mail-certs` volume to `compose/docker-compose-test.yml`
3. Document volume purpose in inline comments

**Verification**:
```bash
# Volume appears in docker volume ls
docker volume ls | grep mail-certs

# Volume can be inspected
docker volume inspect <project>_mail-certs
```

**Files Modified**:
- `compose/docker-compose.yml`
- `compose/docker-compose-test.yml`

**Dependencies**: None

---

#### Task 1.2: Create certificate generation script - [x]
**Objective**: Script to generate self-signed mail certificate

**Steps**:
1. Create `compose/docker/mail/generate-certs.sh`
2. Add OpenSSL command for RSA 2048-bit certificate
3. Set CN=mail, SAN entries for mail.*.docker.local
4. Add skip logic if certificates already exist
5. Set file permissions (644 for .crt, 600 for .key)
6. Make script executable

**Verification**:
```bash
# Script executes without errors
sh compose/docker/mail/generate-certs.sh

# Certificate files created
test -f /certs/mail.crt && test -f /certs/mail.key

# Certificate has correct CN
openssl x509 -in /certs/mail.crt -noout -subject | grep "CN=mail"

# Certificate has SAN entries
openssl x509 -in /certs/mail.crt -noout -ext subjectAltName | grep mail
```

**Files Created**:
- `compose/docker/mail/generate-certs.sh`

**Dependencies**: None

---

#### Task 1.3: Create mail service Dockerfile - [x]
**Objective**: Custom mail image with certificate generation

**Steps**:
1. Create `compose/docker/mail/Dockerfile`
2. Base on `axllent/mailpit:latest`
3. Copy `generate-certs.sh` to `/usr/local/bin/`
4. Create entrypoint script that runs cert generation then mailpit
5. Set working directory to `/certs`

**Verification**:
```bash
# Image builds successfully
docker build -t orodc-mailpit compose/docker/mail/

# Script is executable in image
docker run --rm orodc-mailpit ls -la /usr/local/bin/generate-certs.sh

# Entrypoint exists
docker run --rm orodc-mailpit cat /entrypoint.sh
```

**Files Created**:
- `compose/docker/mail/Dockerfile`
- `compose/docker/mail/entrypoint.sh`

**Dependencies**: Task 1.2

---

### Phase 2: Mail Service Configuration (3 tasks)

#### Task 2.1: Update mail service in docker-compose.yml - [x]
**Objective**: Configure mailpit with TLS support

**Steps**:
1. Replace `image: cd2team/mailhog` with custom build
2. Add build context pointing to `compose/docker/mail`
3. Mount `mail-certs:/certs` volume (read-write)
4. Add mailpit environment variables:
   - `MP_SMTP_BIND_ADDR=0.0.0.0:1025`
   - `MP_SMTP_TLS_BIND_ADDR=:465`
   - `MP_SMTP_TLS_CERT=/certs/mail.crt`
   - `MP_SMTP_TLS_KEY=/certs/mail.key`
   - `MP_SMTP_AUTH_ACCEPT_ANY=1`
   - `MP_WEBROOT=/mailbox`
5. Expose port 465 (SMTPS) in addition to 1025
6. Add environment variable `DC_ORO_PORT_MAIL_SMTPS` with default 30465

**Verification**:
```bash
# Service builds and starts
orodc up -d mail

# Ports are exposed
docker ps | grep mail | grep "1025.*465"

# Certificates generated
docker exec <mail_container> ls -la /certs/

# mailpit web UI accessible
curl -s http://localhost:8025/api/v1/info | jq .version
```

**Files Modified**:
- `compose/docker-compose.yml`

**Dependencies**: Task 1.1, Task 1.3

---

#### Task 2.2: Update mail healthcheck - [x]
**Objective**: Verify both SMTP ports are healthy

**Steps**:
1. Update healthcheck command to test ports 1025 and 465
2. Increase `start_period` to 10s (allow time for cert generation)
3. Keep `interval: 5s` and `retries: 18`

**Verification**:
```bash
# Healthcheck passes
docker ps | grep mail | grep "healthy"

# Both ports listening
docker exec <mail_container> nc -zv localhost 1025
docker exec <mail_container> nc -zv localhost 465

# Healthcheck logs show no errors
docker inspect <mail_container> | jq '.[0].State.Health.Log[-1]'
```

**Files Modified**:
- `compose/docker-compose.yml`

**Dependencies**: Task 2.1

---

#### Task 2.3: Update README with TLS port documentation - [x]
**Objective**: Document new SMTP ports and TLS configuration

**Steps**:
1. Add section "📧 Mail & Debugging" to README.md
2. Document three SMTP modes:
   - Port 1025: Unencrypted
   - Port 587: STARTTLS (via port 1025 + STARTTLS command)
   - Port 465: Implicit TLS
3. Add examples for each encryption type
4. Add troubleshooting section for certificate errors

**Verification**:
```bash
# README renders correctly
grep -A10 "Mail & Debugging" README.md

# Examples are valid YAML
yq eval 'select(.services.mail)' README.md
```

**Files Modified**:
- `README.md`

**Dependencies**: Task 2.1

---

### Phase 3: PHP Container Integration (4 tasks)

#### Task 3.1: Mount mail-certs volume in PHP containers - [x]
**Objective**: Give PHP containers read-only access to certificates

**Steps**:
1. Add `mail-certs:/certs:ro` volume mount to:
   - `fpm` service
   - `cli` service
   - `consumer` service
   - `websocket` service
   - `ssh` service
2. Verify mount is read-only (`:ro` suffix)

**Verification**:
```bash
# Volumes mounted in all PHP containers
for svc in fpm cli consumer websocket ssh; do
  docker inspect <project>_${svc} | jq '.[0].Mounts[] | select(.Destination=="/certs")'
done

# Mount is read-only
docker exec <fpm_container> touch /certs/test.txt 2>&1 | grep "Read-only"

# Certificate files accessible
docker exec <fpm_container> cat /certs/mail.crt | grep "BEGIN CERTIFICATE"
```

**Files Modified**:
- `compose/docker-compose.yml`

**Dependencies**: Task 1.1, Task 2.1

---

#### Task 3.2: Create msmtprc templates for each encryption mode - [x]
**Objective**: Support none/tls/starttls encryption modes

**Steps**:
1. Create `compose/docker/php-node-symfony/shared/msmtprc-none.tmpl`
   - Port 1025, tls off
2. Create `compose/docker/php-node-symfony/shared/msmtprc-tls.tmpl`
   - Port 465, tls on, tls_starttls off
3. Create `compose/docker/php-node-symfony/shared/msmtprc-starttls.tmpl`
   - Port 587, tls on, tls_starttls on
4. All templates: `tls_trust_file /certs/mail.crt`, `tls_certcheck off`

**Verification**:
```bash
# Template files exist
test -f compose/docker/php-node-symfony/shared/msmtprc-none.tmpl
test -f compose/docker/php-node-symfony/shared/msmtprc-tls.tmpl
test -f compose/docker/php-node-symfony/shared/msmtprc-starttls.tmpl

# Templates have correct port numbers
grep "port 1025" msmtprc-none.tmpl
grep "port 465" msmtprc-tls.tmpl
grep "port 587" msmtprc-starttls.tmpl
```

**Files Created**:
- `compose/docker/php-node-symfony/shared/msmtprc-none.tmpl`
- `compose/docker/php-node-symfony/shared/msmtprc-tls.tmpl`
- `compose/docker/php-node-symfony/shared/msmtprc-starttls.tmpl`

**Dependencies**: None (can be done in parallel with Task 3.1)

---

#### Task 3.3: Update PHP container entrypoint for dynamic msmtprc - [x]
**Objective**: Select correct msmtprc based on ORO_MAILER_ENCRYPTION

**Steps**:
1. Update PHP container Dockerfile to copy all three templates
2. Modify entrypoint script (or create if missing) to:
   - Read `$ORO_MAILER_ENCRYPTION` environment variable
   - Default to empty string if unset
   - Copy appropriate template to `/.msmtprc`:
     - Empty or "none" → msmtprc-none.tmpl
     - "tls" → msmtprc-tls.tmpl
     - "starttls" → msmtprc-starttls.tmpl
   - Log which template was selected
3. Ensure entrypoint runs before CMD

**Verification**:
```bash
# Test none encryption
docker run --rm -e ORO_MAILER_ENCRYPTION=none <php_image> cat /.msmtprc | grep "port 1025"

# Test tls encryption
docker run --rm -e ORO_MAILER_ENCRYPTION=tls <php_image> cat /.msmtprc | grep "port 465"

# Test starttls encryption
docker run --rm -e ORO_MAILER_ENCRYPTION=starttls <php_image> cat /.msmtprc | grep "port 587"

# Test default (empty)
docker run --rm <php_image> cat /.msmtprc | grep "port 1025"
```

**Files Modified**:
- `compose/docker/php-node-symfony/8.1/Dockerfile` (and other versions)
- `compose/docker/php-node-symfony/shared/entrypoint.sh` (create if missing)

**Dependencies**: Task 3.2

---

#### Task 3.4: Update docker-compose default environment variables - [x]
**Objective**: Set sensible defaults for mailer configuration

**Steps**:
1. Update `ORO_MAILER_ENCRYPTION` default from `:-null` to `:-`  (empty string)
2. Keep `ORO_MAILER_HOST` default as `mail`
3. Keep `ORO_MAILER_PORT` default as `1025` (backward compat)
4. Document that users can override with:
   - `ORO_MAILER_PORT=587` and `ORO_MAILER_ENCRYPTION=starttls`
   - `ORO_MAILER_PORT=465` and `ORO_MAILER_ENCRYPTION=tls`

**Verification**:
```bash
# Default environment is unencrypted
orodc config | grep ORO_MAILER_ENCRYPTION | grep '""'

# User can override via .env.orodc
echo "ORO_MAILER_ENCRYPTION=tls" >> .env.orodc
orodc config | grep ORO_MAILER_ENCRYPTION | grep 'tls'
```

**Files Modified**:
- `compose/docker-compose.yml`
- `.env.orodc` (user-facing, document in README)

**Dependencies**: Task 3.3

---

### Phase 4: Testing & Documentation (4 tasks)

#### Task 4.1: Add Goss tests for mail service
**Objective**: Automated validation of mail service TLS

**Steps**:
1. Create `compose/docker/mail/goss.yaml`
2. Add tests for:
   - Ports 1025 and 465 listening
   - Certificate files exist with correct permissions
   - Certificate validity (not expired)
   - Certificate CN and SAN entries
   - mailpit process running
3. Add to CI pipeline (GitHub Actions)

**Verification**:
```bash
# Goss tests pass locally
cd compose/docker/mail && goss validate

# Tests run in CI
cat .github/workflows/test-infrastructure.yml | grep mail/goss.yaml
```

**Files Created**:
- `compose/docker/mail/goss.yaml`

**Files Modified**:
- `.github/workflows/test-infrastructure.yml`

**Dependencies**: Task 2.1

---

#### Task 4.2: Add integration test script
**Objective**: Manual test script for all SMTP modes

**Steps**:
1. Create `tests/mail-tls-test.sh`
2. Script sends test emails via:
   - Port 1025 (unencrypted)
   - Port 465 (TLS)
   - Port 587 (STARTTLS)
3. Verify all three emails appear in mailpit API
4. Check each email for expected subject line
5. Add exit code 0 on success, 1 on failure

**Verification**:
```bash
# Script executes without errors
bash tests/mail-tls-test.sh

# All three emails sent
curl -s http://localhost:8025/api/v1/messages | jq '.total' | grep 3

# Script fails if mail service down
orodc stop mail
bash tests/mail-tls-test.sh; echo $?  # Should be 1
```

**Files Created**:
- `tests/mail-tls-test.sh`

**Dependencies**: Task 2.1, Task 3.4

---

#### Task 4.3: Update README with complete TLS examples - [x]
**Objective**: Comprehensive user documentation

**Steps**:
1. Add "SMTP TLS Configuration" section to README
2. Include `.env.orodc` examples for each mode
3. Add msmtp command-line testing examples
4. Document certificate troubleshooting:
   - "certificate verify failed" → check `/certs/mail.crt` exists
   - "connection refused" → check port binding
   - "wrong version number" → mismatched port/encryption
5. Add FAQ section for common TLS issues

**Verification**:
```bash
# README has TLS section
grep "SMTP TLS Configuration" README.md

# Examples are valid
grep -A5 "ORO_MAILER_ENCRYPTION" README.md | grep -E "(none|tls|starttls)"

# Troubleshooting section exists
grep "Troubleshooting" README.md | grep -i tls
```

**Files Modified**:
- `README.md`

**Dependencies**: Task 4.2

---

#### Task 4.4: Update CHANGELOG - [x]
**Objective**: Document changes for users

**Steps**:
1. Add entry to `CHANGELOG.md` (or create if missing)
2. Document:
   - **Added**: TLS/STARTTLS support for mail service
   - **Changed**: Replaced mailhog with mailpit
   - **Added**: Ports 465 and 587 for encrypted SMTP
   - **Added**: `ORO_MAILER_ENCRYPTION` environment variable
3. Include migration notes:
   - Existing projects: No changes required, backward compatible
   - New projects: TLS available via environment variables
   - Breaking: None (mailhog→mailpit is API compatible)

**Verification**:
```bash
# CHANGELOG has entry
grep -A10 "TLS/STARTTLS" CHANGELOG.md

# Migration notes present
grep "migration" CHANGELOG.md -i
```

**Files Modified** (or Created):
- `CHANGELOG.md`

**Dependencies**: All previous tasks

---

## Task Summary

### Total Tasks: 14
- Phase 1 (Infrastructure): 3 tasks
- Phase 2 (Mail Service): 3 tasks  
- Phase 3 (PHP Integration): 4 tasks
- Phase 4 (Testing & Docs): 4 tasks

### Estimated Timeline
- Phase 1: 2-3 hours
- Phase 2: 3-4 hours
- Phase 3: 4-5 hours
- Phase 4: 2-3 hours
- **Total**: 11-15 hours

### Parallel Work Opportunities
- Task 1.2 and 1.3 can be done together (certificate script + Dockerfile)
- Task 3.1 and 3.2 are independent (volume mounts vs templates)
- Task 4.1, 4.2, 4.3 can be split among developers

### Critical Path
1.1 → 1.2 → 1.3 → 2.1 → 2.2 → 3.1 → 3.3 → 3.4 → 4.2 → 4.3 → 4.4

### Risk Areas
- **Task 2.1**: mailpit API compatibility with mailhog (test web UI)
- **Task 3.3**: Entrypoint script complexity (bash quoting, error handling)
- **Task 4.2**: Race conditions in email sending (add sleep between sends)

## Definition of Done

Each task is considered complete when:
- [ ] Code changes implemented
- [ ] Verification commands pass
- [ ] No linter errors introduced
- [ ] Manual testing successful
- [ ] Documentation updated (if user-facing)
- [ ] Committed with descriptive message following convention
- [ ] PR created with task reference (if using GitHub)

