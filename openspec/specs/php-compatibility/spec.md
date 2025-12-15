# php-compatibility Specification

## Purpose
TBD - created by archiving change improve-cli-ux-and-php-support. Update Purpose after archive.
## Requirements
### Requirement: PHP 7.3 Support
The system SHALL support PHP 7.3 for legacy OroPlatform projects.

#### Scenario: PHP 7.3 available in version selector
- **WHEN** user runs `orodc init`
- **THEN** PHP 7.3 SHALL be available in version selector
- **AND** Node.js 18 SHALL be the only compatible option for PHP 7.3

#### Scenario: Auto-detect PHP 7.3 from composer.json
- **WHEN** `composer.json` specifies PHP 7.3
- **THEN** system SHALL detect and display "Detected PHP version from composer.json: 7.3"
- **AND** Node.js 18 SHALL be selected as compatible version

#### Scenario: Generate correct image for PHP 7.3
- **WHEN** user selects PHP 7.3 and Node.js 18
- **THEN** image SHALL be `ghcr.io/digitalspacestdio/orodc-php-node-symfony:7.3-node18-composer2-alpine`

### Requirement: Correct Node.js Defaults for PHP Versions
The system SHALL select optimal Node.js versions as defaults for each PHP version.

#### Scenario: PHP 8.5 defaults to Node.js 24
- **WHEN** user selects PHP 8.5
- **THEN** Node.js 24 SHALL be default
- **AND** Node.js 22 SHALL be available as alternative

#### Scenario: PHP 8.4 defaults to Node.js 22
- **WHEN** user selects PHP 8.4
- **THEN** Node.js 22 SHALL be default
- **AND** Node.js 20, 18 SHALL be available as alternatives

#### Scenario: PHP 8.1-8.3 default to Node.js 20
- **WHEN** user selects PHP 8.1, 8.2, or 8.3
- **THEN** Node.js 20 SHALL be default
- **AND** Node.js 22, 18, 16 SHALL be available as alternatives (version availability varies by PHP)

#### Scenario: PHP 7.4 defaults to Node.js 16
- **WHEN** user selects PHP 7.4
- **THEN** Node.js 16 SHALL be default
- **AND** Node.js 18 SHALL be available as alternative

#### Scenario: PHP 7.3 defaults to Node.js 18
- **WHEN** user selects PHP 7.3
- **THEN** Node.js 18 SHALL be default and only option

### Requirement: PHP Version Auto-Detection
The system SHALL automatically detect PHP version from project files.

#### Scenario: Detect from composer.json require.php
- **WHEN** `composer.json` contains `"require": {"php": "7.3.*"}`
- **THEN** system SHALL extract "7.3" as detected PHP version

#### Scenario: Detect from .php-version file
- **WHEN** `.php-version` file exists with content "8.4"
- **THEN** system SHALL use "8.4" as detected PHP version
- **AND** detection SHALL take priority over `composer.json`

#### Scenario: Detect from .phprc file
- **WHEN** `.phprc` file exists
- **THEN** system SHALL parse PHP version from it
- **AND** detection SHALL take priority over `composer.json` but lower than `.php-version`

### Requirement: Node.js Compatibility Matrix
The system SHALL enforce correct Node.js compatibility for each PHP version.

#### Scenario: PHP 8.5 compatibility
- **WHEN** PHP 8.5 is selected
- **THEN** available Node.js versions SHALL be: 24, 22

#### Scenario: PHP 8.4 compatibility
- **WHEN** PHP 8.4 is selected
- **THEN** available Node.js versions SHALL be: 22, 20, 18

#### Scenario: PHP 8.1-8.3 compatibility
- **WHEN** PHP 8.1, 8.2, or 8.3 is selected
- **THEN** available Node.js versions SHALL include: 22, 20, 18 (and 16 for 8.1)

#### Scenario: PHP 7.4 compatibility
- **WHEN** PHP 7.4 is selected
- **THEN** available Node.js versions SHALL be: 18, 16

#### Scenario: PHP 7.3 compatibility
- **WHEN** PHP 7.3 is selected
- **THEN** available Node.js version SHALL be: 18 only

### Requirement: Version Sorting
The system SHALL display versions in descending order (newest first).

#### Scenario: PHP versions sorted newest to oldest
- **WHEN** displaying PHP version selector
- **THEN** versions SHALL be ordered: 8.5, 8.4, 8.3, 8.2, 8.1, 7.4, 7.3

#### Scenario: Node.js versions sorted newest to oldest
- **WHEN** displaying Node.js version selector for any PHP
- **THEN** versions SHALL be ordered from highest to lowest (e.g., 24, 22, 20, 18, 16)

#### Scenario: Database versions sorted newest to oldest
- **WHEN** displaying PostgreSQL versions
- **THEN** versions SHALL be ordered: 17.4, 16.6, 15.1
- **WHEN** displaying MySQL versions
- **THEN** versions SHALL be ordered: 9.0, 8.4, 8.0, 5.7

