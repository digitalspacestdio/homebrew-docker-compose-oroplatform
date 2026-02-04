## 1. Create Cursor Proxy Module

- [x] 1.1 Create `libexec/orodc/cursor.sh` following modular architecture pattern
- [x] 1.2 Check if `cursor` CLI is installed, show helpful error if missing
- [x] 1.3 Detect or load CMS type from `.env.orodc` or auto-detect (reuse existing detection logic)
- [x] 1.4 Generate `orodc help` output or locate README.md path (reuse existing logic from codex.sh/gemini.sh)
- [x] 1.5 Construct Cursor CLI command with appropriate configuration:
  - CMS type as context
  - Documentation (help output or README path)
  - System prompt for OroDC-only work (reuse system prompt generation from codex.sh/gemini.sh)
- [x] 1.6 Execute Cursor CLI with constructed configuration
- [x] 1.7 Handle all Cursor CLI arguments and pass them through

## 2. Add Command Route

- [x] 2.1 Add `cursor` case to command routing in `bin/orodc`
- [x] 2.2 Route to `libexec/orodc/cursor.sh` module
- [x] 2.3 Support interactive menu integration (if `DC_ORO_IS_INTERACTIVE_MENU` is set)

## 3. System Prompt Configuration

- [x] 3.1 Reuse system prompt generation logic from `codex.sh`/`gemini.sh` (same prompt structure)
- [x] 3.2 Determine Cursor CLI system prompt injection method (check Cursor CLI documentation for how to pass system prompt)
- [x] 3.3 Inject system prompt via Cursor CLI configuration (environment variable, config file, or CLI flag)
- [x] 3.4 Ensure system prompt is CMS-aware (mentions detected CMS type)

## 4. Documentation Context Generation

- [x] 4.1 Reuse documentation context generation from `codex.sh`/`gemini.sh`
- [x] 4.2 Determine best documentation source (prefer README.md if available, fallback to help output)
- [x] 4.3 Format documentation for Cursor CLI consumption (file path or content, depending on Cursor CLI API)

## 5. Testing

- [ ] 5.1 Test `orodc cursor` with Cursor CLI installed
- [ ] 5.2 Test error handling when Cursor CLI is not installed
- [ ] 5.3 Test CMS type auto-detection (reuse existing detection tests)
- [ ] 5.4 Test CMS type from `.env.orodc` configuration
- [ ] 5.5 Test documentation context (README.md vs help output)
- [ ] 5.6 Test system prompt injection
- [ ] 5.7 Test argument passthrough to Cursor CLI
- [ ] 5.8 Test in interactive menu context

## 6. Documentation

- [ ] 6.1 Update `README.md` with `orodc cursor` usage examples
- [ ] 6.2 Document Cursor CLI installation requirement
- [ ] 6.3 Update `AGENTS.md` to mention Cursor CLI integration alongside Codex and Gemini
