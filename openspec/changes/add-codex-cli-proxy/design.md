## Context

Codex CLI is an external AI coding assistant tool that developers can use to get help with their projects. To provide effective assistance, Codex needs:
1. **CMS/Framework Context**: Understanding whether the project is PHP generic, Symfony, Laravel, Magento, or Oro Platform
2. **Documentation Context**: Access to OroDC command reference and project documentation
3. **System Constraints**: Instructions to work within OroDC conventions and use only OroDC commands

This change creates a proxy command that automatically configures Codex CLI with the appropriate context for OroDC projects.

## Goals / Non-Goals

### Goals
- Provide seamless integration between OroDC and Codex CLI
- Auto-detect CMS type or allow explicit configuration
- Pass relevant documentation to Codex (README or help output)
- Constrain Codex to work only with OroDC commands via system prompt
- Follow existing modular architecture patterns

### Non-Goals
- Bundling Codex CLI with OroDC (external dependency)
- Modifying Codex CLI itself
- Supporting other AI assistants (only Codex CLI)
- Replacing existing OroDC commands with AI-generated alternatives

## Decisions

### Decision: CMS Type Detection
- **What**: Extend existing `detect_cms_type()` to support Symfony and Laravel detection
- **Why**: Codex needs to know the CMS type to provide appropriate assistance
- **Alternatives considered**:
  - Always require explicit configuration (rejected - auto-detection is better UX)
  - Only support existing CMS types (rejected - Symfony/Laravel are common PHP frameworks)

### Decision: Documentation Source Priority
- **What**: Prefer README.md path, fallback to `orodc help` output
- **Why**: README.md provides comprehensive documentation, help output is more concise
- **Alternatives considered**:
  - Always use help output (rejected - README is more complete)
  - Always use README (rejected - may not be available in all contexts)

### Decision: System Prompt Injection Method
- **What**: Use Codex CLI `-c` config flag or config file to inject system prompt
- **Why**: Codex CLI supports configuration overrides via `-c` flag
- **Alternatives considered**:
  - Pass as initial prompt (rejected - system prompt is more persistent)
  - Use Codex config file (acceptable - but CLI flag is more explicit)

### Decision: CMS Type Values
- **What**: Use values: `php-generic`, `symfony`, `laravel`, `magento`, `oro`
- **Why**: Clear, explicit values that Codex can understand
- **Alternatives considered**:
  - Use internal `base` value (rejected - `php-generic` is clearer for Codex)
  - Use framework names only (rejected - need `php-generic` for non-framework projects)

### Decision: Optional Init Wizard Step
- **What**: Add optional CMS type selection to `orodc init` wizard
- **Why**: Allows users to explicitly set CMS type if auto-detection fails
- **Alternatives considered**:
  - Always require CMS type (rejected - auto-detection should be default)
  - Never prompt (rejected - explicit configuration is useful for edge cases)

## Risks / Trade-offs

### Risk: Codex CLI Not Installed
- **Mitigation**: Check for `codex` binary, show helpful error message with installation instructions

### Risk: CMS Type Detection Fails
- **Mitigation**: Default to `php-generic`, allow explicit override via `DC_ORO_CMS_TYPE`

### Risk: Documentation Not Available
- **Mitigation**: Fallback chain: README.md → `orodc help` output → minimal context

### Risk: System Prompt Too Restrictive
- **Mitigation**: System prompt should guide, not restrict - allow Codex to suggest improvements while working within OroDC conventions

### Trade-off: External Dependency
- **Impact**: Users must install Codex CLI separately
- **Benefit**: Keeps OroDC focused, allows Codex to evolve independently

## Migration Plan

### For Existing Users
- No migration required - purely additive feature
- Existing CMS detection continues to work
- New `orodc codex` command available immediately

### For New Users
- Optional: Run `orodc init` and optionally set CMS type
- Or: Use `orodc codex` directly (auto-detects CMS type)

## Open Questions

- Should we cache `orodc help` output to avoid re-running on every `orodc codex` call?
- Should we support passing custom prompts to Codex via `orodc codex "prompt text"`?
- Should we validate Codex CLI version compatibility?
