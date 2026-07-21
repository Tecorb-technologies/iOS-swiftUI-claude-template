# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Status: Permission (bootstrapped)

This repo has been bootstrapped from the Tecorb iOS SwiftUI template into a specific client app, **Permission**.

- **App name**: Permission (project/target/scheme + `CFBundleDisplayName`)
- **Bundle ID**: `com.tecorb.permission` (prefix `com.tecorb`)
- **Development Team**: not set yet (signing to be configured later)
- **Minimum iOS**: 17.0
- **Project generator**: XcodeGen (`project.yml` → `CloudToFigma.xcodeproj`; Tuist not used)
- **Backend**: REST-shaped service layer (`Core/Networking`) currently backed by bundled dummy JSON via `MockAPIClient`; swap to `LiveAPIClient` against a real base URL when the backend exists.
- **Design source**: Figma — <https://www.figma.com/design/TwzxAuxO4lVNOk86R9oLly/claudeTofigma> (pull via the `figma` MCP; authenticate with `/mcp → figma → Authenticate`).
- **CI**: GitHub Actions (`.github/workflows/ios.yml`).
- **Theme**: light + dark, following the device appearance automatically (no pinned `preferredColorScheme`); semantic tokens live in `Core/DesignSystem/AppColor.swift`.

`.claude/project.json` is the single source of truth other agents/commands read — check it for these recorded facts. To change an answer, run `/bootstrap-ios --force` (or `--field=value`).

## Architecture (standing Tecorb defaults)

- **UI framework**: SwiftUI-first. UIKit only where a SwiftUI gap requires it, bridged via `UIViewRepresentable`/`UIViewControllerRepresentable`.
- **Pattern**: MVVM + Swift Concurrency (`async`/`await`) + Observation (`@Observable`) — not `ObservableObject`+`@Published`. Combine only to bridge a delegate-based UIKit API with no async alternative.
- **Dependencies**: Swift Package Manager only. No CocoaPods/Carthage unless a dependency genuinely requires it.
- **Distribution**: TestFlight now, App Store later.

See the `tecorb-ios-architecture` skill for concrete do/don't code patterns.

## Folder structure

```
App/                 SwiftUI @main entry point (generated at bootstrap)
Features/<Feature>/  Views/, ViewModels/, Models/ — one subfolder per feature
Core/
  Networking/        Shared networking layer (REST or GraphQL, per bootstrap answer)
  Persistence/        Shared local persistence (e.g. SwiftData)
  DesignSystem/       Shared SwiftUI components, colors, typography, tokens
  Utilities/          Small dependency-free helpers
  Extensions/         Type extensions, one type per file
Resources/           Assets.xcassets, Localizable.xcstrings, Fonts/
Tests/
  UnitTests/          Swift Testing, mirrors Features/Core structure
  SnapshotTests/      View snapshot tests
UITests/             XCUITest end-to-end flows
Scripts/             CI helpers, fastlane, XcodeGen/Tuist config (generated at bootstrap)
```

## Build, test, and lint

