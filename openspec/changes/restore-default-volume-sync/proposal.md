# Change: Restore Default Volume Sync (Bind Mount)

## Why

The `default` sync mode (bind mount) is partially working but needs verification and proper integration. This is the simplest sync mode and should be fully functional before implementing more complex sync modes.

## What Changes

- Verify `default` mode bind mount works correctly via `docker-compose-default.yml`
- Ensure volume configuration is properly loaded when `DC_ORO_MODE=default` or unset
- Add validation that bind mount is working
- Document default mode behavior clearly

## Impact

- Affected specs: `file-sync` capability (default mode)
- Affected code: 
  - `libexec/orodc/lib/environment.sh` (verify default mode loading)
  - `compose/docker-compose-default.yml` (verify configuration)
- Users: No breaking changes, only verification and documentation improvements
- Foundation for subsequent sync mode implementations
