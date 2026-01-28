## ADDED Requirements

### Requirement: Oro Project Detection from composer.json

The system SHALL detect whether the current project is an Oro Platform application by analyzing `composer.json` dependencies.

#### Scenario: Detect Oro Platform project
- **WHEN** `composer.json` exists in project directory
- **AND** `require` section contains `oro/platform`
- **THEN** project SHALL be identified as Oro project
- **AND** `is_oro_project()` function SHALL return true

#### Scenario: Detect OroCommerce project
- **WHEN** `composer.json` exists in project directory
- **AND** `require` section contains `oro/commerce`
- **THEN** project SHALL be identified as Oro project

#### Scenario: Detect OroCRM project
- **WHEN** `composer.json` exists in project directory
- **AND** `require` section contains `oro/crm`
- **THEN** project SHALL be identified as Oro project

#### Scenario: Detect Marello project
- **WHEN** `composer.json` exists in project directory
- **AND** `require` section contains `marello/marello`
- **THEN** project SHALL be identified as Oro project

#### Scenario: Non-Oro PHP project
- **WHEN** `composer.json` exists in project directory
- **AND** `require` section does NOT contain any Oro packages (`oro/platform`, `oro/commerce`, `oro/crm`, `oro/customer-portal`, `marello/marello`)
- **THEN** project SHALL NOT be identified as Oro project
- **AND** `is_oro_project()` function SHALL return false

#### Scenario: No composer.json present
- **WHEN** `composer.json` does NOT exist in project directory
- **THEN** project SHALL NOT be identified as Oro project
- **AND** `is_oro_project()` function SHALL return false

### Requirement: Environment Variable Override for Oro Detection

The system SHALL allow explicit override of Oro project detection via `DC_ORO_IS_ORO_PROJECT` environment variable.

#### Scenario: Force Oro project mode
- **WHEN** `DC_ORO_IS_ORO_PROJECT=1` or `DC_ORO_IS_ORO_PROJECT=true` is set
- **THEN** project SHALL be treated as Oro project regardless of `composer.json` contents
- **AND** Oro-specific features SHALL be enabled

#### Scenario: Force non-Oro project mode
- **WHEN** `DC_ORO_IS_ORO_PROJECT=0` or `DC_ORO_IS_ORO_PROJECT=false` is set
- **THEN** project SHALL be treated as non-Oro project regardless of `composer.json` contents
- **AND** Oro-specific features SHALL be disabled

#### Scenario: Auto-detection when variable not set
- **WHEN** `DC_ORO_IS_ORO_PROJECT` environment variable is not set or empty
- **THEN** system SHALL auto-detect based on `composer.json` analysis
