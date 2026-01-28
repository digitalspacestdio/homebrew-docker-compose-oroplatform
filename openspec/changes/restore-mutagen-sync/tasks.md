## 1. Volume Management

- [ ] 1.1 Add function `ensure_appcode_volume()` in `libexec/orodc/lib/docker-utils.sh` to create Docker volume if missing (reuse from ssh mode if already implemented)
- [ ] 1.2 Call `ensure_appcode_volume()` before `docker compose up` for `mutagen` mode
- [ ] 1.3 Verify volume creation with name pattern `${DC_ORO_NAME}_appcode`
- [ ] 1.4 Test volume persistence across `docker compose down` (volume should not be removed)

## 2. Mutagen Sync Implementation

- [ ] 2.1 Add function `start_mutagen_sync()` in `libexec/orodc/lib/docker-utils.sh` to create/start mutagen session
- [ ] 2.2 Add function `stop_mutagen_sync()` to terminate mutagen session
- [ ] 2.3 Add function `check_mutagen_sync()` to verify sync status
- [ ] 2.4 Integrate mutagen start into `handle_compose_up()` before containers start for `mutagen` mode
- [ ] 2.5 Integrate mutagen stop into `exec_compose_command()` for `down` command
- [ ] 2.6 Add error handling for mutagen not installed (show helpful message with installation instructions)
- [ ] 2.7 Test mutagen sync creates session between `${DC_ORO_APPDIR}` and volume mount point

## 3. Integration

- [ ] 3.1 Update `handle_compose_up()` to call mutagen start for `mutagen` mode
- [ ] 3.2 Update `exec_compose_command()` for `down` to call mutagen stop for `mutagen` mode
- [ ] 3.3 Add sync status display in `show_service_urls()` when mutagen sync is active
- [ ] 3.4 Ensure mutagen sessions are cleaned up on errors/interrupts

## 4. Validation

- [ ] 4.1 Test `mutagen` mode on macOS (volume created, mutagen session active, files sync)
- [ ] 4.2 Test sync stops when containers stop (`orodc compose down`)
- [ ] 4.3 Test sync restarts when containers restart (`orodc compose up` after down)
- [ ] 4.4 Test error handling when mutagen not installed (helpful error message with brew install command)
- [ ] 4.5 Verify `default` and `ssh` modes still work (no mutagen processes started)
