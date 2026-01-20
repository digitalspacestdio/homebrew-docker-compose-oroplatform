# Magento 2 Project Instructions

**This file contains Magento 2-specific instructions.**
**For common instructions, see: `orodc agents common`**
**For Magento coding rules, see: `orodc agents rules`**

**Magento 2 Project**

**Documentation:**
- Full Magento setup guide: See `docs/MAGENTO.md` in OroDC repository
- Reference the documentation for complete installation steps, including:
  - Project creation (Mage-OS or Magento 2)
  - Installation via CLI with all required parameters
  - Static content deployment
  - DI compilation
  - Two-Factor Authentication setup

**Creating New Project (Empty Directory):**
- **MUST follow installation guide**: Run `orodc agents installation magento` to see complete step-by-step instructions
- **Community Edition (CE) via Composer**:
  - Mage-OS (open source): `orodc exec composer create-project --repository-url=https://repo.mage-os.org/ mage-os/project-community-edition .`
  - Magento 2 Official CE: `orodc exec composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition .`
  - **Note**: `composer create-project` installs Community Edition (CE) only. Requires Magento authentication keys for official repository (repo.magento.com)
- **Enterprise Edition**: Enterprise Edition requires access to private Magento Commerce repository (`magento/project-enterprise-edition`) and cannot be installed via public composer create-project. Use git clone from Enterprise repository or contact Magento support

**After Creating Project:**
- ALWAYS follow complete setup steps from `orodc agents installation magento` (run the command to see full guide)
- Required steps include: installation, static content deployment, DI compilation, cache clearing, 2FA disabling
- Use environment variables from `orodc exec env | grep ORO_` for database and service configuration (shows all OroDC service connection variables)

**Key Commands:**
- Magento CLI: `orodc exec bin/magento <command>`
- Cache operations: `orodc exec bin/magento cache:flush`
- Setup upgrade: `orodc exec bin/magento setup:upgrade`
- Compile DI: `orodc exec bin/magento setup:di:compile`
- Deploy static content: `orodc exec bin/magento setup:static-content:deploy -f`

**Admin Credentials:**
- **CRITICAL**: ALWAYS ask the user for admin username and password before performing admin operations
- NEVER assume or use default credentials
- NEVER create admin users or change passwords without explicit user request
- Ask user for admin credentials before:
  - Logging into admin panel
  - Creating admin users via CLI (`bin/magento admin:user:create`)
  - Changing admin passwords (`bin/magento admin:user:unlock`)
  - Performing any admin operations

**Common Tasks:**
- Clear cache: `orodc exec bin/magento cache:flush`
- Setup upgrade: `orodc exec bin/magento setup:upgrade`
- Compile DI: `orodc exec bin/magento setup:di:compile`
- Deploy static content: `orodc exec bin/magento setup:static-content:deploy -f`
- Reindex: `orodc exec bin/magento indexer:reindex`
