## Context

Cursor CLI is an external AI coding assistant tool that developers can use to get help with their projects. To provide effective assistance, Cursor CLI needs:
1. **CMS/Framework Context**: Understanding whether the project is PHP generic, Symfony, Laravel, Magento, or Oro Platform
2. **Documentation Context**: Access to OroDC command reference and project documentation
3. **System Constraints**: Instructions to work within OroDC conventions and use only OroDC commands

This change creates a proxy command that automatically configures Cursor CLI with the appropriate context for OroDC projects, following the same pattern as Codex and Gemini integrations.

## Goals / Non-Goals

### Goals
- Provide seamless integration between OroDC and Cursor CLI
- Reuse existing CMS type detection logic (no changes needed)
- Reuse existing documentation context generation (from codex.sh/gemini.sh)
- Reuse existing system prompt generation (from codex.sh/gemini.sh)
- Follow existing modular architecture patterns
- Maintain consistency with Codex and Gemini integrations

### Non-Goals
- Bundling Cursor CLI with OroDC (external dependency)
- Modifying Cursor CLI itself
- Changing CMS detection logic (reuse existing)
- Changing system prompt structure (reuse existing)
- Supporting other AI assistants beyond Codex, Gemini, and Cursor

## Decisions

### Decision: Reuse Existing Logic
- **What**: Reuse CMS detection, documentation context, and system prompt generation from `codex.sh`/`gemini.sh`
- **Why**: Consistency across AI integrations, reduces code duplication, proven patterns
- **Alternatives considered**:
  - Create new logic (rejected - unnecessary duplication)
  - Extract shared logic to common library (future improvement, not needed now)

### Decision: Cursor CLI System Prompt Injection Method
- **What**: Determine Cursor CLI's method for accepting system prompts (environment variable, config file, or CLI flag)
- **Why**: Cursor CLI may use different mechanism than Codex (`experimental_instructions_file`) or Gemini (`GEMINI_SYSTEM_MD`)
- **Alternatives considered**:
  - Assume same as Codex (rejected - need to verify Cursor CLI API)
  - Assume same as Gemini (rejected - need to verify Cursor CLI API)
  - Check Cursor CLI documentation (required - implementation step)

### Decision: Command Name
- **What**: Use `orodc cursor` as command name
- **Why**: Consistent with `orodc codex` and `orodc gemini` patterns
- **Alternatives considered**:
  - `orodc cursor-cli` (rejected - redundant, CLI is implied)
  - `orodc ai cursor` (rejected - inconsistent with existing commands)

### Decision: Module File Location
- **What**: Create `libexec/orodc/cursor.sh` following modular architecture
- **Why**: Consistent with `codex.sh` and `gemini.sh` location
- **Alternatives considered**:
  - Group in `libexec/orodc/ai/cursor.sh` (rejected - inconsistent with current structure)

## Risks / Trade-offs

### Risk: Cursor CLI Not Installed
- **Mitigation**: Check for `cursor` binary, show helpful error message with installation instructions

### Risk: Cursor CLI API Unknown
- **Mitigation**: Research Cursor CLI documentation during implementation, adapt system prompt injection method accordingly

### Risk: Cursor CLI API Different from Codex/Gemini
- **Mitigation**: Implement adapter logic if needed, but reuse all other logic (CMS detection, documentation, system prompt content)

### Trade-off: External Dependency
- **Impact**: Users must install Cursor CLI separately
- **Benefit**: Keeps OroDC focused, allows Cursor CLI to evolve independently

### Trade-off: Code Duplication
- **Impact**: Some logic duplicated across codex.sh, gemini.sh, and cursor.sh
- **Benefit**: Simpler implementation, easier to maintain individual integrations
- **Future**: Could extract shared logic to common library if more AI integrations are added

## Migration Plan

### For Existing Users
- No migration required - purely additive feature
- Existing CMS detection continues to work
- New `orodc cursor` command available immediately

### For New Users
- Optional: Install Cursor CLI separately
- Use `orodc cursor` directly (auto-detects CMS type, same as codex/gemini)

## Open Questions

- What is the exact Cursor CLI command name and how does it accept system prompts?
- Does Cursor CLI support environment variables for configuration?
- Should we validate Cursor CLI version compatibility?
- Should we support passing custom prompts to Cursor CLI via `orodc cursor "prompt text"`?
