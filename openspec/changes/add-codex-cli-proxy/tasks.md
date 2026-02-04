## 1. Extend CMS Detection

- [x] 1.1 Extend `detect_cms_type()` in `libexec/orodc/lib/common.sh` to detect Symfony projects (check for `symfony/symfony` in composer.json)
- [x] 1.2 Extend `detect_cms_type()` to detect Laravel projects (check for `laravel/framework` in composer.json)
- [x] 1.3 Add `php-generic` as explicit CMS type (maps to `base` internally but exposed as `php-generic` for Codex)
- [x] 1.4 Ensure CMS type detection returns: `php-generic`, `symfony`, `laravel`, `magento`, `oro`
- [x] 1.5 Add `DC_ORO_CMS_TYPE` support for all new CMS types

## 2. Create Codex Proxy Module

- [x] 2.1 Create `libexec/orodc/codex.sh` following modular architecture pattern
- [x] 2.2 Check if `codex` CLI is installed, show helpful error if missing
- [x] 2.3 Detect or load CMS type from `.env.orodc` or auto-detect
- [x] 2.4 Generate `orodc help` output or locate README.md path
- [x] 2.5 Construct Codex CLI command with appropriate configuration:
  - CMS type as context
  - Documentation (help output or README path)
  - System prompt for OroDC-only work
- [x] 2.6 Execute `codex cli` with constructed configuration
- [x] 2.7 Handle all Codex CLI arguments and pass them through

## 3. Add Command Route

- [x] 3.1 Add `codex` case to command routing in `bin/orodc`
- [x] 3.2 Route to `libexec/orodc/codex.sh` module
- [x] 3.3 Support interactive menu integration (if `DC_ORO_IS_INTERACTIVE_MENU` is set)

## 4. Optional: Add CMS Type to Init Wizard

- [x] 4.1 Add optional CMS type selection page to `libexec/orodc/init.sh` wizard
- [x] 4.2 Allow user to explicitly set CMS type: php-generic, symfony, laravel, magento, oro
- [x] 4.3 Save CMS type to `.env.orodc` as `DC_ORO_CMS_TYPE`
- [x] 4.4 Default to auto-detection if user skips this step

## 5. Documentation Context Generation

- [x] 5.1 Implement function to generate `orodc help` output
- [x] 5.2 Locate README.md path (project root or OroDC installation directory)
- [x] 5.3 Determine best documentation source (prefer README.md if available, fallback to help output)
- [x] 5.4 Format documentation for Codex consumption (file path or content)

## 6. System Prompt Configuration

- [x] 6.1 Create system prompt template that instructs Codex to:
  - Work only with OroDC commands (`orodc <command>`)
  - Understand OroDC project structure and conventions
  - Use appropriate CMS-specific patterns based on detected type
  - Reference OroDC documentation when needed
- [x] 6.2 Inject system prompt via Codex CLI configuration (`-c` flag or config file)
- [x] 6.3 Ensure system prompt is CMS-aware (mentions detected CMS type)

## 7. Testing

- [ ] 7.1 Test `orodc codex` with Codex CLI installed
- [ ] 7.2 Test error handling when Codex CLI is not installed
- [ ] 7.3 Test CMS type auto-detection (symfony, laravel, magento, oro, php-generic)
- [ ] 7.4 Test CMS type from `.env.orodc` configuration
- [ ] 7.5 Test documentation context (README.md vs help output)
- [ ] 7.6 Test system prompt injection
- [ ] 7.7 Test argument passthrough to Codex CLI
- [ ] 7.8 Test in interactive menu context

## 8. Documentation

- [x] 8.1 Update `README.md` with `orodc codex` usage examples
- [x] 8.2 Document CMS type detection and configuration
- [x] 8.3 Document Codex CLI installation requirement
- [ ] 8.4 Update `openspec/project.md` with Codex integration architecture
