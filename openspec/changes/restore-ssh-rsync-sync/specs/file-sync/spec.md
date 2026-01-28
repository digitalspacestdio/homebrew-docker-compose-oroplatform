## ADDED Requirements

### Requirement: FILE-SYNC-002 - Docker Volume Creation for SSH Mode

When `DC_ORO_MODE=ssh` is set, the system SHALL automatically create a Docker volume named `${DC_ORO_NAME}_appcode` if it does not exist before starting containers.

#### Scenario: Volume Creation for SSH Mode
- **WHEN** `DC_ORO_MODE=ssh` is set
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

### Requirement: FILE-SYNC-003 - SSH/RSync Sync Lifecycle Management

When `DC_ORO_MODE=ssh` is set, the system SHALL automatically manage rsync synchronization via `orodc-sync` daemon to synchronize files between the local project directory and the Docker volume over SSH.

#### Scenario: RSync Sync Start
- **WHEN** `DC_ORO_MODE=ssh` is set
- **AND** SSH container is running
- **AND** user runs `orodc compose up`
- **THEN** the system SHALL start `orodc-sync` daemon if not running
- **AND** sync SHALL start before containers start
- **AND** sync SHALL synchronize `${DC_ORO_APPDIR}` with the volume mount point via SSH

#### Scenario: RSync Sync Stop
- **WHEN** `DC_ORO_MODE=ssh` is set
- **AND** rsync sync daemon is running
- **AND** user runs `orodc compose down`
- **THEN** the system SHALL stop the rsync sync daemon
- **AND** sync SHALL stop cleanly

#### Scenario: SSH Container Not Available
- **WHEN** `DC_ORO_MODE=ssh` is set
- **AND** SSH container is not running
- **AND** user runs `orodc compose up`
- **THEN** the system SHALL display an error message
- **AND** the error message SHALL indicate SSH container must be started first
- **AND** containers SHALL NOT start

#### Scenario: RSync Process Cleanup
- **WHEN** rsync sync daemon is running
- **AND** container startup fails or user interrupts
- **THEN** the system SHALL attempt to stop the rsync sync daemon
- **AND** rsync process SHALL be terminated if possible
