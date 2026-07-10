---
name: release-checklist
description: Version/build number bump rules (semantic version + auto build number), changelog generation from commit history, screenshot refresh reminders, and App Store metadata location for Tecorb iOS apps. Only invoke explicitly (/release-checklist or equivalent) when actually cutting a release — never auto-trigger, since this touches version numbers and release-facing artifacts.
disable-model-invocation: true
---

# Release Checklist

`disable-model-invocation: true` — this only runs when explicitly invoked. Cutting a release touches version numbers, changelogs, and store metadata; it shouldn't happen as a side effect of an unrelated request.

## Version/build number bump

- **Marketing version** (`CFBundleShortVersionString`) — semantic versioning (`MAJOR.MINOR.PATCH`). Bump `MAJOR` for breaking user-facing changes or a significant relaunch, `MINOR` for new features, `PATCH` for fixes only. Ask the developer which tier this release is if it's not obvious from the changelog being generated below — don't guess on a MAJOR bump.
- **Build number** (`CFBundleVersion`) — monotonically increasing integer, bumped on every TestFlight/App Store submission regardless of whether the marketing version changed. Never reuse or decrease a build number for a given marketing version.
- Both live in `Config/*.xcconfig` (per the bootstrap-generated xcconfig setup) or the project generator config (`project.yml`/`Tuist/Project.swift`) — bump them there, not by hand-editing a checked-in `Info.plist`.

## Changelog generation from commit history

```bash
git log <previous-release-tag>..HEAD --oneline
```

Turn this into a user-facing changelog (not a raw commit dump) — group by feature/fix, drop internal-only commits (refactors, test additions, CI config) that have no user-visible effect, and phrase entries in terms of what changed for the user, not what the diff touched. Propose the entry and confirm with the developer before writing it, per the `changelog-entry` habit already wired into this repo's PostToolUse hook for regular commits — a release changelog is the aggregated, cleaned-up version of those per-commit proposals, not a separate invention.

## Screenshot refresh reminder

If this release changes any screen's visual appearance (check against recent `snapshot-review` output or the diff itself for `Features/*/Views/` changes), flag that App Store screenshots may need refreshing — don't submit stale screenshots that no longer match the shipped UI. This is a reminder to the developer, not something this skill generates itself (screenshot capture is a manual/Fastlane `snapshot` step, see `fastlane-conventions`).

## App Store metadata location

- `store.config.json` (per `apple-skills:apple-aso`) — title, subtitle, description, keywords, localized variants. Use `apple-skills:apple-aso` when actually optimizing/editing this content; this skill just points at where it lives during a release pass.
- Screenshots and preview videos — wherever this project's Fastlane `Deliverfile`/`Snapfile` points (see `fastlane-conventions`).

## The checklist

1. Confirm all tests pass and the build is clean (`ios-build-test-runner`).
2. Bump marketing version (if applicable) and build number.
3. Generate and confirm the changelog with the developer.
4. Flag screenshot refresh if UI changed.
5. Confirm `store.config.json` metadata is current for this release's changes.
6. Hand off to `fastlane-conventions`' beta/release lane to actually build and upload.

Report the checklist as a literal checklist with pass/fail/needs-action per item — don't just narrate that "things look fine."
