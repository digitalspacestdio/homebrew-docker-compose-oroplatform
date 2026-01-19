# Symfony Project Instructions

**This file contains Symfony-specific instructions.**
**For common instructions, see: `AGENTS_common.md`**
**For coding rules, see: `AGENTS_CODING_RULES_common.md`**

**Symfony Project**

**Creating New Project (Empty Directory):**
- **MUST follow installation guide**: See `AGENTS_INSTALLATION_symfony.md` for complete step-by-step instructions
- Use `orodc exec composer create-project` to create new Symfony project

**Key Commands:**
- Symfony console: `orodc exec bin/console <command>`
- Cache operations: `orodc exec bin/console cache:clear`
- Database migrations: `orodc exec bin/console doctrine:migrations:migrate`

**Common Tasks:**
- Clear cache: `orodc exec bin/console cache:clear`
- Warm up cache: `orodc exec bin/console cache:warmup`
- Run migrations: `orodc exec bin/console doctrine:migrations:migrate`
- Install assets: `orodc exec bin/console assets:install`
