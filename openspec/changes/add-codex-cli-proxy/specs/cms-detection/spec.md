## MODIFIED Requirements

### Requirement: CMS Type Detection

The system SHALL detect the CMS type of the current project to determine which services should be started.

#### Scenario: Detect Oro Platform project
- **WHEN** `composer.json` exists in project directory
- **AND** `require` section contains `oro/platform`, `oro/commerce`, `oro/crm`, `oro/customer-portal`, or `marello/marello`
- **THEN** CMS type SHALL be detected as `oro`
- **AND** `detect_cms_type()` function SHALL return `oro`

#### Scenario: Detect Magento 2 project via composer.json
- **WHEN** `composer.json` exists in project directory
- **AND** `require` section contains `magento/product-community-edition`, `magento/product-enterprise-edition`, `magento/magento-cloud-metapackage`, or `mage-os/mage-os`
- **THEN** CMS type SHALL be detected as `magento`
- **AND** `detect_cms_type()` function SHALL return `magento`

#### Scenario: Detect Magento 2 project via project files
- **WHEN** project directory contains `bin/magento` executable
- **OR** project directory contains `app/etc/config.php`
- **OR** project directory contains `pub/index.php` with Magento structure
- **THEN** CMS type SHALL be detected as `magento`
- **AND** `detect_cms_type()` function SHALL return `magento`

#### Scenario: Detect Symfony project
- **WHEN** `composer.json` exists in project directory
- **AND** `require` section contains `symfony/symfony` or `symfony/framework-bundle`
- **THEN** CMS type SHALL be detected as `symfony`
- **AND** `detect_cms_type()` function SHALL return `symfony`

#### Scenario: Detect Laravel project
- **WHEN** `composer.json` exists in project directory
- **AND** `require` section contains `laravel/framework`
- **THEN** CMS type SHALL be detected as `laravel`
- **AND** `detect_cms_type()` function SHALL return `laravel`

#### Scenario: Default to base CMS type
- **WHEN** project does NOT match Oro, Magento, Symfony, or Laravel detection criteria
- **THEN** CMS type SHALL default to `base`
- **AND** `detect_cms_type()` function SHALL return `base`
- **AND** for external tools (like Codex CLI), `base` SHALL be exposed as `php-generic`

#### Scenario: No composer.json present
- **WHEN** `composer.json` does NOT exist in project directory
- **AND** no Magento-specific files are found
- **THEN** CMS type SHALL default to `base`
- **AND** `detect_cms_type()` function SHALL return `base`

### Requirement: Environment Variable Override for CMS Detection

The system SHALL allow explicit override of CMS type detection via `DC_ORO_CMS_TYPE` environment variable.

#### Scenario: Force Oro CMS type
- **WHEN** `DC_ORO_CMS_TYPE=oro` is set
- **THEN** CMS type SHALL be treated as `oro` regardless of project files
- **AND** Oro-specific services SHALL be enabled

#### Scenario: Force Magento CMS type
- **WHEN** `DC_ORO_CMS_TYPE=magento` is set
- **THEN** CMS type SHALL be treated as `magento` regardless of project files
- **AND** Magento-specific services SHALL be enabled

#### Scenario: Force Symfony CMS type
- **WHEN** `DC_ORO_CMS_TYPE=symfony` is set
- **THEN** CMS type SHALL be treated as `symfony` regardless of project files
- **AND** base services SHALL be enabled (no CMS-specific services)

#### Scenario: Force Laravel CMS type
- **WHEN** `DC_ORO_CMS_TYPE=laravel` is set
- **THEN** CMS type SHALL be treated as `laravel` regardless of project files
- **AND** base services SHALL be enabled (no CMS-specific services)

#### Scenario: Force PHP generic CMS type
- **WHEN** `DC_ORO_CMS_TYPE=php-generic` is set
- **THEN** CMS type SHALL be treated as `base` internally
- **AND** base services SHALL be enabled

#### Scenario: Force base CMS type
- **WHEN** `DC_ORO_CMS_TYPE=base` is set
- **THEN** CMS type SHALL be treated as `base` regardless of project files
- **AND** only base services SHALL be enabled

#### Scenario: Auto-detection when variable not set
- **WHEN** `DC_ORO_CMS_TYPE` environment variable is not set or empty
- **THEN** system SHALL auto-detect CMS type based on project files and `composer.json` analysis

### Requirement: CMS Type Priority

The system SHALL check detection sources in specific priority order.

#### Scenario: Environment variable takes highest priority
- **WHEN** `DC_ORO_CMS_TYPE` is set
- **THEN** detection SHALL use environment variable value
- **AND** SHALL NOT check `composer.json` or project files
- **AND** SHALL validate value is one of: `base`, `php-generic`, `symfony`, `laravel`, `magento`, `oro`

#### Scenario: Composer.json detection takes priority over file detection
- **WHEN** `DC_ORO_CMS_TYPE` is not set
- **AND** `composer.json` contains CMS-specific packages
- **THEN** detection SHALL use `composer.json` analysis
- **AND** SHALL NOT check project files

#### Scenario: File detection as fallback
- **WHEN** `DC_ORO_CMS_TYPE` is not set
- **AND** `composer.json` does not contain CMS-specific packages
- **AND** project files match CMS-specific patterns
- **THEN** detection SHALL use file-based detection
