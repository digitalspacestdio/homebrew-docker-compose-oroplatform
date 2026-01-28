## 1. Implementation

- [x] 1.1 Create `is_oro_project()` function in `bin/orodc` that checks `composer.json` for Oro dependencies
- [x] 1.2 Add `DC_ORO_IS_ORO_PROJECT` environment variable support for explicit override
- [x] 1.3 Extract `consumer` service from `compose/docker-compose.yml` to new `compose/docker-compose-consumer.yml`
- [x] 1.4 Update compose file assembly logic in `bin/orodc` to conditionally include `docker-compose-consumer.yml`
- [x] 1.5 Update `show_interactive_menu()` to hide Oro-specific items (12, 17-18) when not Oro project
- [x] 1.6 Update menu numbering/layout to handle conditional items gracefully

## 2. Validation

- [ ] 2.1 Test with Oro project (auto-detection works, consumer starts, full menu shown)
- [ ] 2.2 Test with generic Symfony project (consumer not started, Oro menu items hidden)
- [ ] 2.3 Test with `DC_ORO_IS_ORO_PROJECT=1` override on non-Oro project
- [ ] 2.4 Test with `DC_ORO_IS_ORO_PROJECT=0` override on Oro project
