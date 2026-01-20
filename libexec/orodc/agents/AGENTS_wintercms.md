# WinterCMS Project Instructions

**Note: WinterCMS is the community fork of OctoberCMS. They are compatible and use the same structure.**

**This file contains WinterCMS-specific instructions.**
**For common instructions, see: `orodc agents common`**
**For coding rules, see: `orodc agents rules`**

**WinterCMS Project (formerly OctoberCMS)**

**Creating New Project (Empty Directory):**
- **MUST follow installation guide**: Run `orodc agents installation wintercms` to see complete step-by-step instructions
- Use `orodc exec composer create-project wintercms/winter .` to create new WinterCMS project

**Key Commands:**
- Artisan CLI: `orodc exec artisan <command>`
- Cache operations: `orodc exec artisan cache:clear`
- Database migrations: `orodc exec artisan winter:up`
- Environment setup: `orodc exec artisan winter:env`

**Common Tasks:**
- Clear cache: `orodc exec artisan cache:clear`
- Clear config: `orodc exec artisan config:clear`
- Run migrations: `orodc exec artisan winter:up`
- Generate key: `orodc exec artisan key:generate`
- Setup environment: `orodc exec artisan winter:env`
- Interactive installer: `orodc exec artisan winter:install`
