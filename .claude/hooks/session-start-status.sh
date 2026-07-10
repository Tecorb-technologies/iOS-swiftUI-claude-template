#!/bin/bash
# H5: SessionStart — print branch, last commit, and TODO/FIXME count so a developer
# starts each session with situational awareness instead of discovering it later.

cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "no-git")
last=$(git log -1 --oneline 2>/dev/null || echo "no commits yet")
todos=$(grep -rE 'TODO|FIXME' --include='*.swift' . 2>/dev/null | wc -l | tr -d ' ')

printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"Branch: %s | Last commit: %s | TODO/FIXME count: %s"}}\n' "$branch" "$last" "$todos"

exit 0
