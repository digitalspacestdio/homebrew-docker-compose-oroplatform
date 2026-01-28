## 1. Volume Management

- [ ] 1.1 Add function `ensure_appcode_volume()` in `libexec/orodc/lib/docker-utils.sh` to create Docker volume if missing
- [ ] 1.2 Call `ensure_appcode_volume()` before `docker compose up` for `ssh` mode
- [ ] 1.3 Verify volume creation with name pattern `${DC_ORO_NAME}_appcode`
- [ ] 1.4 Test volume persistence across `docker compose down` (volume should not be removed)

## 2. RSync Sync Implementation

- [ ] 2.1 Add function `start_rsync_sync()` in `libexec/orodc/lib/docker-utils.sh` to start `orodc-sync` daemon
- [ ] 2.2 Add function `stop_rsync_sync()` to stop rsync daemon process
- [ ] 2.3 Add function `check_rsync_sync()` to verify sync status
- [ ] 2.4 Integrate rsync start into `handle_compose_up()` before containers start for `ssh` mode
- [ ] 2.5 Integrate rsync stop into `exec_compose_command()` for `down` command
- [ ] 2.6 Ensure SSH container is running before starting rsync sync
- [ ] 2.7 Test rsync sync between `${DC_ORO_APPDIR}` and volume mount point via SSH

## 3. Integration

- [ ] 3.1 Update `handle_compose_up()` to call rsync start for `ssh` mode
- [ ] 3.2 Update `exec_compose_command()` for `down` to call rsync stop for `ssh` mode
- [ ] 3.3 Add sync status display in `show_service_urls()` when rsync sync is active
- [ ] 3.4 Ensure rsync processes are cleaned up on errors/interrupts

## 4. Validation

- [ ] 4.1 Test `ssh` mode (volume created, rsync daemon running, files sync via SSH)
- [ ] 4.2 Test sync stops when containers stop (`orodc compose down`)
- [ ] 4.3 Test sync restarts when containers restart (`orodc compose up` after down)
- [ ] 4.4 Test error handling when SSH container not available (helpful error message)
- [ ] 4.5 Verify `default` mode still works (no rsync processes started)
