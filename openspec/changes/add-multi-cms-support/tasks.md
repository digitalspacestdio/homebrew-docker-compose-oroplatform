## 1. Extract WebSocket Service

- [ ] 1.1 Create `compose/docker-compose-websocket.yml` with websocket service definition
- [ ] 1.2 Remove websocket service from `compose/docker-compose.yml`
- [ ] 1.3 Verify websocket service configuration (environment variables, volumes, depends_on, Traefik labels)
- [ ] 1.4 Test websocket service starts correctly when included

## 2. Implement CMS Detection

- [ ] 2.1 Add `detect_cms_type()` function to `libexec/orodc/lib/common.sh`
- [ ] 2.2 Implement Oro detection (reuse existing `is_oro_project()` logic)
- [ ] 2.3 Implement Magento detection (check composer.json for Magento packages)
- [ ] 2.4 Implement Magento file-based detection (check for `bin/magento`, `app/etc/config.php`)
- [ ] 2.5 Add environment variable override support (`DC_ORO_CMS_TYPE`)
- [ ] 2.6 Default to `base` CMS type when no CMS detected
- [ ] 2.7 Add debug logging for CMS detection process

## 3. Update Compose File Assembly

- [ ] 3.1 Update `initialize_environment()` in `libexec/orodc/lib/environment.sh` to use `detect_cms_type()`
- [ ] 3.2 Add logic to include `docker-compose-websocket.yml` for `oro` CMS type
- [ ] 3.3 Add logic to include `docker-compose-consumer.yml` for `oro` CMS type (existing logic)
- [ ] 3.4 Add logic to include `docker-compose-cron.yml` for `magento` CMS type
- [ ] 3.5 Update compose file loading order documentation/comments
- [ ] 3.6 Add debug logging for compose file inclusion decisions

## 4. Create Magento Cron Service

- [ ] 4.1 Create `compose/docker-compose-cron.yml` with Ofelia service definition
- [ ] 4.2 Configure Ofelia to run `cron.sh` from project root
- [ ] 4.3 Implement wait logic: if `cron.sh` doesn't exist, sleep 5 seconds and retry
- [ ] 4.4 Mount project code volume to allow Ofelia access to `cron.sh`
- [ ] 4.5 Configure proper depends_on relationships (database, redis, etc.)
- [ ] 4.6 Add healthcheck for cron service
- [ ] 4.7 Test cron service starts and waits for `cron.sh` correctly

## 5. Testing

- [ ] 5.1 Test base PHP/Symfony project (no consumer, websocket, cron)
- [ ] 5.2 Test Oro project (consumer + websocket, no cron)
- [ ] 5.3 Test Magento 2 project (cron, no consumer, no websocket)
- [ ] 5.4 Test environment variable override (`DC_ORO_CMS_TYPE`)
- [ ] 5.5 Test backward compatibility with existing Oro projects
- [ ] 5.6 Test Magento project without `cron.sh` (should wait)
- [ ] 5.7 Test Magento project with `cron.sh` (should run)

## 6. Update Interactive Menu

- [ ] 6.1 Add CMS type detection call in `show_interactive_menu()` function
- [ ] 6.2 Display CMS type in menu header after "Current Directory" line
- [ ] 6.3 Format CMS type display: "CMS Type: Oro Platform" / "CMS Type: Magento 2" / "CMS Type: Base (PHP/Symfony/Laravel)"
- [ ] 6.4 Update `redraw_menu_screen()` function to include CMS type in status section
- [ ] 6.5 Test menu display for all CMS types (oro, magento, base)

## 7. Documentation

- [ ] 7.1 Update `openspec/project.md` with CMS type architecture
- [ ] 7.2 Document CMS detection logic and override options
- [ ] 7.3 Add examples for different CMS types
- [ ] 7.4 Update README if needed
