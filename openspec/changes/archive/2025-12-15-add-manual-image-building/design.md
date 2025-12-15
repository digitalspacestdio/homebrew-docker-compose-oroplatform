# Design: Manual Docker Image Building

## Context

OroDC currently uses pre-built Docker images hosted on GitHub Container Registry. This architecture works well for most users but creates challenges in:

1. **Air-gapped environments**: Organizations with restricted internet access
2. **Custom versions**: Projects requiring PHP/Node.js versions not in pre-built catalog
3. **Registry outages**: GitHub Container Registry downtime blocks development
4. **Image testing**: Testing Dockerfile changes requires CI/CD pipeline

The existing build infrastructure in `compose/docker/` contains all necessary Dockerfiles but lacks a CLI interface for local building.

## Goals / Non-Goals

### Goals
- **Primary**: Enable local building of `php-node-symfony` final images
- **Dependency handling**: Automatically build `php` base images when needed (required as FROM base)
- Support all PHP versions: 7.3, 7.4, 8.1, 8.2, 8.3, 8.4, 8.5
- Support all Node.js versions: 18, 20, 22
- Support Composer versions: 1, 2
- Interactive prompts for ease of use
- Proper image tagging compatible with docker-compose configuration
- Architecture-aware building (amd64, arm64)

### Non-Goals
- Multi-architecture cross-compilation (use Docker Buildx if needed)
- Automated registry upload (keep in GitHub Actions)
- Project-specific image building (already handled by `docker-compose build`)
- **Other service images**: nginx, pgsql, mysql, redis, elasticsearch, etc. (use official or pre-built images)
- Standalone PHP base image building without final image (only as intermediate step)

## Decisions

### Command Structure
**Decision**: Use `orodc image build` with automatic version detection from OroDC configuration

**Rationale**:
- Consistent with OroDC command naming (`orodc tests`, `orodc ssh`)
- **Zero configuration**: Uses same version detection flow as `orodc up`
- Versions from environment variables: `DC_ORO_PHP_VERSION`, `DC_ORO_NODE_VERSION`, `DC_ORO_COMPOSER_VERSION`
- Sources: `.env.orodc`, environment, or hardcoded defaults in `bin/orodc`
- Aligns with zero-configuration philosophy

**Alternatives considered**:
- Interactive prompts - Inconsistent with OroDC philosophy, extra user friction
- CLI flags `--php=8.3 --node=20` - Redundant when configuration already exists
- `orodc build-image` - Less structured, doesn't allow future `image` subcommands

### Build Workflow
**Decision**: Sequential two-stage build with automatic version detection and dependency resolution

**Primary Goal**: Build `php-node-symfony` image for current project configuration

**Architecture**:
```
1. User runs: orodc image build

2. Detect versions from OroDC configuration:
   - Read DC_ORO_PHP_VERSION (from .env.orodc, env, or default: 8.4)
   - Read DC_ORO_NODE_VERSION (from .env.orodc, env, or default: 22)
   - Read DC_ORO_COMPOSER_VERSION (from .env.orodc, env, or default: 2)
   - Read DC_ORO_PHP_DIST (from .env.orodc, env, or default: alpine)

3. Display detected configuration:
   - "Building for: PHP ${DC_ORO_PHP_VERSION}, Node.js ${DC_ORO_NODE_VERSION}, Composer ${DC_ORO_COMPOSER_VERSION}"

4. Stage 1 (Dependency): Build PHP base image
   - Purpose: Required as FROM base for php-node-symfony
   - Location: ${DC_ORO_CONFIG_DIR}/docker/php/Dockerfile.${DC_ORO_PHP_VERSION}.${DC_ORO_PHP_DIST}
   - Tag: orodc-php:${DC_ORO_PHP_VERSION}-${DC_ORO_PHP_DIST}
   - Base: php:${DC_ORO_PHP_VERSION}-fpm-${DC_ORO_PHP_DIST} (official)
   - Skip if already exists locally

5. Stage 2 (Target): Build PHP+Node.js final image
   - Purpose: Main image used by OroDC docker-compose
   - Location: ${DC_ORO_CONFIG_DIR}/docker/php-node-symfony/${DC_ORO_PHP_VERSION}/Dockerfile
   - Tag: orodc-php-node-symfony:${DC_ORO_PHP_VERSION}-node${DC_ORO_NODE_VERSION}-composer${DC_ORO_COMPOSER_VERSION}-${DC_ORO_PHP_DIST}
   - Base: orodc-php:${DC_ORO_PHP_VERSION}-${DC_ORO_PHP_DIST} (from Stage 1)
   
6. Validate: Check both images exist with docker images
7. Output: Success message with built image tag
```

