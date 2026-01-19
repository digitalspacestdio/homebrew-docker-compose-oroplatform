# Code Quality Rules

Detailed code quality rules for AI agents.

---

## Shellcheck is Mandatory

**WHEN EDITING BASH SCRIPTS:**

- **MUST** run `shellcheck` on ALL `.sh` files
- **MUST** run `read_lints` together with shellcheck
- **MUST** fix ALL warnings (except SC1091)
- **MUST** check syntax with `bash -n script.sh`
- **MUST NOT** commit without shellcheck

**WORKFLOW:**
```bash
# 1. Make changes
# 2. Run shellcheck
shellcheck libexec/orodc/lib/environment.sh

# 3. Fix warnings
# 4. Verify again
shellcheck libexec/orodc/lib/environment.sh

# 5. Check syntax
bash -n libexec/orodc/lib/environment.sh

# 6. Commit
```

**If shellcheck unavailable:** INSTALL IT FIRST before making changes.

---

## Shell Compatibility

**All commands MUST be zsh compatible:**

```bash
# ✅ CORRECT
echo "DC_ORO_MODE=mutagen" >> .env.orodc

# ❌ WRONG
echo 'DC_ORO_MODE="mutagen"' >> .env.orodc
```

---

## Terminal Output Rules

- **NEVER** use emojis in commands/output
- **NEVER** use Unicode symbols
- Use plain ASCII: `[OK]`, `[ERROR]`, `[INFO]`

```bash
# ✅ CORRECT
echo "[OK] Installation completed"

# ❌ WRONG  
echo "✅ Installation completed"
```

---

## Fix Root Cause, Not Symptoms

**⛔ NEVER:**
- Add fallbacks/workarounds without user confirmation
- Hide problems with default values or silent failures
- Create "safe" code paths that mask real issues

**✅ ALWAYS:**
- Fix the root cause of the problem
- Make code fail fast and clearly
- Investigate WHY something doesn't work

**WRONG:**
```bash
if ! find_and_export_ports; then
  export DC_ORO_PORT_MQ=15672  # ❌ Hides the real problem
fi
```

**CORRECT:**
```bash
# Fix why find_and_export_ports doesn't work
find_and_export_ports
```

---

## Never Modify User Files Without Permission

**⛔ FORBIDDEN:**
- `~/.zshrc`, `~/.bashrc`, `~/.profile`
- `~/.config/*`, `~/.env`
- `/etc/*`
- Any file outside git repository

**✅ ALLOWED:**
- Files within current git repository
- Temporary files in project directory
- Files explicitly mentioned by user

**CORRECT APPROACH:**
```bash
# ❌ WRONG
echo "export VAR=value" >> ~/.zshrc

# ✅ CORRECT - Show user what to add:
# User should add to ~/.zshrc:
# export VAR=value
```

---

## Version Updates

**Formula location:** `Formula/docker-compose-oroplatform.rb`

```ruby
version "0.8.6"  # Before

version "0.8.7"  # Bug fix (patch)
version "0.9.0"  # New feature (minor)
version "1.0.0"  # Breaking change (major)
```

**ALWAYS update version before committing changes to `compose/` or `bin/`**

When user says "version" - 90% means Formula version.

---

## After Modifying libexec/ or compose/

**MUST reinstall formula:**
```bash
brew reinstall digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform
```

**Why:** Homebrew copies files to Cellar on install.

**When to reinstall:**
- After changes to `libexec/orodc/*.sh`
- After changes to `libexec/orodc/lib/*.sh`
- After changes to `compose/` YAML files
- After changes to `bin/` scripts

**Exception:** Formula file changes apply immediately.
