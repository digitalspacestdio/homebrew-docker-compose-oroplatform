## MODIFIED Requirements

### Requirement: Interactive Menu Display When No Arguments Provided

The system SHALL display an interactive menu when `orodc` is executed without any arguments in an interactive terminal. Menu items SHALL be conditionally displayed based on whether the project is an Oro Platform application. Menu SHALL support arrow key navigation and verbose mode toggle. Menu SHALL display detected CMS/framework type.

#### Scenario: Display CMS type in menu header
- **WHEN** menu is displayed
- **AND** project is in initialized directory
- **THEN** menu header SHALL display CMS type after "Current Directory" line
- **AND** CMS type SHALL be formatted as: "CMS Type: {display_name}"
- **AND** display names SHALL be:
  - "Oro Platform" for `oro` CMS type
  - "Magento 2" for `magento` CMS type  
  - "Base (PHP/Symfony/Laravel)" for `base` CMS type
- **AND** CMS type SHALL be detected using `detect_cms_type()` function

#### Scenario: Display CMS type for Oro project
- **WHEN** menu is displayed
- **AND** project is detected as Oro Platform (CMS type `oro`)
- **THEN** menu header SHALL show: "CMS Type: Oro Platform"
- **AND** CMS type SHALL be displayed in same section as environment status and directory

#### Scenario: Display CMS type for Magento project
- **WHEN** menu is displayed
- **AND** project is detected as Magento (CMS type `magento`)
- **THEN** menu header SHALL show: "CMS Type: Magento 2"
- **AND** CMS type SHALL be displayed in same section as environment status and directory

#### Scenario: Display CMS type for base PHP/Symfony/Laravel project
- **WHEN** menu is displayed
- **AND** project is detected as base type (CMS type `base`)
- **THEN** menu header SHALL show: "CMS Type: Base (PHP/Symfony/Laravel)"
- **AND** CMS type SHALL be displayed in same section as environment status and directory

#### Scenario: Hide CMS type when not in project
- **WHEN** menu is displayed
- **AND** current directory is not a project directory (no `DC_ORO_NAME` set)
- **THEN** CMS type line SHALL NOT be displayed
- **AND** only "Current Environment: - (not in project)" SHALL be shown

#### Scenario: CMS type updates on environment switch
- **WHEN** user switches environment via "List all environments" menu option
- **AND** new environment has different CMS type
- **THEN** menu SHALL be redrawn with updated CMS type
- **AND** CMS type SHALL reflect the new project's detection result
