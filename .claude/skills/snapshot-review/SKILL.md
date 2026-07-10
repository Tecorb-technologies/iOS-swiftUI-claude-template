---
name: snapshot-review
description: After a UI change, generates a description of what to visually check and reminds to update snapshot baselines. Use immediately after any change to a SwiftUI View's body, layout, or styling — before considering the change done — to produce a human-checkable visual diff summary and flag which snapshot-testing baselines need regenerating.
---

# Post-UI-Change Snapshot Review

This skill produces a *review artifact* — what a human should look at and which baselines need updating — it does not itself run snapshot tests. For the actual snapshot test conventions and how baselines are generated/stored, see `snapshot-testing`.

## When a View's body/layout/styling changes, produce this

1. **What changed visually** — a plain-language diff: "Card padding increased from `Spacing.sm` to `Spacing.md`; badge moved from trailing to leading; added a loading spinner overlay." Derive this from the actual diff, not from the commit message.
2. **What a human should check** — concrete visual checkpoints, not "make sure it looks right":
   - Does the new layout clip/overlap at the smallest supported device width?
   - Does it still look correct at `.accessibility3` Dynamic Type (per `accessibility`)?
   - Does it hold up in both light and dark mode?
   - If the change touched a shared `Core/DesignSystem` component, which other screens use it and should be spot-checked for regressions?
3. **Which snapshot baselines are now stale** — list the specific `SnapshotTests` test files/cases whose reference images cover the changed View, based on what `snapshot-testing` says gets snapshotted (device/size classes × light/dark).

## Output format

```
## Visual change summary
<plain-language diff>

## Check before merging
- [ ] <checkpoint>
- [ ] <checkpoint>

## Stale snapshot baselines
- Tests/SnapshotTests/<Feature>/<View>Tests.swift — regenerate: <command>
```

## Regenerating baselines

Point at the actual regeneration command/flag used by this project's snapshot test setup (see `snapshot-testing` for the swift-snapshot-testing `isRecording`/environment-variable convention) — don't just tell the developer "update your baselines" without saying how. Regenerating a baseline is a visual assertion that the *new* rendering is correct — remind the developer to actually look at the new reference image before committing it, not just regenerate and commit blindly.

## Scope

This applies to View-level changes (layout, styling, new states) — not to pure ViewModel/service logic changes with no rendering impact. A change that's purely `Core/Networking` or `Core/Persistence` doesn't need this review; a change to how a View renders, even if triggered by a ViewModel change, does.
