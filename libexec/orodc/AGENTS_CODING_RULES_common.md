# Common Coding Rules

**General Coding Guidelines:**
- Follow PSR-12 coding standards for PHP code
- Use meaningful variable and function names
- Write self-documenting code with clear comments where needed
- Keep functions focused on a single responsibility
- Avoid deep nesting (max 3-4 levels)
- Use early returns to reduce complexity

**Code Organization:**
- Group related functionality together
- Separate concerns (business logic, presentation, data access)
- Use namespaces appropriately
- Follow framework conventions for file structure

**Error Handling:**
- Always handle errors gracefully
- Provide meaningful error messages
- Log errors appropriately
- Never expose sensitive information in error messages

**Security:**
- Validate and sanitize all user input
- Use prepared statements for database queries
- Never trust user input
- Follow OWASP security best practices
- Keep dependencies up to date

**Performance:**
- Optimize database queries (avoid N+1 problems)
- Use caching where appropriate
- Minimize external API calls
- Profile code before optimizing

**Testing:**
- Write tests for critical functionality
- Test edge cases and error conditions
- Keep tests maintainable and readable
- Use appropriate testing frameworks
