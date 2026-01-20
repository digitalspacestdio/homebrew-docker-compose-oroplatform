# Oro Platform Project Instructions

**This file contains Oro Platform-specific instructions.**
**For common instructions, see: `orodc agents common`**
**For Oro coding rules, see: `orodc agents rules`**

**Oro Platform Project (OroCommerce, OroCRM, etc.)**

**Creating New Project (Empty Directory):**
- **MUST follow installation guide**: Run `orodc agents installation` to see complete step-by-step instructions
- **Git clone (Recommended)**: 
  - OroCommerce: `orodc exec git clone --single-branch --branch 6.1.4 https://github.com/oroinc/orocommerce-application.git .`
  - OroPlatform: `orodc exec git clone --single-branch --branch 6.1 https://github.com/oroinc/platform-application.git .`
  - MarelloCommerce: Clone from Marello repository
- **Composer create-project (CE Edition only)**:
  - OroCommerce CE: `orodc exec composer create-project oro/commerce-application .`
  - OroPlatform CE: `orodc exec composer create-project oro/platform-application .`
  - **Note**: `composer create-project` installs Community Edition (CE) only. For Enterprise Edition, use git clone from Enterprise repository

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
