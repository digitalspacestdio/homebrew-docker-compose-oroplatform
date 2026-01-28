## Context

OroDC was originally designed exclusively for Oro Platform applications. As usage expanded to generic PHP/Symfony projects, the tight coupling to Oro-specific features became problematic. The consumer service crashes on non-Oro projects, and Oro-specific menu items confuse users.

## Goals / Non-Goals

**Goals:**
- Detect Oro projects reliably via `composer.json` dependencies
- Gate Oro-specific functionality (consumer, menu items) behind detection
- Maintain backward compatibility for existing Oro users
- Allow explicit override via environment variable

**Non-Goals:**
- Full refactor of OroDC to be Oro-agnostic (future work)
- Support for other framework-specific consumers (Laravel Horizon, etc.)
- Changes to WebSocket service (also Oro-specific, but less disruptive)

## Decisions

### Decision 1: Detection via composer.json require section

Check for any of these packages in `composer.json` → `require`:
- `oro/platform`
- `oro/commerce` 
- `oro/crm`
- `oro/customer-portal`
- `marello/marello`

**Why:** These are the canonical Oro ecosystem packages. If any is present, it's an Oro project.

**Alternative considered:** Check for `bin/console oro:*` commands → Too slow (requires PHP execution), fragile.

### Decision 2: Separate compose file for consumer (not profile)

Extract consumer to `docker-compose-consumer.yml` and conditionally include via `-f` flag.

**Why:** 
- Profiles require explicit `--profile consumer` which changes UX
- Separate file allows clean conditional inclusion based on detection
- Follows existing pattern for database (`docker-compose-pgsql.yml`, `docker-compose-mysql.yml`)

**Alternative considered:** Docker Compose profiles → Would require users to remember `--profile` flags.

### Decision 3: Environment variable override

Add `DC_ORO_IS_ORO_PROJECT` variable:
- `1` or `true` → Force treat as Oro project
- `0` or `false` → Force treat as non-Oro project  
- Unset → Auto-detect from `composer.json`

**Why:** Edge cases exist (custom forks, renamed packages, testing).

## Risks / Trade-offs

- **Risk:** False negatives (Oro project not detected) → **Mitigation:** Override variable, clear error messages
- **Risk:** Breaking change for CI scripts relying on consumer always starting → **Mitigation:** Document in release notes, override available
- **Trade-off:** Slightly more complex compose assembly → Acceptable for cleaner UX

## Migration Plan

1. Deploy change
2. Existing Oro projects: No action needed (auto-detected)
3. Non-Oro projects: Consumer stops starting automatically (intended behavior)
4. If consumer needed on non-Oro: Set `DC_ORO_IS_ORO_PROJECT=1` in `.env.orodc`

## Open Questions

- Should WebSocket service also be gated? (Deferred to future change)
- Should we add detection for other Oro ecosystem packages? (Can be extended later)
