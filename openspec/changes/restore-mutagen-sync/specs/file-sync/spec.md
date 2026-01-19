## ADDED Requirements

### Requirement: FILE-SYNC-004 - Docker Volume Creation for Mutagen Mode

When `DC_ORO_MODE=mutagen` is set, the system SHALL automatically create a Docker volume named `${DC_ORO_NAME}_appcode` if it does not exist before starting containers.

#### Scenario: Volume Creation for Mutagen Mode
- **WHEN** `DC_ORO_MODE=mutagen` is set
- **AND** volume `${DC_ORO_NAME}_appcode` does not exist
- **AND** user runs `orodc compose up`
- **THEN** the system SHALL create the Docker volume `${DC_ORO_NAME}_appcode`
- **AND** the volume SHALL be created before containers start
- **AND** the volume SHALL persist across `docker compose down` (not removed)

#### Scenario: Volume Already Exists
- **WHEN** volume `${DC_ORO_NAME}_appcode` already exists
- **AND** user runs `orodc compose up`
- **THEN** the system SHALL use the existing volume
- **AND** no error SHALL occur

### Requirement: FILE-SYNC-005 - Mutagen Sync Lifecycle Management

When `DC_ORO_MODE=mutagen` is set, the system SHALL automatically manage mutagen sync sessions to synchronize files between the local project directory and the Docker volume.

#### Scenario: Mutagen Sync Start
- **WHEN** `DC_ORO_MODE=mutagen` is set
- **AND** mutagen is installed
- **AND** user runs `orodc compose up`
- **THEN** the system SHALL create a mutagen sync session if it does not exist
- **OR** the system SHALL resume an existing mutagen sync session
- **AND** sync SHALL start before containers start
- **AND** sync SHALL synchronize `${DC_ORO_APPDIR}` with the volume mount point

#### Scenario: Mutagen Sync Stop
- **WHEN** `DC_ORO_MODE=mutagen` is set
- **AND** mutagen sync session is active
- **AND** user runs `orodc compose down`
- **THEN** the system SHALL terminate the mutagen sync session
- **AND** sync SHALL stop cleanly

#### Scenario: Mutagen Not Installed
- **WHEN** `DC_ORO_MODE=mutagen` is set
- **AND** mutagen is not installed
- **AND** user runs `orodc compose up`
- **THEN** the system SHALL display an error message
- **AND** the error message SHALL include installation instructions: `brew install mutagen-io/mutagen/mutagen`
- **AND** containers SHALL NOT start

#### Scenario: Mutagen Session Cleanup
- **WHEN** mutagen sync session is active
- **AND** container startup fails or user interrupts
- **THEN** the system SHALL attempt to terminate the mutagen sync session
- **AND** mutagen session SHALL be terminated if possible
