## ADDED Requirements

### Requirement: MySQL image build target
The system SHALL provide a docker-build target for MySQL images with version selection and sensible defaults.

#### Scenario: Build default MySQL versions
- **WHEN** user runs docker-build for MySQL without specifying a version
- **THEN** the system builds all supported MySQL versions in sequence

#### Scenario: Build a specific MySQL version
- **WHEN** user runs docker-build for MySQL with a version argument
- **THEN** the system builds only the requested version

#### Scenario: Reject unsupported MySQL version
- **WHEN** user runs docker-build for MySQL with an unsupported version
- **THEN** the system displays an error listing supported versions

### Requirement: MySQL image includes pv
The MySQL image SHALL include pv to support import progress when available.

#### Scenario: pv available in database-cli container
- **WHEN** the database-cli container runs a MySQL import
- **AND** pv is available in the image
- **THEN** the import command can display a pv progress stream