Once bootstrapped (see Status above):
- Generate/refresh the Xcode project: `xcodegen generate` (or `tuist generate`, per `.claude/project.json`'s `toolchain.projectGenerator`).
- Confirm the scheme: `xcodebuild -list`.
- Build: `xcodebuild build -scheme <scheme> -destination 'platform=iOS Simulator,name=<simulator>'`.
- Test (all): `xcodebuild test -scheme <scheme> -destination '...'`. For a single test: append `-only-testing:<TargetName>/<TestClass>/<testMethod>`.
- Pure-SPM packages (no simulator needed): `swift build`, `swift test`.
- Lint: `swiftlint lint`. Format: `swiftformat .`. Config lives in `.swiftlint.yml`/`.swiftformat` at the repo root (line length 120, force-unwrap/force-try/force-cast disallowed outside `Tests/`/`UITests/`, explicit `self` removed rather than enforced, imports sorted).

## `.claude/` extension architecture

| Type | Name | Purpose |
|---|---|---|
| Skill | `tecorb-ios-bootstrap` | Auto-triggers on an un-bootstrapped repo; asks project-context questions, writes `.claude/project.json`, generates the app-specific scaffold. |
| Command | `/bootstrap-ios` | Explicit, idempotent re-run of the bootstrap flow (`--force` to change an answer, `--field=value` to update one field). |
| Skill | `tecorb-ios-architecture` | Reference for MVVM+Observation+Concurrency conventions, folder layout, and the do/don't patterns agents follow. |
| Agent | `ios-swiftui-engineer` | Builds/modifies Views, ViewModels, Models, and `Core/DesignSystem` components. |
| Agent | `swift-code-reviewer` | Read-only review: architecture boundaries, concurrency correctness, lint/format compliance. |
| Agent | `ios-build-test-runner` | Regenerates the project and runs real `xcodebuild`/`swift test` output. |
| Agent | `test-engineer` | Writes and runs targeted unit/UI/snapshot tests in an isolated context. |
| Agent | `qa-runner` | Runs the full test suite cheaply (haiku), reports failures only. |
| Agent | `release-manager` | Version bump, changelog, Fastlane lanes, TestFlight upload — explicit invocation only. |
| Agent | `accessibility-auditor` | Reviews new/changed Views for VoiceOver, Dynamic Type, tap targets, contrast. |
| Agent | `security-auditor` | Runs the MASVS/security skills against networking, auth, and persistence changes. |
| Agent | `docs-maintainer` | Runs `docs-sync` in isolation, reports a summary of doc updates. |
| MCP | figma (remote) | Figma design context for design-to-code and ios-swiftui-engineer. Registered in .mcp.json; run /mcp → figma → Authenticate on first use. Provides get_design_context, get_variable_defs, get_screenshot, and Code Connect tools. |
| Hook | `PreToolUse` on `Write\|Edit\|Bash` | Nudges toward bootstrapping if `.claude/project.json` is missing. |
| Hook | `PreToolUse` on `Bash` | Blocks (`deny`) commands that leak Fastlane match/signing secrets or force-push `--force`/`-f` to `main`/`master`. |
| Hook | `PostToolUse` on `Bash` | Suggests a CHANGELOG.md entry after a `git commit`. |
| Hook | `PostToolUse` on `Edit\|Write` (`*.swift`) | Auto-runs `swiftformat` + `swiftlint --fix` on the touched file; reports unfixable violations. |
| Hook | `PostToolUse` on `Edit\|Write` (test files) | Suggests a targeted `-only-testing:<Target>/<Class>` run instead of the full suite. |
| Hook | `PostToolUse` on `Edit\|Write` (`Core/Networking`, `Core/Persistence`, auth/token/session code) | Nudges Claude to invoke `security-auditor` now. |
| Hook | `Stop` | Runs `swiftlint` across the changed diff as a final gate; blocks completion on real violations. |
| Hook | `Stop` (secondary) | If the diff touches public-facing behavior (new screen/command/config), reminds to run `/docs-sync` — advisory only, never auto-runs. |
| Hook | `SessionStart` | Prints current git branch, last commit, and TODO/FIXME count. |
| Hook | `Notification` | Fires a desktop notification on Claude Code's notification events. |

All hook scripts live under `.claude/hooks/`, with per-hook rationale and conventions in `.claude/hooks/README.md` (JSON can't hold comments, so that file is the source of truth for "why").

## Distribution and CI

TestFlight-first distribution. CI target (Xcode Cloud or GitHub Actions) is recorded in `.claude/project.json`'s `ci.target` once bootstrapped, and the corresponding workflow file (`.github/workflows/ios.yml` or `ci_scripts/`) is generated at that point.

## Quality gates

Before considering iOS work done: `swift-code-reviewer` for architecture/correctness review, `ios-build-test-runner` for a real build+test pass, plus the generic `code-review`/`security-review`/`verify` skills for broader cleanup or security passes when relevant.

## Regeneration note

The "Status" and "Architecture" sections above get filled in with real values the first time `/bootstrap-ios` runs against an actual client project. The rest of this file (folder structure, build commands, extension architecture table, quality gates) is stable template documentation and shouldn't need to change per-project.
