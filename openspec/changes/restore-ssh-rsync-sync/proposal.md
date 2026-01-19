# Change: Restore SSH/RSync Sync Mode

## Why

The `ssh` sync mode is documented but missing volume creation and rsync synchronization management. This mode is required for remote Docker setups and should work automatically when `DC_ORO_MODE=ssh` is set.

## What Changes

- Add automatic Docker volume creation for `appcode` volume when using `ssh` mode
- Add rsync synchronization lifecycle management (start, stop) using `orodc-sync` daemon
- Integrate rsync sync lifecycle into `orodc compose up` and `orodc compose down` commands
- Add sync status checking and error handling
- Ensure SSH container is available before starting sync

## Impact

- Affected specs: `file-sync` capability (ssh mode)
- Affected code: 
  - `libexec/orodc/lib/docker-utils.sh` (volume creation, rsync lifecycle)
  - `libexec/orodc/compose.sh` (integrate rsync into up/down)
- Users with remote Docker can now use `ssh` mode automatically
- Requires SSH container to be running before sync starts
