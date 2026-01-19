# Laravel Project Instructions

**This file contains Laravel-specific instructions.**
**For common instructions, see: `AGENTS_common.md`**
**For coding rules, see: `AGENTS_CODING_RULES_common.md`**

**Laravel Project**

**Creating New Project (Empty Directory):**
- **MUST follow installation guide**: See `AGENTS_INSTALLATION_laravel.md` for complete step-by-step instructions
- Use `orodc exec composer create-project laravel/laravel .` to create new Laravel project

**Key Commands:**
- Artisan CLI: `orodc exec artisan <command>`
- Cache operations: `orodc exec artisan cache:clear`
- Database migrations: `orodc exec artisan migrate`

**Common Tasks:**
- Clear cache: `orodc exec artisan cache:clear`
- Clear config: `orodc exec artisan config:clear`
- Run migrations: `orodc exec artisan migrate`
- Generate key: `orodc exec artisan key:generate`
