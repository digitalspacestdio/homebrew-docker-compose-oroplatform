# Laravel Coding Rules

**Laravel-Specific Guidelines:**
- Follow Laravel coding standards (PSR-12)
- Use Laravel's service container and dependency injection
- Follow Laravel's directory structure conventions
- Use Laravel's facades appropriately
- Implement proper authentication and authorization

**Application Structure:**
- Follow Laravel's MVC pattern
- Use Laravel's service providers for service registration
- Use Laravel's middleware for request/response handling
- Use Laravel's routing system appropriately
- Follow Laravel's naming conventions

**Database:**
- Use Laravel migrations for database schema changes: `orodc exec artisan migrate`
- Use Eloquent ORM for database operations
- Never modify database schema directly
- Use database seeders for initial data

**Cache:**
- Clear cache after configuration changes: `orodc exec artisan cache:clear`
- Clear config cache: `orodc exec artisan config:clear`
- Use Laravel's cache system appropriately

**Best Practices:**
- Use Laravel's form requests for validation
- Use Laravel's policies and gates for authorization
- Implement proper error handling with Laravel's exception handling
- Use Laravel's events and listeners for extensibility
- Follow Laravel's versioning and upgrade guidelines
- Use Laravel's queue system for background jobs
