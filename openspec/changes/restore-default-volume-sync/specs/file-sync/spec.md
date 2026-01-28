## ADDED Requirements

### Requirement: FILE-SYNC-001 - Default Mode Bind Mount

When `DC_ORO_MODE=default` is set (or unset, defaulting to `default`), the system SHALL use direct bind mount without any sync processes or Docker volumes.

#### Scenario: Default Mode Configuration
- **WHEN** `DC_ORO_MODE=default` is set (or unset)
- **AND** user runs `orodc compose up`
- **THEN** the system SHALL load `docker-compose-default.yml`
- **AND** `appcode` volume SHALL be configured as bind mount (type: none, o: bind)
- **AND** bind mount SHALL point to `${DC_ORO_APPDIR:-$PWD}`
- **AND** no Docker volume SHALL be created for `appcode`

#### Scenario: Default Mode File Access
- **WHEN** `DC_ORO_MODE=default` is set
- **AND** containers are running
- **AND** user modifies files in `${DC_ORO_APPDIR}`
- **THEN** changes SHALL be immediately visible in containers
- **AND** no sync process SHALL be involved
- **AND** files SHALL be directly accessible via bind mount

#### Scenario: Default Mode No Sync Processes
- **WHEN** `DC_ORO_MODE=default` is set
- **AND** user runs `orodc compose up`
- **THEN** no mutagen sync session SHALL be started
- **AND** no rsync sync daemon SHALL be started
- **AND** only Docker containers SHALL be running
