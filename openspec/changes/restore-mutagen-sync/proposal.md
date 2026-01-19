# Change: Restore Mutagen Sync Mode

## Why

The `mutagen` sync mode is documented but missing volume creation and mutagen daemon management. This mode is **required** for macOS users due to extremely slow Docker filesystem performance. Without mutagen sync, macOS users cannot effectively use OroDC.

## What Changes

- Add automatic Docker volume creation for `appcode` volume when using `mutagen` mode
- Add mutagen daemon lifecycle management (create, start, stop, terminate) for `mutagen` mode
- Integrate mutagen sync lifecycle into `orodc compose up` and `orodc compose down` commands
- Add sync status checking and error handling
- Ensure mutagen is installed before starting sync

## Impact

- Affected specs: `file-sync` capability (mutagen mode)
- Affected code: 
  - `libexec/orodc/lib/docker-utils.sh` (volume creation, mutagen lifecycle)
  - `libexec/orodc/compose.sh` (integrate mutagen into up/down)
- **Critical for macOS users** - enables acceptable performance
- Requires mutagen installation (`brew install mutagen-io/mutagen/mutagen`)
