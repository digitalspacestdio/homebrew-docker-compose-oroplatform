# Change: Add Codex CLI Proxy Command

## Why

Codex CLI is a powerful AI coding assistant that can help developers work with OroDC projects. However, to provide the best assistance, Codex needs context about:
1. The CMS/framework type (PHP generic, Symfony, Laravel, Magento) to understand project structure
2. OroDC documentation (`orodc help` output or README) to understand available commands
3. A system prompt that constrains the agent to work only with OroDC commands and conventions

This change adds an `orodc codex` command that automatically configures Codex CLI with the appropriate context, making it easier for developers to get AI assistance tailored to their OroDC project.

## What Changes

- Add `orodc codex` command that proxies to `codex cli`
- Auto-detect CMS type (php generic, symfony, laravel, magento) or use value from `.env.orodc` config
- Pass `orodc help` output or README.md path as documentation context to Codex
- Configure system prompt that instructs Codex to work only with OroDC commands
- Add CMS type configuration option to `orodc init` wizard (optional step)
- Create `libexec/orodc/codex.sh` module following modular architecture pattern

## Impact

- Affected specs: `codex-integration` (new), `cli-architecture` (modified - new command route), `cms-detection` (modified - expose CMS type for Codex), `interactive-init` (modified - optional CMS type prompt)
- Affected code:
  - `bin/orodc` (add `codex` command route)
  - `libexec/orodc/codex.sh` (new module for Codex proxy)
  - `libexec/orodc/lib/common.sh` (extend CMS detection to support symfony/laravel)
  - `libexec/orodc/init.sh` (optional CMS type configuration step)
- No breaking changes - purely additive feature
- Requires Codex CLI to be installed separately (not bundled)
