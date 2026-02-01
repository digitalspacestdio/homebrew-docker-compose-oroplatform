# Change: Add Cursor CLI Proxy Command

## Why

Cursor CLI is a powerful AI coding assistant that can help developers work with OroDC projects. However, to provide the best assistance, Cursor CLI needs context about:
1. The CMS/framework type (PHP generic, Symfony, Laravel, Magento, Oro) to understand project structure
2. OroDC documentation (`orodc help` output or README) to understand available commands
3. A system prompt that constrains the agent to work only with OroDC commands and conventions

This change adds an `orodc cursor` command that automatically configures Cursor CLI with the appropriate context, making it easier for developers to get AI assistance tailored to their OroDC project.

## What Changes

- Add `orodc cursor` command that proxies to Cursor CLI
- Auto-detect CMS type (php generic, symfony, laravel, magento, oro) or use value from `.env.orodc` config
- Pass `orodc help` output or README.md path as documentation context to Cursor CLI
- Configure system prompt that instructs Cursor CLI to work only with OroDC commands
- Create `libexec/orodc/cursor.sh` module following modular architecture pattern

## Impact

- Affected specs: `cursor-integration` (new), `cli-architecture` (modified - new command route)
- Affected code:
  - `bin/orodc` (add `cursor` command route)
  - `libexec/orodc/cursor.sh` (new module for Cursor CLI proxy)
- No breaking changes - purely additive feature
- Requires Cursor CLI to be installed separately (not bundled)
