#!/bin/bash
# H4: Stop — run swiftlint across every changed .swift file as a final gate before
# a task counts as "done". Blocks (forces Claude to keep working) only when real
# violations are found; no-ops entirely when the template isn't bootstrapped yet
# or swiftlint isn't installed, so it can't wedge an in-progress template repo.

cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0

[ -f .claude/project.json ] || exit 0
command -v swiftlint >/dev/null 2>&1 || exit 0
command -v git >/dev/null 2>&1 || exit 0

changed=$(git diff --name-only --diff-filter=ACM HEAD 2>/dev/null | grep '\.swift$' || true)
[ -n "$changed" ] || exit 0

result=$(echo "$changed" | xargs swiftlint lint --quiet 2>&1 || true)
[ -n "$result" ] || exit 0

esc=$(echo "$result" | tr '\n' ' ' | sed 's/"/\\"/g')
printf '{"decision":"block","reason":"swiftlint found violations across the diff: %s Fix these before finishing.","hookSpecificOutput":{"hookEventName":"Stop","additionalContext":"swiftlint violations found in the diff — see reason."}}\n' "$esc"

exit 0
