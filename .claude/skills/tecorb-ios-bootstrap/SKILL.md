---
name: tecorb-ios-bootstrap
description: Bootstraps this Tecorb iOS SwiftUI template for a new client project. Auto-triggers when the repo is un-bootstrapped — .claude/project.json is absent AND no project.yml, Tuist/Project.swift, or *.xcodeproj exists anywhere under the repo root — and the developer's request implies build/run/feature work (e.g. "build this screen", "run the app", "add a feature", "let's start the project"), not a purely read-only or inspection question. Do not auto-trigger if .claude/project.json already exists — use the /bootstrap-ios command for that. Asks for app name, bundle ID + team, minimum iOS deployment target, backend style, Figma design source, CI target, and project generator preference; applies Tecorb's standing architecture defaults without asking; writes .claude/project.json; generates project.yml or Tuist config, xcconfigs, Info.plist values, and the App/<AppName>App.swift entry point; and updates CLAUDE.md with real values.
---

# Tecorb iOS Bootstrap

This template ships with a generic folder skeleton, lint/format config, and `.claude/` extension architecture, but no app-specific files — no `project.yml`/`Project.swift`, no `.xcodeproj`, no `App/<AppName>App.swift`. This skill turns the generic template into a real, buildable Xcode project for one specific client app.

## 1. Detect whether bootstrap is needed

Check, in order:
1. Does `.claude/project.json` exist? If yes, **stop** — already bootstrapped. Point the developer at `/bootstrap-ios --force` if they want to change an answer.
2. Does `project.yml`, `Tuist/Project.swift`, or any `*.xcodeproj` exist anywhere under the repo root? If yes, this repo has already been bootstrapped by other means — stop and ask the developer before doing anything, rather than assuming.
3. Is the developer's current request actually about building/running/adding a feature (not just asking "what's in here" or reading code)? If it's read-only, don't interrupt — just answer their question. Bootstrap when they try to do real work.

If all three checks say "needs bootstrapping," proceed.

## 2. Ask the project-context questions

Ask these in order, one at a time or in a short batch — whichever reads more naturally. State the default inline so the developer can just confirm rather than being asked an open-ended question for things Tecorb already has a house default for.

1. **App name** — no default, required.
2. **Bundle ID + team** — suggest `com.tecorb.<kebab-cased-app-name>` as the default bundle ID; ask for the Apple Developer **Team ID** separately (can't be derived, developer must provide it, or say "not yet" if signing isn't set up).
3. **Minimum iOS deployment target** — default **iOS 17** if the developer says "unsure" or skips.
4. **Backend style** — REST, GraphQL, or "none yet / TBD".
5. **Design source** — Figma file link, or "none yet".
6. **CI target** — Xcode Cloud or GitHub Actions.
7. **Project generator** — XcodeGen or Tuist. Only ask if not already implied by an existing (unusual, since detection in step 1 should have caught this) partial setup.

## 3. Tecorb standing defaults — apply, do not ask

- UI framework: SwiftUI-first; UIKit only where a SwiftUI gap requires it (bridge via `UIViewRepresentable`/`UIViewControllerRepresentable`).
- Architecture: MVVM + Swift Concurrency (`async`/`await`) + Observation (`@Observable`) — Combine only when bridging a delegate-based UIKit API with no async alternative.
- Dependency management: Swift Package Manager only. No CocoaPods/Carthage unless a dependency genuinely requires it — if so, stop and confirm with the developer before introducing it.
- Distribution: TestFlight now, App Store later.

## 4. Write `.claude/project.json`

```json
{
  "$schemaVersion": 1,
  "generatedAt": "<ISO-8601 timestamp>",
  "app": {
    "name": "<App Name>",
    "bundleIdPrefix": "com.tecorb",
    "bundleId": "com.tecorb.<kebab-app-name>",
    "teamId": "<Team ID or null>",
    "minIOSVersion": "17.0"
  },
  "toolchain": { "projectGenerator": "xcodegen | tuist", "dependencyManager": "spm" },
  "architecture": { "uiFramework": "swiftui-first", "pattern": "mvvm-observation", "concurrency": "swift-concurrency" },
  "backend": { "style": "rest | graphql | none", "baseURLPlaceholder": null },
  "design": { "figmaFileUrl": null },
  "ci": { "target": "xcode-cloud | github-actions" },
  "distribution": { "channel": "testflight-first" },
  "bootstrapHistory": [
    { "timestamp": "<ISO-8601 timestamp>", "action": "initial-bootstrap", "fieldsChanged": [] }
  ]
}
```

