# WinterCMS Coding Rules

**Note: WinterCMS is the community fork of OctoberCMS. They are compatible and use the same structure.**

**WinterCMS-Specific Guidelines:**
- Follow WinterCMS coding standards (Laravel-based with WinterCMS extensions)
- Use Laravel's service container and dependency injection
- Follow WinterCMS's plugin structure conventions
- Use WinterCMS's component system appropriately

**Project Structure:**
- Follow WinterCMS's directory structure conventions
- Create plugins following WinterCMS's naming conventions
- Use proper namespace structure for plugins

**Configuration:**
- Use WinterCMS's configuration system
- Define plugin configuration in plugin's `config.php`
- Use WinterCMS's settings system for user-configurable options

**Database:**
- Use Laravel migrations for database schema changes: `orodc exec artisan migrate`
- Use Eloquent ORM for database operations
- Never modify database schema directly
- Use database seeders for initial data

**Assets:**
- Build assets after changes: `orodc exec artisan winter:build`
- Use WinterCMS's asset management system
- Follow WinterCMS's theme structure

**Cache:**
- Clear cache after configuration changes: `orodc exec artisan cache:clear`
- Clear config cache: `orodc exec artisan config:clear`
- Use WinterCMS's cache system appropriately

**Security:**
- Use WinterCMS's form requests for validation
- Use WinterCMS's authorization system
- Implement proper error handling with Laravel's exception handling
- Use WinterCMS's events and listeners for extensibility
- Follow WinterCMS's versioning and upgrade guidelines
- Use Laravel's queue system for background jobs
