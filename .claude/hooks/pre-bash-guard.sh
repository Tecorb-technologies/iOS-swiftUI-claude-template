#!/bin/bash
# H1: PreToolUse:Bash — deny commands that leak Fastlane match/signing secrets or
# force-push straight to main/master. See .claude/hooks/README.md for rationale.
# Matches only high-confidence literal signals: false positives here cost more
# than a rare miss, so this stays narrow rather than clever.

input=$(cat)

if command -v jq >/dev/null 2>&1; then
  cmd=$(echo "$input" | jq -r '.tool_input.command // empty')
else
  cmd=$(echo "$input" | grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"command"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')
fi

reason=""

if echo "$cmd" | grep -qE 'MATCH_PASSWORD|ASC_KEY_ID|ASC_KEY_CONTENT'; then
  reason='Command references a Fastlane match/App Store Connect secret directly. Use ENV[...] inside the Fastfile, never a literal value in a shell command.'
elif echo "$cmd" | grep -qE 'match\(' && echo "$cmd" | grep -qE 'readonly:[[:space:]]*false'; then
  reason='Command runs match(readonly: false), which can rotate/regenerate signing certs and profiles. Confirm explicitly with the developer before running this.'
elif echo "$cmd" | grep -qE 'git push' && echo "$cmd" | grep -qE -- '(--force|-f\b)' && echo "$cmd" | grep -qE '\b(main|master)\b'; then
  reason='Force-push to main/master detected. Confirm explicitly with the developer before running this.'
fi

if [ -n "$reason" ]; then
  esc=$(echo "$reason" | sed 's/"/\\"/g')
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$esc"
fi

exit 0
