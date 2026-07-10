#!/bin/bash
# H7: PostToolUse:Edit|Write — nudge Claude to invoke the security-auditor subagent
# after editing networking/persistence/auth-adjacent code. Hooks are shell commands
# and cannot invoke the Task/Agent tool directly, so this only injects
# additionalContext for Claude to act on next turn — a backstop to
# security-auditor.md's own auto-trigger description, not the sole trigger.

input=$(cat)

if command -v jq >/dev/null 2>&1; then
  path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
else
  path=$(echo "$input" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"file_path"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')
fi

[ -n "$path" ] || exit 0

if echo "$path" | grep -qiE 'Core/Networking|Core/Persistence|(auth|login|session|token|biometric|keychain|userdefaults)'; then
  printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s touches networking/persistence/auth-sensitive code. Invoke the security-auditor subagent now before considering this change done."}}\n' "$path"
fi

exit 0
