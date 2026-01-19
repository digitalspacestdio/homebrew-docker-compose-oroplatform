# Oro Platform Project Instructions

**This file contains Oro Platform-specific instructions.**
**For common instructions, see: `AGENTS_common.md`**
**For Oro coding rules, see: `AGENTS_CODING_RULES_oro.md`**

**Oro Platform Project (OroCommerce, OroCRM, etc.)**

**Creating New Project (Empty Directory):**
- **MUST follow installation guide**: See `AGENTS_INSTALLATION_oro.md` for complete step-by-step instructions
- OroCommerce: `orodc exec git clone --single-branch --branch 6.1.4 https://github.com/oroinc/orocommerce-application.git .`
- OroPlatform: `orodc exec git clone --single-branch --branch 6.1 https://github.com/oroinc/platform-application.git .`
- MarelloCommerce: Clone from Marello repository
- Note: Oro projects are typically cloned from GitHub repositories, not created via composer

**Key Commands:**
- Symfony console: `orodc exec bin/console <command>`
- Cache operations: `orodc exec bin/console cache:clear`
- Database migrations: `orodc exec bin/console oro:migration:load`
- Install assets: `orodc exec bin/console oro:assets:install`

**Admin Credentials:**
- **CRITICAL**: ALWAYS ask the user for admin username and password before performing admin operations
- NEVER assume or use default credentials
- NEVER create admin users or change passwords without explicit user request
- Ask user for admin credentials before:
  - Logging into admin panel
  - Creating admin users via CLI
  - Changing admin passwords
  - Performing any admin operations

**Common Tasks:**
- Clear cache: `orodc exec bin/console cache:clear`
- Warm up cache: `orodc exec bin/console cache:warmup`
- Install assets: `orodc exec bin/console oro:assets:install`
- Run migrations: `orodc exec bin/console oro:migration:load`
- Build assets: `orodc exec bin/console oro:assets:build default -w`
