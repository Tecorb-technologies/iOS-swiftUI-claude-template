# Hooks reference

`.claude/settings.json` cannot hold comments, so every hook's purpose and rationale
lives here instead. Each entry below matches a `command` referenced from
`.claude/settings.json`, plus the two pre-existing inline hooks defined directly in
that file (kept as short one-liners rather than moved into scripts).

All new hook logic lives in this directory as standalone `.sh` files, each with an
inline comment repeating the summary below — read either place, they should agree.

## Existing hooks (defined inline in `.claude/settings.json`, unchanged)

**Bootstrap nudge** — `PreToolUse` on `Write|Edit|Bash`. If `.claude/project.json`
is missing, injects a reminder to run `/bootstrap-ios` or the `tecorb-ios-bootstrap`
skill before writing app code. This is why you've been seeing that reminder while
these hook files were being written — expected, since the template genuinely isn't
bootstrapped yet.

**Changelog nudge** — `PostToolUse` on `Bash`. After a `git commit` runs, suggests
drafting a `CHANGELOG.md` entry and asks before writing it.

## New hooks

### H1 — `pre-bash-guard.sh` (`PreToolUse:Bash`, **blocking**)
Denies (`permissionDecision: deny`) any Bash command that: references a Fastlane
match/App Store Connect secret literally (`MATCH_PASSWORD`, `ASC_KEY_ID`,
`ASC_KEY_CONTENT`), calls `match(readonly: false)` (which can rotate signing certs),
or force-pushes (`--force`/`-f`) with `main`/`master` as the target. This is the
first hard-blocking hook in this repo — matches only high-confidence literal
signals on purpose, since a false-positive block costs more here than a rare miss.
Known gap: doesn't yet catch a force-push via an explicit refspec like
`git push -f origin feature:main` — the branch check only looks for a bare
`main`/`master` token anywhere in the command.

### H2 — `post-edit-format-lint.sh` (`PostToolUse:Edit|Write`, advisory)
Filters to `*.swift` files. Runs `swiftformat` then `swiftlint --fix` on the touched
file, then reports any violations that couldn't be auto-fixed as additional context.
No-ops silently (with a one-line note) if `swiftformat`/`swiftlint` aren't installed
— expected on a freshly cloned, not-yet-bootstrapped template.

### H3 — `post-edit-test-runner.sh` (`PostToolUse:Edit|Write`, advisory)
Filters to test files under `Tests/UnitTests`, `Tests/SnapshotTests`, or `UITests`.
Suggests the exact `xcodebuild test -only-testing:<Target>/<Class>` command for just
that test (mirrors `test-engineer.md`'s targeted-run convention) rather than running
the full suite. Deliberately advisory instead of running `xcodebuild` synchronously
inside the hook — a real test run can take 30s+, which would stall the tool-response
loop. No-ops if `.claude/project.json` is missing or `xcodebuild` isn't available.

### H4 — `stop-lint-gate.sh` (`Stop`, **blocking**)
Runs `swiftlint lint` over every changed `*.swift` file (`git diff` against `HEAD`).
If violations are found, emits `{"decision":"block",...}`, forcing Claude to address
them before the turn ends — this is the "final gate" a task must clear. No-ops
entirely (never blocks) when `.claude/project.json` is missing or `swiftlint` isn't
installed, so it can't wedge the still-unbootstrapped template.

### H5 — `session-start-status.sh` (`SessionStart`, advisory)
Prints current branch, last commit, and a repo-wide `TODO|FIXME` count over
`*.swift` files as additional context, so a session starts with situational
awareness instead of the developer having to ask for it.

### H6 — `notification-desktop.sh` (`Notification`, side-effect only)
Fires an `osascript` desktop notification whenever Claude Code emits its own
`Notification` event (permission prompts, idle waits). **Scope note:** Claude Code
has no hook event that fires specifically "a long build/test just finished" with
duration information — this is the closest available approximation to what was
asked for, not a literal per-build-duration trigger.

### H7 — `post-edit-security-nudge.sh` (`PostToolUse:Edit|Write`, advisory)
Filters to paths under `Core/Networking`, `Core/Persistence`, or containing an
auth/login/session/token/biometric/keychain/userdefaults keyword. Injects additional
context telling Claude to invoke the `security-auditor` subagent now. **Important:**
hooks are shell commands — they cannot invoke the Task/Agent tool directly. This is
a backstop that makes the nudge explicit and hook-enforced, alongside (not instead
of) `security-auditor.md`'s own auto-trigger description.

### H8 — `stop-docs-sync-reminder.sh` (`Stop`, advisory only — never blocks)
If the diff touches `Features/*/Views/`, `.claude/commands/`, `Info.plist`,
`project.yml`, or `Tuist/`, reminds the developer to run `/docs-sync` before calling
the task done. Deliberately advisory per explicit instruction — doc writes should be
reviewed by a human, not auto-run. **Known gap:** no `.claude/commands/docs-sync.md`
file exists yet in this template (only the `docs-sync` *skill* does) — the reminder
says so explicitly rather than silently pointing at a command that doesn't exist.

## Conventions for adding another hook

- One `.sh` file per hook, named `<event>-<what-it-does>.sh`, with the same
  one-paragraph summary as a leading comment and here in this README.
- Read `tool_input.file_path` / `tool_input.command` from stdin JSON via `jq` when
  available, falling back to a `grep`/`sed` extraction otherwise (this repo can't
  assume every developer machine has `jq`).
- Always guard on the tool you shell out to actually being installed
  (`command -v <tool>`) and, for anything build/test/lint related, on
  `.claude/project.json` existing — this template ships unbootstrapped, and a hook
  erroring out on a fresh clone is worse than one that silently no-ops.
- Advisory output: `{"hookSpecificOutput":{"hookEventName":"<Event>","additionalContext":"..."}}`.
- Blocking output: `PreToolUse` uses `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"..."}}`;
  `Stop` uses a top-level `{"decision":"block","reason":"..."}`. These are different
  field shapes — don't mix them up between event types.
