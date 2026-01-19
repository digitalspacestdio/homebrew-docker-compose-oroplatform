# Change: Add Oro Project Detection and Conditional Consumer/Menu Gating

## Why

Currently, OroDC treats any PHP project with `composer.json` as an Oro project. This causes:
1. Oro-specific menu items (Platform Update, Install with/without demo) shown for non-Oro PHP projects
2. Oro consumer service (`oro:message-queue:consume`) started for all projects, failing on non-Oro apps
3. Confusing UX when using OroDC for generic PHP/Symfony development

## What Changes

- Add proper Oro project detection by checking `composer.json` for Oro dependencies (`oro/platform`, `oro/commerce`, `oro/crm`, etc.)
- Hide Oro-specific interactive menu items when project is not Oro-based
- **BREAKING**: Move `consumer` service from base `docker-compose.yml` to separate `docker-compose-consumer.yml`
- Include `docker-compose-consumer.yml` only when Oro project detected
- Add `DC_ORO_IS_ORO_PROJECT` environment variable for explicit override
- Add `is_oro_project()` function for detection logic

## Impact

- Affected specs: `interactive-menu`, new `oro-project-detection`, new `compose-assembly`
- Affected code: `bin/orodc` (detection function, menu display, compose file assembly), `compose/docker-compose.yml`, new `compose/docker-compose-consumer.yml`
- Users with non-Oro PHP projects will no longer see Oro-specific menu items
- Existing Oro projects continue to work without changes (auto-detected)
