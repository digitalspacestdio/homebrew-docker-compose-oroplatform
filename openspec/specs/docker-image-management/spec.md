# docker-image-management Specification

## Purpose
TBD - created by archiving change add-manual-image-building. Update Purpose after archive.
## Requirements
### Requirement: Manual Image Building Command

The system SHALL provide a CLI command `orodc image build` that enables users to build `php-node-symfony` Docker images locally (with automatic `php` base image dependency building) without relying on GitHub Container Registry.

#### Scenario: Build PHP base image as dependency
- **WHEN** user runs `orodc image build`
- **AND** versions are detected from configuration
- **AND** php base image `orodc-php:{version}-alpine` does not exist locally
- **THEN** system automatically builds PHP base image from `${DC_ORO_CONFIG_DIR}/docker/php/Dockerfile.{version}.alpine`
- **AND** tags image as `orodc-php:{version}-alpine`
- **AND** displays: "Stage 1/2: Building PHP {version} base image..."

#### Scenario: Build php-node-symfony final image successfully
- **WHEN** PHP base image exists (built or already present)
- **AND** versions are detected from configuration
- **THEN** system displays: "Stage 2/2: Building PHP+Node.js final image..."
- **AND** builds final image from `${DC_ORO_CONFIG_DIR}/docker/php-node-symfony/{php}/Dockerfile`
- **AND** tags image as `orodc-php-node-symfony:{php}-node{node}-composer{composer}-alpine`
- **AND** validates image exists after build
- **AND** displays: "Success! Built: orodc-php-node-symfony:{php}-node{node}-composer{composer}-alpine"

#### Scenario: Handle missing Dockerfile
- **WHEN** user selects unsupported version combination
- **AND** corresponding Dockerfile does not exist
- **THEN** system displays error message listing available versions
- **AND** exits with non-zero status code

#### Scenario: Handle build failure
- **WHEN** Docker build process fails during execution
- **THEN** system displays full build error log
- **AND** provides troubleshooting suggestions
- **AND** exits with non-zero status code

### Requirement: Automatic Version Detection

The system SHALL automatically detect versions from OroDC configuration using the same flow as other OroDC commands.

#### Scenario: Detect versions from environment variables
- **WHEN** user runs `orodc image build`
- **THEN** system reads `DC_ORO_PHP_VERSION`, `DC_ORO_NODE_VERSION`, `DC_ORO_COMPOSER_VERSION`, `DC_ORO_PHP_DIST`
- **AND** uses values from `.env.orodc`, environment variables, or hardcoded defaults
- **AND** displays detected configuration before build

#### Scenario: Use default versions when not configured
- **WHEN** user runs `orodc image build` without `.env.orodc`
- **THEN** system uses default versions (PHP 8.4, Node.js 22, Composer 2, alpine)
- **AND** displays: "Building for: PHP 8.4, Node.js 22, Composer 2"

#### Scenario: Respect project-specific configuration
- **WHEN** `.env.orodc` contains `DC_ORO_PHP_VERSION=8.3`, `DC_ORO_NODE_VERSION=20`
- **AND** user runs `orodc image build`
- **THEN** system builds for PHP 8.3, Node.js 20
- **AND** built images match docker-compose configuration

### Requirement: Image Tagging

The system SHALL tag built images using local registry format compatible with docker-compose configuration.

#### Scenario: PHP base image tagging
- **WHEN** PHP base image build completes
- **THEN** image is tagged as `orodc-php:{version}-alpine`
- **AND** tag is visible in `docker images` output

#### Scenario: Final image tagging
- **WHEN** PHP+Node.js final image build completes
- **THEN** image is tagged as `orodc-php-node-symfony:{php}-node{node}-composer{composer}-alpine`
- **AND** tag matches format expected by docker-compose services

### Requirement: Build Validation

The system SHALL validate successful image builds before completion.

#### Scenario: Verify image exists
- **WHEN** Docker build command exits with status 0
- **THEN** system checks image exists using `docker images` command
- **AND** confirms image size is reasonable (> 100MB for base, > 500MB for final)

#### Scenario: Build verification failure
- **WHEN** Docker build exits successfully
- **BUT** image is not found in local registry
- **THEN** system displays error message
- **AND** suggests checking Docker daemon status

### Requirement: Build Progress Feedback

The system SHALL provide clear progress feedback during image builds.

#### Scenario: Display build progress
- **WHEN** Docker build is in progress
- **THEN** system streams Docker build output to terminal
- **AND** shows current build step and total steps

#### Scenario: Build completion notification
- **WHEN** image build completes successfully
- **THEN** system displays success message with image tag
- **AND** shows usage instructions for docker-compose integration

### Requirement: Disk Space Management

The system SHALL check available disk space before initiating builds.

#### Scenario: Insufficient disk space warning
- **WHEN** available disk space is less than 5GB
- **THEN** system displays warning about potential build failure
- **AND** prompts user to confirm continuation

#### Scenario: Adequate disk space
- **WHEN** available disk space is 5GB or more
- **THEN** system proceeds with build without warning

### Requirement: Architecture Awareness

The system SHALL build images for the current system architecture only.

#### Scenario: Build for local architecture
- **WHEN** user builds image on amd64 system
- **THEN** image is built for linux/amd64 platform
- **AND** image is tagged without architecture suffix

#### Scenario: Build for local architecture on ARM64
- **WHEN** user builds image on arm64 system (Apple Silicon, AWS Graviton)
- **THEN** image is built for linux/arm64 platform
- **AND** image is compatible with local Docker daemon

### Requirement: Build Caching

The system SHALL utilize Docker build cache to speed up rebuilds.

#### Scenario: Use cached layers
- **WHEN** user rebuilds same image version
- **THEN** Docker reuses cached layers from previous build
- **AND** build completes faster than initial build

#### Scenario: Force rebuild without cache
- **WHEN** user runs `orodc image build --no-cache`
- **THEN** Docker ignores all cached layers
- **AND** performs complete rebuild from scratch

### Requirement: Error Recovery

The system SHALL provide clear error messages and recovery suggestions.

#### Scenario: Docker daemon not running
- **WHEN** Docker daemon is not accessible
- **THEN** system displays error: "Docker is not running"
- **AND** suggests starting Docker Desktop or Docker service

#### Scenario: Network error during build
- **WHEN** Docker cannot pull base images due to network failure
- **THEN** system displays network error message
- **AND** suggests checking internet connectivity

#### Scenario: Permission denied error
- **WHEN** Docker build fails due to permission issues
- **THEN** system displays permission error
- **AND** suggests running with proper Docker group membership

