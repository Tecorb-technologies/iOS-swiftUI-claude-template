#!/bin/bash
# H3: PostToolUse:Edit|Write — after a test file is written/edited, suggest running
# just that target for fast feedback (mirrors test-engineer's targeted-run pattern),
# instead of running the full suite. Advisory only: a real xcodebuild test run can
# take 30s+, so this hook suggests the command rather than blocking on running it.

input=$(cat)

if command -v jq >/dev/null 2>&1; then
  path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
else
  path=$(echo "$input" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"file_path"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')
fi

case "$path" in
  *Tests/UnitTests/*Tests.swift) target="UnitTests" ;;
  *Tests/SnapshotTests/*Tests.swift) target="SnapshotTests" ;;
  *UITests/*Tests.swift) target="UITests" ;;
  *) exit 0 ;;
esac

project_root="${CLAUDE_PROJECT_DIR:-.}"

if [ ! -f "$project_root/.claude/project.json" ]; then
  printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"Test file written but the project is not bootstrapped yet (.claude/project.json missing), so %s cannot be run. Run /bootstrap-ios first."}}\n' "$target"
  exit 0
fi

command -v xcodebuild >/dev/null 2>&1 || exit 0

class=$(basename "$path" .swift)
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"Run just this test now for fast feedback: xcodebuild test -scheme <scheme> -destination platform=iOS Simulator,name=<simulator> -only-testing:%s/%s"}}\n' "$target" "$class"

exit 0
