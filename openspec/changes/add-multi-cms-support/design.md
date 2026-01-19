## Context

OroDC currently has a hybrid architecture:
- Base services (FPM, CLI, Nginx, Database, Redis, Elasticsearch) are generic and work for any PHP project
- Oro-specific services (consumer, websocket) are conditionally loaded for Oro projects
- However, websocket is still in the base compose file, causing it to start for all projects

As usage expands to other CMS systems (Magento 2, MageOS, Adobe Commerce), we need a modular architecture that:
1. Provides minimal base setup for generic PHP/Symfony/Laravel projects
2. Adds CMS-specific services only when needed
3. Maintains backward compatibility with existing Oro projects

## Goals / Non-Goals

**Goals:**
- Support three CMS tiers: base (PHP/Symfony/Laravel), Oro, Magento
- Modular compose file architecture with conditional loading
- Automatic CMS type detection from project files
- Backward compatibility with existing Oro projects
- Minimal base setup (no unnecessary services)

**Non-Goals:**
- Full refactor to CMS-agnostic architecture (future work)
- Support for other CMS systems (WordPress, Drupal, etc.) in this change
- Changes to base service definitions (FPM, CLI, Nginx remain unchanged)
- Gotenberg service implementation (mentioned but not required for this change)

## Decisions

### Decision 1: Three-Tier CMS Architecture

**Base Tier (PHP/Symfony/Laravel):**
- Services: CLI, FPM, Nginx, Database, Redis, Elasticsearch
- No consumer, websocket, or cron services
- Minimal setup for generic PHP development

**Oro Tier:**
- Base tier services +
- Consumer service (`oro:message-queue:consume`)
- WebSocket service (`gos:websocket:server`)
- Optional: Gotenberg (future enhancement)

**Magento Tier:**
- Base tier services +
- Cron service (Ofelia running `cron.sh`)

**Why:** Clear separation of concerns, allows incremental service addition, maintains backward compatibility.

**Alternative considered:** Single compose file with profiles → Would require users to remember `--profile` flags, less flexible.

### Decision 2: CMS Detection via composer.json and Project Files

**Detection Priority:**
1. Environment variable override (`DC_ORO_CMS_TYPE`)
2. Check `composer.json` for CMS-specific packages:
   - Oro: `oro/platform`, `oro/commerce`, `oro/crm`, `oro/customer-portal`, `marello/marello`
   - Magento: `magento/product-community-edition`, `magento/product-enterprise-edition`, `magento/magento-cloud-metapackage`, `mage-os/mage-os`
3. Check for project-specific files:
   - Magento: `bin/magento`, `app/etc/config.php`, `pub/index.php` (Magento structure)
4. Default to `base` if no CMS detected

**Why:** Reliable detection without requiring PHP execution, follows existing Oro detection pattern.

**Alternative considered:** Check for CLI commands (`bin/console`, `bin/magento`) → Too slow, requires container execution.

### Decision 3: Separate Compose Files per CMS Feature

**File Structure:**
- `docker-compose.yml` - Base services only
- `docker-compose-consumer.yml` - Consumer service (Oro)
- `docker-compose-websocket.yml` - WebSocket service (Oro)
- `docker-compose-cron.yml` - Cron service (Magento)

**Why:** 
- Follows existing pattern (`docker-compose-consumer.yml`, `docker-compose-pgsql.yml`)
- Allows independent enablement of features
- Easy to extend with new CMS types

**Alternative considered:** Single file with all services → Harder to maintain, less flexible.

### Decision 4: Magento Cron Implementation with Ofelia

**Ofelia Service:**
- Uses `mcuadros/ofelia:latest` image
- Runs `cron.sh` from project root if exists
- If `cron.sh` doesn't exist, sleeps 5 seconds and waits for it to appear
- Mounts project code volume to access `cron.sh`

**Why:** 
- Ofelia is a lightweight cron scheduler for Docker
- Waiting for `cron.sh` allows projects to add it after initial setup
- Common pattern for Magento development

**Alternative considered:** Direct cron execution → Requires cron.sh to exist immediately, less flexible.

### Decision 5: Backward Compatibility

**Oro Projects:**
- Continue to work without changes
- Auto-detected as `oro` CMS type
- Consumer and websocket services loaded automatically

**Why:** Prevents breaking existing installations, maintains user trust.

## Risks / Trade-offs

**Risk:** Existing non-Oro projects might break if websocket service removal causes issues
**Mitigation:** Websocket service was already failing for non-Oro projects, this change just prevents it from starting

**Risk:** Magento detection might be inaccurate for custom forks
**Mitigation:** Environment variable override (`DC_ORO_CMS_TYPE=magento`) allows manual correction

**Risk:** Ofelia cron service might conflict with existing cron setups
**Mitigation:** Only starts if Magento detected, can be disabled via environment variable

**Trade-off:** More compose files to maintain vs. cleaner separation of concerns
**Decision:** Prefer modularity for easier maintenance and extension

## Migration Plan

1. **Phase 1: Extract websocket to separate file**
   - Move websocket service from `docker-compose.yml` to `docker-compose-websocket.yml`
   - Update compose assembly logic to include websocket for Oro projects
   - Test with existing Oro projects

2. **Phase 2: Add CMS detection**
   - Implement `detect_cms_type()` function
   - Update compose assembly to use CMS type
   - Test with base PHP/Symfony projects

3. **Phase 3: Add Magento cron support**
   - Create `docker-compose-cron.yml` with Ofelia service
   - Add Magento detection logic
   - Test with Magento 2 project

4. **Phase 4: Update documentation**
   - Document CMS types and detection
   - Update examples for different CMS types

**Rollback:** If issues occur, revert compose file changes and restore websocket to base file.

## Open Questions

- Should Gotenberg be included in this change or deferred to future enhancement?
  **Decision:** Defer to future change, focus on core CMS support first

- Should we support multiple CMS types simultaneously (e.g., Oro + Magento)?
  **Decision:** No, single CMS type per project. If needed, use environment variable override.

- How to handle projects that don't fit any CMS type?
  **Decision:** Default to `base` type with minimal services.
