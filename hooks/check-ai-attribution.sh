#!/bin/bash
# Fail when the given text files carry AI attribution, such as
# "Co-Authored-By: Claude ...", "Generated with Claude Code" or a bot address
# (noreply@anthropic.com, cursoragent@cursor.com).
# Used by hooks/commit-msg and by the "No AI attribution" GitHub workflow.
# Usage: hooks/check-ai-attribution.sh FILE...
set -euo pipefail

tools='claude|anthropic|copilot|openai|chatgpt|codex|cursor|gemini|aider'
pattern="co-authored-by:.*(${tools})|generated (with|by) .*(${tools})|noreply@anthropic\.com|cursoragent@cursor\.com"

status=0
for file in "$@"; do
  # Git drops comment lines from commit messages, so do not check them.
  found=$(grep -v '^#' "${file}" | grep -niE "${pattern}" || true)
  if [[ -n "${found}" ]]; then
    echo "AI attribution found in ${file}; remove these lines:" >&2
    echo "${found}" >&2
    status=1
  fi
done

exit "${status}"
