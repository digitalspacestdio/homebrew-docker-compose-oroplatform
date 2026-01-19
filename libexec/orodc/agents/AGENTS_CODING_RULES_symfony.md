# Symfony Coding Rules

**Symfony-Specific Guidelines:**
- Follow Symfony coding standards (PSR-12)
- Use Symfony's dependency injection system
- Follow Symfony's bundle structure conventions
- Use Symfony's service container appropriately
- Implement proper security with Symfony Security component

**Bundle Development:**
- Create bundles following Symfony's naming conventions
- Use proper namespace structure: `Vendor\\BundleName`
- Define services.yml, routing.yml, and configuration files
- Use Symfony's configuration system
- Register bundles in bundles.php (Symfony 4+) or AppKernel.php (Symfony 3)

**Doctrine:**
- Use Doctrine migrations for database schema changes: `orodc exec bin/console doctrine:migrations:migrate`
- Use Doctrine entities and repositories
- Never modify database schema directly
- Use Doctrine events and listeners appropriately

**Cache:**
- Clear cache after configuration changes: `orodc exec bin/console cache:clear`
- Warm up cache for production: `orodc exec bin/console cache:warmup`
- Use appropriate cache pools

**Best Practices:**
- Use Symfony's form component for form handling
- Use Symfony's validator component for validation
- Implement proper error handling with Symfony's exception handling
- Use Symfony's event dispatcher for extensibility
- Follow Symfony's versioning and upgrade guidelines
