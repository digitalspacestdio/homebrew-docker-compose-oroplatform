# Magento 2 Coding Rules

**Magento-Specific Guidelines:**
- Follow Magento 2 coding standards (PSR-2/PSR-12 with Magento extensions)
- Use Magento's dependency injection system
- Prefer plugins over rewrites when possible
- Use service contracts (interfaces) for API access
- Follow Magento's module structure conventions

**Module Development:**
- Create modules in `app/code/` directory
- Use proper module naming: `Vendor_ModuleName`
- Define module.xml, registration.php, and composer.json
- Use dependency injection for object creation
- Register plugins, preferences, and virtual types in di.xml

**Database:**
- Use declarative schema (db_schema.xml) for database changes
- Create data patches for data migrations
- Use resource models for database operations
- Never modify core tables directly

**Caching:**
- Use Magento's cache system appropriately
- Clear cache after configuration changes: `orodc exec bin/magento cache:flush`
- Use cache types for specific operations
- Implement cache invalidation properly

**Static Content:**
- Deploy static content after changes: `orodc exec bin/magento setup:static-content:deploy -f`
- Use LESS for styling (Magento 2.3 and earlier) or CSS (2.4+)
- Follow Magento's theme structure
- Use layout XML for page structure

**DI Compilation:**
- Compile DI after code changes: `orodc exec bin/magento setup:di:compile`
- Required after adding plugins, preferences, or virtual types
- Required after modifying di.xml files

**Best Practices:**
- Use repositories for entity access
- Implement service contracts for custom APIs
- Use events and observers for extensibility
- Follow Magento's versioning and backward compatibility rules
- Test with different Magento versions if supporting multiple
