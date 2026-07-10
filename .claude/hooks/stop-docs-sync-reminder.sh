#!/bin/bash
# H8: Stop (advisory only — never blocks, per explicit instruction that doc writes
# should be reviewed, not auto-run). Reminds the developer to run /docs-sync when
# the diff touches public-facing behavior. NOTE: no .claude/commands/docs-sync.md
# exists yet in this template (only the docs-sync *skill* does) — this reminder is
# aspirational until that command file is added; it does not fail if missing.

cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
command -v git >/dev/null 2>&1 || exit 0

changed=$( { git diff --name-only HEAD 2>/dev/null; git diff --name-only --cached 2>/dev/null; } | sort -u)
[ -n "$changed" ] || exit 0

if echo "$changed" | grep -qE 'Features/.*/Views/|\.claude/commands/|Info\.plist|project\.yml|Tuist/'; then
  printf '{"hookSpecificOutput":{"hookEventName":"Stop","additionalContext":"This change touches public-facing behavior (screen, command, or config). Consider running /docs-sync before calling this done. Note: no .claude/commands/docs-sync.md exists yet in this template, only the docs-sync skill."}}\n'
fi

exit 0
