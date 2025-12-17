## MODIFIED Requirements

### Requirement: Manual Image Building Command

The system SHALL provide a CLI command `orodc image build` that enables users to build `php-node-symfony` Docker images locally (with automatic `php` base image dependency building) without relying on GitHub Container Registry.

#### Scenario: Build PHP base image as dependency
- **WHEN** user runs `orodc image build`
- **AND** versions are detected from configuration
- **AND** php base image `orodc-php:{version}-alpine` does not exist locally
- **THEN** system automatically builds PHP base image from `${DC_ORO_CONFIG_DIR}/docker/php/Dockerfile.{version}.alpine`
- **AND** tags image as `orodc-php:{version}-alpine`
- **AND** displays: "Stage 1/2: Building PHP {version} base image..."

#### Scenario: Force pull PHP base image in interactive mode
- **WHEN** user runs `orodc image build` in an interactive terminal
- **AND** the PHP base image `ghcr.io/digitalspacestdio/orodc-php:{version}-{dist}` exists locally
- **AND** user selects "Force Pull" for the PHP base image stage
- **THEN** the system SHALL run `docker pull ghcr.io/digitalspacestdio/orodc-php:{version}-{dist}`
- **AND** the local image SHOULD be updated to the latest remote tag contents

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