This file is the single source of truth other agents/commands read — don't duplicate these facts elsewhere without also updating this file.

## 5. Generate the app-specific scaffold

Before running any generator, check it's installed (`which xcodegen` or `which tuist`); if missing, tell the developer how to install it (`brew install xcodegen` / `brew install tuist`) and stop — don't try to work around a missing toolchain.

**If XcodeGen:**
- Write `project.yml` at the repo root: target name = app name, bundle id, deployment target, sources pointing at `App`, `Features`, `Core`, `Resources`; test targets pointing at `Tests/UnitTests`, `Tests/SnapshotTests`, `UITests`.
- Write `Config/Debug.xcconfig` and `Config/Release.xcconfig` with `PRODUCT_BUNDLE_IDENTIFIER`, `DEVELOPMENT_TEAM`, `IPHONEOS_DEPLOYMENT_TARGET`.
- Run `xcodegen generate` after confirming with the developer (this is the first broad-effect step — confirm once, not per file).

**If Tuist:**
- Write `Tuist/Project.swift` and `Tuist/Workspace.swift` with equivalent target/scheme definitions.
- Run `tuist generate` after confirming with the developer.

**Both:**
- Write `App/<AppName>App.swift` — a minimal SwiftUI `@main` `App` struct with an empty `ContentView` — tagged with a leading `// GENERATED-BY-BOOTSTRAP` comment so `/bootstrap-ios --force` can detect hand-edits later and avoid clobbering them.
- Populate `Info.plist` values (`CFBundleDisplayName`, `CFBundleName`) via the generator config rather than hand-editing a checked-in `Info.plist`.
- If `backend.style` is `rest` or `graphql`, add a minimal stub under `Core/Networking` (a bare `APIClient` shape for REST, or a note for GraphQL client setup) — don't build out a full networking layer speculatively, just enough to unblock the first feature.
- If `ci.target` is `github-actions`, write `.github/workflows/ios.yml` with a build+test job. If `xcode-cloud`, write `ci_scripts/ci_post_clone.sh`.
- Ensure `Resources/Assets.xcassets` contains an `AppIcon.appiconset` (an empty single-`1024x1024` set is fine — no image file needed). The generated Info.plist references `AppIcon` via `ASSETCATALOG_COMPILER_APPICON_NAME`, so a fresh catalog with only `Contents.json` fails the build with "None of the input catalogs contained a matching … app icon set named AppIcon".

## 6. Update CLAUDE.md

Fill in the app name, bundle ID, architecture, and CI sections with real values (see the CLAUDE.md structure already in this repo — sections 1–2 are app-specific, 3–8 are stable template documentation, don't touch those).

## 7. Verify the build end-to-end

Don't declare the bootstrap done until a real generate + build passes. Run these (substitute the recorded generator and the `<Scheme>` = app module name):

```bash
brew install xcodegen                 # or: brew install tuist — only if step 5 found it missing
xcodegen generate                     # or: tuist generate — creates <Scheme>.xcodeproj from project.yml
xcodebuild -list                      # confirm the scheme is "<Scheme>" — never guess it
xcodebuild build -scheme <Scheme> \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO             # CODE_SIGNING_ALLOWED=NO so a blank DEVELOPMENT_TEAM doesn't block the build
```

Notes:
- If the destination name is ambiguous (multiple installed OS versions for one device), pin it: `name=iPhone 16,OS=18.5`.
- These are shell commands — never append `# inline comments`, since an interactive zsh without `INTERACTIVE_COMMENTS` passes `#` as an argument and the command fails.
- If the build fails, fix the cause (e.g. the missing `AppIcon` set above) and re-run before reporting success.

## 8. Report back

Summarize what was created, confirm the build passed, and tell the developer the next step (`open <Scheme>.xcodeproj`, or scaffold the first feature).
