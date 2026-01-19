# Git Hooks

This directory contains git hooks for code quality checks.

## Pre-commit Hook

The `pre-commit` hook automatically checks Bash scripts with `shellcheck` before committing.

### Installation

```bash
# Copy hook to .git/hooks
cp hooks/pre-commit .git/hooks/pre-commit

# Make it executable
chmod +x .git/hooks/pre-commit
```

### Requirements

- `shellcheck` - Install with: `brew install shellcheck`

### What it does

1. Checks if `shellcheck` is available (skips if not installed)
2. Finds all staged `.sh` files or files with bash/shebang
3. Checks syntax with `bash -n`
4. Runs `shellcheck` on each script
5. Blocks commit if any issues found

### Skip hook (if needed)

```bash
git commit --no-verify
```

### Features

- ✅ Only checks staged files (fast)
- ✅ Checks both `.sh` files and files with bash shebang
- ✅ Syntax check before shellcheck
- ✅ Colorized output
- ✅ Graceful handling if shellcheck not installed
- ✅ Clear error messages
