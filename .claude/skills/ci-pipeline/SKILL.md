---
name: ci-pipeline
description: What each Tecorb iOS CI stage does (lint, build, unit test, UI test, archive, upload) and how to read a failed CI run. Use whenever setting up or modifying CI config (.github/workflows/ios.yml or ci_scripts/), or when diagnosing a failed CI run.
---

# Tecorb CI Pipeline

CI target (Xcode Cloud or GitHub Actions) is recorded in `.claude/project.json`'s `ci.target`, set at bootstrap. The stage sequence is the same regardless of which runs it — only the config syntax differs.

## Stage sequence

1. **Lint** — `swiftlint lint` (and `swiftformat --lint` to catch un-formatted code) against the whole repo except `Tests/`/`UITests/` per `.swiftlint.yml`'s force-unwrap exception. Fails fast before spending build minutes on a lint violation.
2. **Build** — `xcodebuild build -scheme <scheme> -destination '...'` (or `swift build` for a pure-SPM package target). Catches compile errors and, under Swift 6 strict concurrency, `Sendable`/actor-isolation errors (see `concurrency-safety`).
3. **Unit test** — `xcodebuild test -only-testing:UnitTests` (or `swift test`). Runs `Tests/UnitTests` per `ios-testing`'s conventions.
4. **UI test** — `xcodebuild test -only-testing:UITests`, on a real simulator boot. Slower than unit tests — some pipelines run this only on `main`/release branches rather than every PR; check `.claude/project.json`/the workflow file for which policy this project uses rather than assuming.
5. **Archive** — `xcodebuild archive` producing an `.xcarchive`, only on branches that trigger a release path (typically `main` or a release branch), not on every PR.
6. **Upload** — `fastlane beta` (per `fastlane-conventions`) or an equivalent `altool`/App Store Connect API upload, only after archive succeeds.

Stages 5–6 don't run on every PR — gate them on branch/tag per the workflow config, otherwise every PR triggers a TestFlight upload, which is not the intent.

## GitHub Actions shape

```yaml
# .github/workflows/ios.yml
jobs:
  lint:
    steps: [ ... swiftlint lint, swiftformat --lint ... ]
  build-and-test:
    needs: lint
    steps: [ ... xcodegen generate (or tuist generate), xcodebuild build, xcodebuild test ... ]
  archive-and-upload:
    needs: build-and-test
    if: github.ref == 'refs/heads/main'
    steps: [ ... xcodebuild archive, fastlane beta ... ]
```

## Xcode Cloud shape

`ci_scripts/ci_post_clone.sh` handles dependency setup (project generator run, if not committing the generated project) before Xcode Cloud's own build/test/archive stages, which are configured via workflow settings in App Store Connect rather than a YAML file in-repo.

## Reading a failed CI run

1. **Which stage failed** — lint/build failures are usually the fastest to fix (a lint violation or compile error, read the exact file:line from the log). Test failures need the actual test output, not just "tests failed" — pull the specific failing test name and assertion message.
2. **Is it a real regression or flaky?** — a UI test failing with a timeout/`waitForExistence` issue on an otherwise-passing PR is more likely flaky (see `ui-testing`'s note on avoiding fixed `sleep` delays) than a unit test failing with a clear assertion mismatch, which is almost always real.
3. **Reproduce locally** before assuming a fix — `ios-build-test-runner` runs the same commands locally that CI runs, so a "fixed" CI failure can be verified before pushing again.

## Modifying the pipeline

Changes to `.github/workflows/ios.yml`/`ci_scripts/` are CI-affecting changes visible to the whole team on every subsequent PR — confirm with the developer before changing stage gating, required-status-check config, or removing a stage, the same as any other shared-infrastructure change.
