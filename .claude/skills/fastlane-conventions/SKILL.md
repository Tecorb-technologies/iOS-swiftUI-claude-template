---
name: fastlane-conventions
description: Fastfile lane structure (test, beta, release) and match/certificate handling notes for Tecorb iOS apps — never printing secrets. Use whenever adding/modifying a Fastlane lane, setting up code signing with match, or running a beta/release lane.
---

# Tecorb Fastlane Conventions

Fastlane config lives under `Scripts/fastlane/` (per this template's folder structure). Three standard lanes — don't invent a fourth without a clear gap the three don't cover.

## Lane structure

```ruby
# Scripts/fastlane/Fastfile

desc "Run unit and UI tests"
lane :test do
  run_tests(scheme: "AppScheme", devices: ["iPhone 16 Pro"])
end

desc "Build and upload to TestFlight"
lane :beta do
  match(type: "appstore", readonly: true)
  increment_build_number(xcodeproj: "AppName.xcodeproj")
  build_app(scheme: "AppScheme", export_method: "app-store")
  upload_to_testflight(skip_waiting_for_build_processing: true)
end

desc "Submit the current TestFlight build to App Store review"
lane :release do
  deliver(submit_for_review: true, automatic_release: false)
end
```

- **`test`** — runs the same test suite CI runs (see `ci-pipeline`), for a local pre-push sanity check.
- **`beta`** — bumps build number, builds, uploads to TestFlight. This is the lane CI's `beta` stage calls (per `ci-pipeline`) and the one a developer runs manually for an ad hoc TestFlight build.
- **`release`** — promotes the current TestFlight build to App Store review. Kept separate from `beta` so submitting to review is always a deliberate, separate action, never an automatic side effect of a beta upload.

## match / certificate handling

- `match` manages signing certificates/profiles in a separate, encrypted git repo (`MATCH_GIT_URL`) — never commit `.p12`/`.mobileprovision` files to this app's repo.
- Lanes call `match(type: ..., readonly: true)` for CI and most local runs — `readonly: false` (which can register new devices/regenerate profiles) is a deliberate, manual action a developer runs when actually changing the signing setup, not something a lane defaults to.
- The match passphrase and any App Store Connect API key live in environment variables / CI secrets (`MATCH_PASSWORD`, `ASC_KEY_ID`, etc.) — never in `Fastfile`, never printed to logs. If a lane needs to reference one, use `ENV["MATCH_PASSWORD"]`, not a literal.

## Never print secrets

- Don't add `puts`/`UI.message` calls that echo an API key, password, or match passphrase, even for debugging — remove such lines before committing, and flag them in review if seen in a diff.
- Fastlane's own output can leak signing identity details in verbose/`--verbose` mode — avoid running `--verbose` in CI logs that are visible to a broader audience than the release team, unless actively debugging a signing issue in a private run.

## Running a lane

```bash
fastlane test
fastlane beta
fastlane release   # only after a beta build has been validated in TestFlight
```

`fastlane release` should never be run as part of routine work — it submits to App Store review. Confirm with the developer before running it, the same way a force-push or other hard-to-reverse action would need confirmation.