**Rationale**:
- **Standard OroDC flow**: Same configuration source as `orodc up` and docker-compose
- **Zero-configuration**: Works out of the box, uses project settings
- **Consistency**: Built images match docker-compose expectations
- **Automatic dependency**: php base built transparently as prerequisite
- **CI/CD alignment**: Matches pipeline architecture (`.github/workflows/build-docker-images.yml`)
- **Clear scope**: Only php and php-node-symfony, not other services

### Image Tagging
**Decision**: Use local tags without registry prefix

**Format**:
- Base: `orodc-php:{version}-alpine`
- Final: `orodc-php-node-symfony:{php}-node{node}-composer{composer}-alpine`

**Rationale**:
- Docker Compose checks local registry first before pulling
- Matches tag format in GitHub registry (without `ghcr.io/` prefix)
- Allows easy override of registry images

**Environment variable override**:
Users can force local images via `.env.orodc`:
```bash
DC_ORO_PHP_REGISTRY=''  # Empty string = use local images
```

### Architecture Handling
**Decision**: Build for local architecture only

**Rationale**:
- Simplifies implementation (no buildx complexity)
- Developers typically need images for their own architecture
- Cross-architecture builds slow and require emulation

**Note**: Users needing multi-arch can use Docker Buildx manually

### Error Handling
**Decision**: Fail fast with clear error messages

**Scenarios**:
1. Dockerfile not found → Show list of available versions
2. Docker build fails → Display full build log
3. Image tag already exists → Prompt for overwrite confirmation
4. Insufficient disk space → Check before build, warn if < 5GB free

## Risks / Trade-offs

### Risks

1. **Disk Space**:
   - Risk: Base images ~1GB each, final images ~2GB each
   - Mitigation: Check free space before build, warn if < 5GB
   
2. **Build Time**:
   - Risk: Full build takes 5-15 minutes depending on system
   - Mitigation: Show progress, allow cancellation with Ctrl+C

3. **Dockerfile Changes**:
   - Risk: Local Dockerfiles may diverge from registry
   - Mitigation: Document that Homebrew upgrade syncs latest Dockerfiles

4. **Missing Dependencies**:
   - Risk: Build may fail if system lacks build tools
   - Mitigation: Check for Docker before proceeding, show clear error

### Trade-offs

| Aspect | Chosen Approach | Alternative | Reasoning |
|--------|----------------|-------------|-----------|
| Interactivity | Prompts | CLI flags | Easier for occasional use |
| Architecture | Single arch | Multi-arch | Simpler, faster |
| Caching | Docker cache | No cache | Faster rebuilds |
| Validation | Post-build check | None | Catch failures early |

## Migration Plan

### Rollout
1. Add command to `bin/orodc` behind feature detection
2. Test with beta users in air-gapped environments
3. Document in README and troubleshooting guides
4. Announce in release notes

### Backward Compatibility
- No breaking changes
- Existing projects continue using registry images
- New command is opt-in

### Rollback
- Remove command handler from `bin/orodc`
- No data migration needed
- Registry images remain primary distribution

## Open Questions

1. **Build caching**: Should we expose Docker build cache options (`--no-cache`)?
   - **Decision**: Add `--no-cache` flag for troubleshooting builds

2. **Parallel builds**: Build multiple versions in parallel?
   - **Decision**: Sequential builds for clarity, revisit if users request

3. **Build logs**: Save build logs to file?
   - **Decision**: Output to stdout/stderr, users can redirect if needed

4. **Registry fallback**: Auto-pull from registry if local build fails?
   - **Decision**: No, fail explicitly so users understand the issue

