---
name: snapshot-testing
description: swift-snapshot-testing conventions for Tecorb iOS apps — which device/size classes to snapshot (iPhone SE, iPhone 16 Pro Max, iPad), the light/dark mode matrix, and how baselines are recorded/regenerated. Use whenever adding a new SwiftUI View that needs a snapshot test, regenerating stale baselines, or reviewing SnapshotTests coverage.
---

# Tecorb Snapshot Testing Conventions

Tecorb apps use [pointfreeco/swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) via SPM (per the repo's SPM-only dependency policy) — not a hand-rolled image-diffing setup. This skill covers what to snapshot and the recording workflow; for *what to visually check* after a UI change before baselines are regenerated, see `snapshot-review`.

## Device/size class matrix

Every DesignSystem component and Feature screen View gets snapshot coverage across:

| Device | Why |
|---|---|
| iPhone SE (smallest supported width) | Catches clipping/truncation on the tightest layout |
| iPhone 16 Pro Max | Catches layout that assumes cramped width and looks sparse/wrong when it isn't |
| iPad (if the app supports iPad) | Catches regular-width layout regressions distinct from compact-width iPhone layouts |

Skip iPad snapshots for iPhone-only apps — check `.claude/project.json` or the target's supported device families before adding iPad cases that will never actually run differently.

## Light/dark mode matrix

Every device snapshot above is doubled for light and dark mode — a component that only gets tested in light mode has no regression protection for dark-mode-specific bugs (wrong color token, insufficient contrast).

```swift
@Test
func statusBadgeSnapshots() {
    for colorScheme in [ColorScheme.light, .dark] {
        for device in [ViewImageConfig.iPhoneSe, .iPhone13ProMax, .iPadPro11] {
            assertSnapshot(
                of: StatusBadge(status: .active).environment(\.colorScheme, colorScheme),
                as: .image(layout: .device(config: device)),
                named: "\(device.description)-\(colorScheme)"
            )
        }
    }
}
```

Factor the device/colorScheme matrix into a shared test helper (`Tests/SnapshotTests/Support/SnapshotMatrix.swift`) rather than re-writing the double loop in every test file.

## Recording new baselines

```bash
# Set isRecording = true (or the SNAPSHOT_RECORDING env var, per the library's current API)
# for the specific test run, then run:
xcodebuild test -scheme <scheme> -destination '...' -only-testing:SnapshotTests/<ViewName>Tests
# Review the newly written reference images under __Snapshots__/ before committing —
# a regenerated baseline is an assertion the new rendering is correct, not just "made the test pass."
```

Never regenerate a baseline to make a failing test pass without first confirming the new rendering is actually correct — that turns the test from a regression check into a no-op.

## What doesn't need a snapshot test

- Views with no meaningful visual state beyond what a unit test on the ViewModel already covers indirectly (rare — most Views with any layout are worth snapshotting).
- Transient/animation-only visual states — snapshot testing captures a single frame, so it's a poor fit for verifying animation itself (see `animation-motion` for that instead).

## Reviewing snapshot coverage

A new `Core/DesignSystem` component or `Features/<Feature>/Views/*` screen with a `#Preview` (required per `swiftui-components`) but no corresponding `Tests/SnapshotTests/` file is a gap — the preview states are the natural source for what the snapshot test cases should be.
