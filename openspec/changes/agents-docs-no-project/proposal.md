# Change: Agents Command Does Not Require Project Validation

## Why

The agents command is documentation-only. It should provide system prompts
without requiring a project to be initialized. Current validation fails early
when `DC_ORO_APPDIR` is unset, which blocks using the command outside a
project directory.

## What Changes

- Skip global project validation for the agents command
- Keep agents command self-contained for CMS detection and prompt rendering

## Impact

- Affected code: global validation library in `libexec`
- Behavior: agents command works in any directory without requiring project
  initialization
- No impact on commands that require full project context
