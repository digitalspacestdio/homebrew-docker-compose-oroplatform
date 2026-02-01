# Magento 2 Project Instructions

**This file contains Magento 2-specific instructions.**
**For common instructions, see: `orodc agents common`**
**For Magento coding rules, see: `orodc agents rules`**

---

## ⚠️ CRITICAL: FOR NEW PROJECT INSTALLATION

**🔴 BEFORE STARTING ANY MAGENTO INSTALLATION, RUN THIS COMMAND:**

```bash
orodc agents installation magento
```

**This is MANDATORY to get the complete step-by-step installation guide with:**
- All required steps in correct order
- Sample data (demo data) installation if requested
- Frontend build (static content deployment) - REQUIRED
- OpenSearch configuration
- All critical steps that MUST NOT be skipped

**🚨 DO NOT attempt installation without reading the installation guide first!**

---

**Magento 2 Project**

**Documentation:**
- **INSTALLATION GUIDE**: Run `orodc agents installation magento` (REQUIRED for new projects)
- Full Magento setup guide: See `docs/MAGENTO.md` in OroDC repository
- Reference the documentation for complete installation steps, including:
  - Project creation (Mage-OS or Magento 2)
  - Installation via CLI with all required parameters
  - Sample data (demo data) installation when requested
  - Static content deployment (frontend build)
  - DI compilation
  - Two-Factor Authentication setup

**Creating New Project (Empty Directory):**
- **🔴 MANDATORY**: Run `orodc agents installation magento` FIRST to see complete step-by-step instructions
- **Community Edition (CE) via Composer**:
  - Mage-OS (open source): `orodc exec composer create-project --repository-url=https://repo.mage-os.org/ mage-os/project-community-edition .`
  - Magento 2 Official CE: `orodc exec composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition .`
  - **Note**: `composer create-project` installs Community Edition (CE) only. Requires Magento authentication keys for official repository (repo.magento.com)
- **Enterprise Edition**: Enterprise Edition requires access to private Magento Commerce repository (`magento/project-enterprise-edition`) and cannot be installed via public composer create-project. Use git clone from Enterprise repository or contact Magento support

**After Creating Project:**
- **🔴 ALWAYS follow complete setup steps from `orodc agents installation magento`** (run the command to see full guide)
- **CRITICAL steps** (DO NOT SKIP):
  - **OpenSearch configuration** (if using OpenSearch) - REQUIRED before Magento installation
  - Installation via `bin/magento setup:install`
  - **🔴 Sample data (demo data)** - MUST install if user requested demo data (see installation guide Step 6)
  - **🔴 Static content deployment (frontend build)** - REQUIRED, frontend will not work without it
  - DI compilation
  - Cache clearing
  - 2FA disabling (for development)
  - **Final step: `orodc up -d`** - ensure containers are running before accessing application
- Use environment variables from `orodc exec env | grep ORO_` for database and service configuration (shows all OroDC service connection variables)

**🚨 IMPORTANT - When User Requests Demo Data:**
- If user explicitly asks for demo data, sample data, or test products - YOU MUST execute Step 6 from installation guide
- Demo data includes: sample products, categories, CMS pages, sales data
- Command: `orodc exec bin/magento sampledata:deploy && orodc exec bin/magento setup:upgrade && orodc exec bin/magento cache:flush`
- DO NOT skip this step when user requests demo data!

**OpenSearch Configuration (Required for Magento 2 with OpenSearch):**
- **CRITICAL**: If using OpenSearch 2.0+, you MUST configure `indices.id_field_data.enabled` setting before installing Magento
- **Why**: OpenSearch 2.0+ disables fielddata access for `_id` field by default. Magento 2 requires this for product indexing and search
- **When**: Configure BEFORE running `bin/magento setup:install`
- **How to configure**:
  ```bash
  # Ensure containers are running
  orodc up -d
  
  # Configure OpenSearch
  orodc exec curl -X PUT "http://search:9200/_cluster/settings" \
    -H 'Content-Type: application/json' \
    -d '{"persistent": {"indices.id_field_data.enabled": true}}'
  
  # Verify setting was applied
  orodc exec curl -s "http://search:9200/_cluster/settings?include_defaults=true&flat_settings=true" | grep id_field_data
  ```
- **Note**: 
  - Only needed for OpenSearch (not Elasticsearch)
  - Setting persists across container restarts
  - Only need to configure once per OpenSearch cluster
  - If products are not showing in search after installation, check if this setting was configured

**Key Commands:**
- Magento CLI: `orodc exec bin/magento <command>`
- Cache operations: `orodc exec bin/magento cache:flush`
- Setup upgrade: `orodc exec bin/magento setup:upgrade`
- Compile DI: `orodc exec bin/magento setup:di:compile`
- Deploy static content: `orodc exec bin/magento setup:static-content:deploy -f`

**Admin Credentials:**
- **CRITICAL**: ALWAYS ask the user for admin username and password before performing admin operations with EXISTING admin account
- **NOTE**: For initial installation, see `orodc agents installation` - admin credentials should be auto-generated, not requested from user
- NEVER assume or use default credentials for existing admin operations
- NEVER create admin users or change passwords without explicit user request (except during initial installation)
- Ask user for admin credentials before:
  - Logging into admin panel (existing admin)
  - Creating additional admin users via CLI (`bin/magento admin:user:create` - requires existing admin credentials)
  - Changing admin passwords (`bin/magento admin:user:unlock` - requires existing admin credentials)
  - Performing any admin operations with existing admin account

**Common Tasks:**
- Clear cache: `orodc exec bin/magento cache:flush`
- Setup upgrade: `orodc exec bin/magento setup:upgrade`
- Compile DI: `orodc exec bin/magento setup:di:compile`
- Deploy static content: `orodc exec bin/magento setup:static-content:deploy -f`
- Reindex: `orodc exec bin/magento indexer:reindex`

**Troubleshooting:**
- **Products not showing in search**: Check if OpenSearch `indices.id_field_data.enabled` setting is configured (see OpenSearch Configuration section above)
- **Search not working**: Verify OpenSearch is running (`orodc ps | grep search`) and configured correctly
- **Frontend without styles**: Ensure static content was deployed with explicit locale: `orodc exec bin/magento setup:static-content:deploy en_US -f`
