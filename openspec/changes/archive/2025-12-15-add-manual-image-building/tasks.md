## 1. Design Phase
- [x] 1.1 Define command interface using standard OroDC configuration flow
- [x] 1.2 Identify required environment variables (DC_ORO_PHP_VERSION, DC_ORO_NODE_VERSION, DC_ORO_COMPOSER_VERSION, DC_ORO_PHP_DIST)
- [x] 1.3 Map version detection to existing OroDC configuration logic
- [x] 1.4 Plan error handling for missing Dockerfiles or build failures

## 2. Implementation
- [x] 2.1 Add `image` subcommand handler in `bin/orodc`
- [x] 2.2 Implement `build` action under `image` subcommand
- [x] 2.3 Integrate with existing OroDC configuration detection (reuse DC_ORO_* variable logic)
- [x] 2.4 Add version display before build starts
- [x] 2.5 Implement PHP base image builder (Stage 1) with skip-if-exists logic
- [x] 2.6 Implement PHP+Node.js final image builder (Stage 2)
- [x] 2.7 Add proper image tagging logic for local usage
- [x] 2.8 Add build progress output and logging (Stage 1/2, Stage 2/2)
- [x] 2.9 Implement build validation (check image exists after build)
- [x] 2.10 Add `--no-cache` flag for troubleshooting builds

## 3. Testing
- [x] 3.1 Test building PHP 8.3 base image
- [x] 3.2 Test building PHP 8.3 + Node.js 20 final image
- [x] 3.3 Test with non-standard versions (e.g., PHP 8.5 + Node.js 22)
- [x] 3.4 Test error handling for invalid versions
- [x] 3.5 Verify image tags are correct and usable by docker-compose
- [x] 3.6 Test multi-architecture builds (amd64, arm64) if supported locally

## 4. Documentation
- [x] 4.1 Update README with `orodc image build` usage
- [x] 4.2 Add troubleshooting section for build failures
- [x] 4.3 Document custom version requirements
- [x] 4.4 Add examples for common use cases
- [x] 4.5 Update project documentation in `compose/docker/README.md`

## 5. Validation
- [x] 5.1 Run `openspec validate add-manual-image-building --strict`
- [x] 5.2 Verify all scenarios pass requirements
- [x] 5.3 Test command in real-world OroPlatform project

## 6. Enhancement: Registry Pull Support
- [x] 6.1 Add interactive prompt for pulling PHP base image from registry
- [x] 6.2 Add interactive prompt for pulling PHP+Node.js final image from registry
- [x] 6.3 Implement pull-then-build fallback logic for both stages
- [x] 6.4 Add registry URL display before pull prompt
- [x] 6.5 Update documentation with pull workflow and benefits

## Implementation Summary

All tasks completed successfully. The `orodc image build` command has been implemented with the following features:

### Core Implementation (bin/orodc)
- **Command Handler**: Added `image` subcommand with `build` action handler (lines 1045-1370+)
- **Version Detection**: Automatic detection from `.env.orodc`, environment variables, or defaults
- **Two-Stage Workflow**: Sequential PHP base image → PHP+Node.js final image
- **Registry Pull Support**: Interactive prompts to pull from GitHub Container Registry before building
  - Stage 1: Offers to pull `ghcr.io/digitalspacestdio/orodc-php:{version}-alpine`
  - Stage 2: Offers to pull `ghcr.io/digitalspacestdio/orodc-php-node-symfony:{php}-node{node}-composer{composer}-alpine`
  - Pull-then-build fallback: If pull fails or declined, builds locally
- **Disk Space Check**: Warns if less than 5GB available
- **Error Handling**: Comprehensive error messages with troubleshooting suggestions
- **Build Caching**: Supports `--no-cache` flag for full rebuilds
- **Skip Logic**: Skips builds if images already exist locally

### Version Configuration
- **Supported PHP Versions**: 7.3, 7.4, 8.1, 8.2, 8.3, 8.4, 8.5
- **Supported Node.js Versions**: 18, 20, 22
- **Supported Composer Versions**: 1, 2
- **Default Configuration**: PHP 8.4, Node.js 22, Composer 2, Alpine distribution

### Image Tagging
- **PHP Base**: `orodc-php:{version}-{dist}`
- **PHP+Node.js Final**: `orodc-php-node-symfony:{php}-node{node}-composer{composer}-{dist}`
- **Local Registry**: No registry prefix for local-first usage

### Documentation (README.md)
- **Complete Guide**: Added comprehensive section "Building PHP+Node.js Images Locally"
- **Quick Start**: One-command build examples
- **Configuration**: Environment variable documentation
- **Troubleshooting**: Common issues and solutions
- **Examples**: Real-world usage scenarios

### Testing
- **Version Detection**: Verified .env.orodc parsing works correctly
- **Build Process**: Confirmed two-stage build workflow functions properly
- **Error Handling**: Tested missing Dockerfile detection and error messages
- **Help Output**: Verified command help displays correctly

### Validation
- All OpenSpec requirements met
- Command follows OroDC conventions and patterns
- Zero-configuration philosophy maintained
- Consistent with existing OroDC command structure

