#!/bin/bash
# H2: PostToolUse:Edit|Write — auto-run swiftformat + swiftlint --fix on the touched
# .swift file, then surface any violations swiftlint couldn't auto-fix. No-ops
# silently if the tools aren't installed (this template may be pre-bootstrap).

input=$(cat)

if command -v jq >/dev/null 2>&1; then
  path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
else
  path=$(echo "$input" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"file_path"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')
fi

case "$path" in
  *.swift) ;;
  *) exit 0 ;;
esac

[ -f "$path" ] || exit 0

if ! command -v swiftformat >/dev/null 2>&1 || ! command -v swiftlint >/dev/null 2>&1; then
  printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"swiftformat/swiftlint not installed — skipped auto-fix on %s. Install with: brew install swiftformat swiftlint"}}\n' "$path"
  exit 0
fi

swiftformat "$path" >/dev/null 2>&1 || true
swiftlint --fix --path "$path" >/dev/null 2>&1 || true
remaining=$(swiftlint lint --path "$path" --quiet 2>&1 || true)

if [ -n "$remaining" ]; then
  esc=$(echo "$remaining" | tr '\n' ' ' | sed 's/"/\\"/g')
  printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"swiftlint found violations in %s that could not be auto-fixed: %s"}}\n' "$path" "$esc"
fi

exit 0
