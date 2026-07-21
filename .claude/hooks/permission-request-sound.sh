#!/bin/bash
# H9: PermissionRequest — plays a distinct macOS system sound just before Claude
# Code shows a permission-approval prompt, categorized by the tool being
# requested: Bash invoking git -> Hero.aiff, Bash otherwise -> Tink.aiff,
# Edit/Write/NotebookEdit -> Glass.aiff, WebFetch/WebSearch/any mcp__* tool ->
# Submarine.aiff, everything else -> Ping.aiff. Fires in every permission_mode
# (no gating) and emits NO JSON — this is a pure side effect, it never
# influences the permission decision itself. See .claude/hooks/README.md.

input=$(cat)

if command -v jq >/dev/null 2>&1; then
  tool_name=$(echo "$input" | jq -r '.tool_name // empty')
else
  tool_name=$(echo "$input" | grep -oE '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"tool_name"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')
fi

sound="/System/Library/Sounds/Ping.aiff"

case "$tool_name" in
  Bash)
    if command -v jq >/dev/null 2>&1; then
      cmd=$(echo "$input" | jq -r '.tool_input.command // empty')
    else
      cmd=$(echo "$input" | grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"command"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')
    fi
    if echo "$cmd" | grep -qE '\bgit\b'; then
      sound="/System/Library/Sounds/Hero.aiff"
    else
      sound="/System/Library/Sounds/Tink.aiff"
    fi
    ;;
  Edit|Write|NotebookEdit)
    sound="/System/Library/Sounds/Glass.aiff"
    ;;
  WebFetch|WebSearch|mcp__*)
    sound="/System/Library/Sounds/Submarine.aiff"
    ;;
  *)
    sound="/System/Library/Sounds/Ping.aiff"
    ;;
esac

if command -v afplay >/dev/null 2>&1; then
  ( afplay "$sound" >/dev/null 2>&1 & ) || true
fi

exit 0
