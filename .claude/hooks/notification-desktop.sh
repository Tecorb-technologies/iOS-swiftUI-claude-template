#!/bin/bash
# H6: Notification — desktop alert on Claude Code's own notification events
# (permission prompts, idle waits). NOTE: Claude Code has no event that fires
# specifically "after a long build/test finishes" with duration info — this is
# the closest available approximation, not a literal per-build-duration trigger.

if command -v osascript >/dev/null 2>&1; then
  osascript -e 'display notification "Claude Code needs your attention" with title "Claude Code"' >/dev/null 2>&1 || true
fi

exit 0
