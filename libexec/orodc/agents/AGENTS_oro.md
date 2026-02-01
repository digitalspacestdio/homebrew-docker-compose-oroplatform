# Oro Platform Project Instructions

**This file contains Oro Platform-specific instructions.**
**For common instructions, see: `orodc agents common`**
**For Oro coding rules, see: `orodc agents rules`**

---

## ⚠️ CRITICAL: FOR NEW PROJECT INSTALLATION

**🔴 BEFORE STARTING ANY ORO INSTALLATION, RUN THIS COMMAND:**

```bash
orodc agents installation oro
```

**This is MANDATORY to get the complete step-by-step installation guide with:**
- All required steps in correct order
- Sample data (demo data) installation option (`--sample-data=y`)
- Assets build (frontend) - REQUIRED
- All critical steps that MUST NOT be skipped

**🚨 DO NOT attempt installation without reading the installation guide first!**

---

**Oro Platform Project (OroCommerce, OroCRM, etc.)**

**Creating New Project (Empty Directory):**
- **🔴 MANDATORY**: Run `orodc agents installation oro` FIRST to see complete step-by-step instructions
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
- **CRITICAL**: ALWAYS ask the user for admin username and password before performing admin operations with EXISTING admin account
- **NOTE**: For initial installation, see `orodc agents installation` - admin credentials should be auto-generated, not requested from user
- NEVER assume or use default credentials for existing admin operations
- NEVER create admin users or change passwords without explicit user request (except during initial installation)
- Ask user for admin credentials before:
  - Logging into admin panel (existing admin)
  - Creating additional admin users via CLI (requires existing admin credentials)
  - Changing admin passwords (requires existing admin credentials)
  - Performing any admin operations with existing admin account

**Common Tasks:**
- Clear cache: `orodc exec bin/console cache:clear`
- Warm up cache: `orodc exec bin/console cache:warmup`
- Install assets: `orodc exec bin/console oro:assets:install`
- Run migrations: `orodc exec bin/console oro:migration:load`
- Build assets: `orodc exec bin/console oro:assets:build default -w`

**🚨 IMPORTANT - When Installing New Oro Project:**
- **If user requests demo data** → use `--sample-data=y` in oro:install command
- **If user does NOT want demo data** → use `--sample-data=n` in oro:install command
- **Assets build is ALWAYS required** → `orodc exec bin/console oro:assets:build default -w`
- **DO NOT skip assets build** - frontend will not work without it!

**After Installation - CRITICAL Steps (DO NOT SKIP):**
1. **🔴 Assets build**: `orodc exec bin/console oro:assets:build default -w` - REQUIRED
2. **Cache operations**: `orodc exec bin/console cache:clear && orodc exec bin/console cache:warmup`
3. **Verify**: Access frontend and admin panel to confirm everything works
