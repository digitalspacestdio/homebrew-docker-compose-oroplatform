# Change: Add Multi-CMS Support via Conditional Compose Files

## Why

Currently, OroDC is optimized for Oro Platform applications, but the base infrastructure (PHP, FPM, CLI, Nginx, Database, Redis, Elasticsearch) is generic enough to support other PHP frameworks and CMS systems. To expand support for Symfony, Laravel, Magento 2, MageOS, and Adobe Commerce, we need a modular compose file architecture that conditionally loads CMS-specific services based on project type detection.

This change enables:
1. **Base PHP/Symfony/Laravel projects**: Minimal setup with CLI, FPM, Nginx, Database, Redis, Elasticsearch (no consumer, websocket, cron)
2. **Oro Platform projects**: Adds consumer and websocket services (and optionally Gotenberg for PDF generation)
3. **Magento 2/MageOS/Adobe Commerce projects**: Adds cron service using Ofelia that runs `cron.sh` from project root

## What Changes

- **BREAKING**: Move `websocket` service from base `docker-compose.yml` to separate `docker-compose-websocket.yml`
- Add CMS type detection function `detect_cms_type()` that identifies project type (base, oro, magento)
- Add `docker-compose-websocket.yml` for Oro-specific websocket service
- Add `docker-compose-cron.yml` for Magento-specific cron service using Ofelia
- Conditionally include CMS-specific compose files based on detected CMS type
- Add `DC_ORO_CMS_TYPE` environment variable for explicit override
- Update compose file assembly logic to support multiple CMS types
- Base compose file (`docker-compose.yml`) becomes minimal: CLI, FPM, Nginx, Database, Redis, Elasticsearch only

## Impact

- Affected specs: `cms-detection` (new), `compose-assembly` (modified), `oro-project-detection` (modified), `interactive-menu` (modified)
- Affected code: 
  - `libexec/orodc/lib/common.sh` (new `detect_cms_type()` function)
  - `libexec/orodc/lib/environment.sh` (compose file assembly logic)
  - `libexec/orodc/menu.sh` (display CMS type in menu header)
  - `compose/docker-compose.yml` (remove websocket, keep base services)
  - `compose/docker-compose-websocket.yml` (new, extracted from base)
  - `compose/docker-compose-cron.yml` (new, for Magento cron)
- Existing Oro projects continue to work (auto-detected as `oro` CMS type)
- New Magento projects will automatically get cron support
- Base PHP/Symfony/Laravel projects get minimal setup without unnecessary services
- Interactive menu displays detected CMS/framework type for better user awareness
