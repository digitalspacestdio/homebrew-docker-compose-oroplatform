# Binary Structure and Paths

Understanding OroDC binary structure and path resolution.

---

## Two Execution Contexts

OroDC has TWO different execution contexts that affect path resolution:

### 1. Homebrew Installation (Production)

```
/usr/local/Cellar/docker-compose-oroplatform/X.Y.Z/
├── bin/
│   └── orodc -> ../libexec/orodc-main (symlink)
└── libexec/
    ├── orodc-main (copy of bin/orodc from tap)
    ├── orodc-find_free_port
    ├── orodc-sync
    └── orodc/ (modular structure)
        ├── cache.sh
        ├── search.sh
        ├── compose.sh
        └── lib/
            ├── common.sh
            ├── ui.sh
            └── environment.sh
```

### 2. Tap Directory (Development)

```
homebrew-docker-compose-oroplatform/
├── bin/
│   ├── orodc (real file, not symlink)
│   ├── orodc-find_free_port
│   └── orodc-sync
└── libexec/
    └── orodc/ (modular structure)
        ├── cache.sh
        ├── search.sh
        ├── compose.sh
        └── lib/
            ├── common.sh
            ├── ui.sh
            └── environment.sh
```

---

## Path Resolution Logic

```bash
SCRIPT_PATH="${BASH_SOURCE[0]}"
if [ -L "$SCRIPT_PATH" ]; then
  SCRIPT_PATH="$(readlink -f "$SCRIPT_PATH")"
fi
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

if [[ "$(basename "$SCRIPT_DIR")" == "bin" ]]; then
  # Development tap
  LIBEXEC_DIR="${SCRIPT_DIR}/../libexec/orodc"
else
  # Homebrew installation
  LIBEXEC_DIR="${SCRIPT_DIR}/orodc"
fi
```

---

## Key Differences

| Aspect | Homebrew | Tap Development |
|--------|----------|-----------------|
| `bin/orodc` | Symlink | Real file |
| `SCRIPT_DIR` | `.../libexec/` | `.../bin/` |
| `LIBEXEC_DIR` | `${SCRIPT_DIR}/orodc` | `${SCRIPT_DIR}/../libexec/orodc` |

---

## Cross-Platform Homebrew Locations

- **Linux**: `/home/linuxbrew/.linuxbrew`
- **macOS Intel**: `/usr/local`
- **macOS Apple Silicon**: `/opt/homebrew`

---

## Formula Installation Process

```ruby
def install
  # Copy main dispatcher to libexec
  (libexec/"orodc-main").write (tap_root/"bin/orodc").read
  (libexec/"orodc-main").chmod 0755
  
  # Copy modular structure
  if (tap_root/"libexec/orodc").exist?
    cp_r (tap_root/"libexec/orodc"), libexec
  end
  
  # Create bin symlink
  bin.install_symlink libexec/"orodc-main" => "orodc"
end
```

---

## Rules for Path Resolution

**✅ ALWAYS:**
- Check if `SCRIPT_DIR` basename is `bin` to detect tap
- Use conditional logic for `LIBEXEC_DIR`
- Test both contexts when modifying paths
- Follow symlinks with `readlink -f`

**❌ NEVER:**
- Assume `SCRIPT_DIR` is always same location
- Use hardcoded paths
- Forget symlink vs real file cases

---

## Testing Both Contexts

**Tap (development):**
```bash
cd /path/to/tap
./bin/orodc help
```

**Homebrew (production):**
```bash
brew reinstall digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform
orodc help
```

---

## Adding New Modules

```bash
# New module location
libexec/orodc/new-module.sh

# Router addition in bin/orodc
new-module)
  shift
  if [[ -n "${DC_ORO_IS_INTERACTIVE_MENU:-}" ]]; then
    execute_with_menu_return "${LIBEXEC_DIR}/new-module.sh" "$@"
  else
    exec "${LIBEXEC_DIR}/new-module.sh" "$@"
  fi
  ;;
```

---

## Always Start Analysis with Router

When analyzing any command or feature, **ALWAYS start with the router** (`bin/orodc`):

1. Check how command is routed
2. Check initialization flow (`initialize_environment`)
3. Check command flow

**Router location:** `bin/orodc`
- Lines 122-139: Environment initialization
- Lines 192-527: Command routing (case statement)

**⛔ NEVER** start analyzing individual scripts without checking router first.
