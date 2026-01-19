# Oro Platform Coding Rules

**Oro-Specific Guidelines:**
- Follow Oro Platform coding standards (Symfony-based with Oro extensions)
- Use Symfony's dependency injection system
- Follow Oro's bundle structure conventions
- Use Oro's entity and field management system
- Implement proper ACL (Access Control Lists)

**Bundle Development:**
- Create bundles following Oro's naming conventions
- Use proper namespace structure: `Oro\\Bundle\\YourBundle`
- Define services.yml, routing.yml, and entity configurations
- Use Oro's configuration system (ConfigBundle)
- Register bundles in AppKernel.php

**Entity Management:**
- Use Oro's entity configuration system
- Define entities in Resources/config/oro/entity_config.yml
- Use migrations for database schema changes: `orodc exec bin/console oro:migration:load`
- Never modify core entities directly

**Assets:**
- Build assets after changes: `orodc exec bin/console oro:assets:build default -w`
- Use Oro's asset management system
- Follow Oro's theme structure
- Use layout YAML for page structure

**Cache:**
- Clear cache after configuration changes: `orodc exec bin/console cache:clear`
- Warm up cache for production: `orodc exec bin/console cache:warmup`
- Use appropriate cache pools

**Best Practices:**
- Use Oro's service locator pattern appropriately
- Implement proper ACL for security
- Use Oro's workflow system for business processes
- Follow Oro's versioning and upgrade guidelines
- Test with different Oro versions if supporting multiple
