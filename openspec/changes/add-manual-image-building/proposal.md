# Change: Add Manual Docker Image Building

## Why

Users need the ability to build base Docker images locally when:
- GitHub Container Registry is unavailable or blocked
- Custom PHP or Node.js versions are required (not available in pre-built images)
- Development requires testing image changes before CI/CD deployment
- Air-gapped or restricted network environments prevent registry access

Currently, OroDC relies on pre-built images from `ghcr.io/digitalspacestdio/orodc-*`, which limits flexibility in offline scenarios and custom version requirements.

## What Changes

- Add new CLI command: `orodc image build`
- **Auto-detection**: Use existing OroDC configuration flow (DC_ORO_PHP_VERSION, DC_ORO_NODE_VERSION, DC_ORO_COMPOSER_VERSION)
- **Primary goal**: Build `php-node-symfony` final images for current project configuration
- **Dependency**: Automatically build required `php` base images first (dependency for php-node-symfony)
- Two-stage sequential build: `php` (base) → `php-node-symfony` (final)
- Proper tagging for local image usage
- Integration with existing build architecture in `compose/docker/`
- Comprehensive documentation and error handling
- **Scope limitation**: Only `php` and `php-node-symfony` images (not nginx, pgsql, mysql, etc.)

## Impact

- Affected specs: New capability `docker-image-management`
- Affected code:
  - `bin/orodc` - Add new command handler for `image build`
  - `compose/docker/` - Utilize existing Dockerfiles and structure
  - Documentation - Update README and guides with manual build instructions
- User experience: Enhanced flexibility for offline development and custom versions
- No breaking changes to existing functionality

