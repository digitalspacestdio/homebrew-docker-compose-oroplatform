## 1. Design Phase
- [ ] 1.1 Define command interface using standard OroDC configuration flow
- [ ] 1.2 Identify required environment variables (DC_ORO_PHP_VERSION, DC_ORO_NODE_VERSION, DC_ORO_COMPOSER_VERSION, DC_ORO_PHP_DIST)
- [ ] 1.3 Map version detection to existing OroDC configuration logic
- [ ] 1.4 Plan error handling for missing Dockerfiles or build failures

## 2. Implementation
- [ ] 2.1 Add `image` subcommand handler in `bin/orodc`
- [ ] 2.2 Implement `build` action under `image` subcommand
- [ ] 2.3 Integrate with existing OroDC configuration detection (reuse DC_ORO_* variable logic)
- [ ] 2.4 Add version display before build starts
- [ ] 2.5 Implement PHP base image builder (Stage 1) with skip-if-exists logic
- [ ] 2.6 Implement PHP+Node.js final image builder (Stage 2)
- [ ] 2.7 Add proper image tagging logic for local usage
- [ ] 2.8 Add build progress output and logging (Stage 1/2, Stage 2/2)
- [ ] 2.9 Implement build validation (check image exists after build)
- [ ] 2.10 Add `--no-cache` flag for troubleshooting builds

## 3. Testing
- [ ] 3.1 Test building PHP 8.3 base image
- [ ] 3.2 Test building PHP 8.3 + Node.js 20 final image
- [ ] 3.3 Test with non-standard versions (e.g., PHP 8.5 + Node.js 22)
- [ ] 3.4 Test error handling for invalid versions
- [ ] 3.5 Verify image tags are correct and usable by docker-compose
- [ ] 3.6 Test multi-architecture builds (amd64, arm64) if supported locally

## 4. Documentation
- [ ] 4.1 Update README with `orodc image build` usage
- [ ] 4.2 Add troubleshooting section for build failures
- [ ] 4.3 Document custom version requirements
- [ ] 4.4 Add examples for common use cases
- [ ] 4.5 Update project documentation in `compose/docker/README.md`

## 5. Validation
- [ ] 5.1 Run `openspec validate add-manual-image-building --strict`
- [ ] 5.2 Verify all scenarios pass requirements
- [ ] 5.3 Test command in real-world OroPlatform project

