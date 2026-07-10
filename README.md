# Tecorb iOS SwiftUI Bootstrap Template

A reusable Tecorb-wide starting point for a new iOS Swift/SwiftUI client project. This repo is a **template**, not a specific app: the folder skeleton, lint/format config, and `.claude/` Claude Code extension set already exist, but the app-specific pieces (`project.yml`/`Project.swift`, `.xcodeproj`, app entry point) don't exist until the template is bootstrapped against a real client project.

## Table of contents

- [Status](#status)
- [Architecture](#architecture)
- [Concurrency model](#concurrency-model)
- [Networking layer](#networking-layer)
- [Persistence layer](#persistence-layer)
- [Design system](#design-system)
- [Folder structure](#folder-structure)
- [Build system](#build-system)
- [Testing strategy](#testing-strategy)
- [CI/CD pipeline](#cicd-pipeline)
- [Release process](#release-process)
- [Security conventions](#security-conventions)
- [Code style and static analysis](#code-style-and-static-analysis)
- [Claude Code integration](#claude-code-integration)

## Status

This template has **not been bootstrapped yet** — there's no Xcode project, scheme, target, or app entry point until that happens. `.claude/project.json` (the single source of truth for app name, bundle ID, backend style, CI target, and toolchain choice) doesn't exist yet either.

To bootstrap:
1. Run `/bootstrap-ios` in Claude Code, or just start describing the feature/screen you want built — the `tecorb-ios-bootstrap` skill auto-triggers on an un-bootstrapped repo.
2. Answer the project-context questions: app name; bundle ID + Apple Developer Team ID; minimum iOS deployment target (defaults to iOS 17); backend style (REST/GraphQL/none yet); Figma design source; CI target (Xcode Cloud or GitHub Actions); project generator (XcodeGen or Tuist).
3. The skill writes `.claude/project.json`, generates `project.yml`/`Tuist/Project.swift`, xcconfigs, `Info.plist` values, and `App/<AppName>App.swift` (tagged `// GENERATED-BY-BOOTSTRAP`), and fills in the app-specific sections of `CLAUDE.md`.
4. Re-run bootstrap later with `/bootstrap-ios --force` (re-answer all questions, pre-filled with current values) or `/bootstrap-ios --field=ci.target=github-actions` (update one field without a full re-run).

## Architecture

**MVVM + Swift Concurrency + Observation.** ViewModels are `@Observable` classes (not `ObservableObject`/`@Published`), own no UIKit/networking calls directly, and take dependencies through `init` rather than reaching into globals or singletons:

```swift
@MainActor
@Observable
final class ProfileViewModel {
    private(set) var profile: Profile?
    private(set) var isLoading = false
    private(set) var error: Error?

    private let service: ProfileServicing

    init(service: ProfileServicing) {
        self.service = service
    }

    func load(userID: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            profile = try await service.fetchProfile(userID: userID)
        } catch {
            self.error = error
        }
    }
}
```

Views own or receive a ViewModel and render its state — no business logic, no direct network/persistence calls in a View's body.

**UIKit** is used only where a SwiftUI gap requires it (e.g. certain `UIActivityViewController`/`PHPickerViewController` edge cases), bridged via `UIViewRepresentable`/`UIViewControllerRepresentable` with a thin bridge that delegates state back to an `@Observable` ViewModel.

**Combine** is used only to bridge a delegate-based or Combine-only third-party API with no async alternative — convert to `async`/`AsyncSequence` at the boundary rather than threading `Publisher`s through the ViewModel layer.

**Dependencies** are managed exclusively via **Swift Package Manager**. CocoaPods/Carthage are not used unless a dependency genuinely requires it.

Standing up a new feature end-to-end:
1. `Features/<FeatureName>/Models/` — plain structs/enums for that feature's domain data (feature-local; shared types live in `Core/`).
2. `Features/<FeatureName>/ViewModels/` — one `@Observable` class per screen/major UI unit.
3. `Features/<FeatureName>/Views/` — SwiftUI views rendering ViewModel state.
4. `Tests/UnitTests/<FeatureName>/` — tests for the ViewModel, mocking dependencies at the `init` boundary.

## Concurrency model

Swift 6 strict concurrency. The house pattern is race-free by construction when followed:

- Every `@Observable` ViewModel is explicitly annotated `@MainActor` (don't rely on inference).
- Services/stores are `Sendable` structs or actors, called with `await` from the ViewModel — the isolation boundary is the `async` call itself.
- Never reach for `@unchecked Sendable`/`@preconcurrency` as a first move — those are last resorts for an already-understood-safe pattern the compiler can't see through, not a way to silence a warning.

When a `Sendable`/actor-isolation compiler error appears, check in order: (1) is the crossing type just a value type that needs `Sendable` conformance — the common, harmless case; (2) is it a reference type with real shared mutable state — needs an `actor` or confined mutation; (3) is a closure capturing `self` across an isolation boundary — capture only the `Sendable` values it needs.

## Networking layer

Protocol + live + mock, so ViewModels depend on an abstraction, not a concrete `URLSession`/`APIClient`:

```swift
// Core/Networking/ProfileService.swift
protocol ProfileServicing: Sendable {
    func fetchProfile(userID: String) async throws -> Profile
}

struct ProfileService: ProfileServicing {
    let client: APIClient
    func fetchProfile(userID: String) async throws -> Profile {
        try await client.get("/users/\(userID)", as: Profile.self)
    }
}

struct MockProfileService: ProfileServicing {
    var result: Result<Profile, Error> = .success(.preview)
    func fetchProfile(userID: String) async throws -> Profile { try result.get() }
}
```

Typed errors, not raw `URLError`/`DecodingError`, cross the `APIClient` boundary:

```swift
enum APIError: Error, Equatable {
    case badResponse(statusCode: Int)
    case decoding(underlying: String)
    case unauthorized
    case offline
}
```

Only idempotent (GET) requests auto-retry, with simple exponential backoff at the `APIClient` level — no third-party retry library. `async`/`await` is used throughout; Combine and completion handlers are not used for new networking code. If `.claude/project.json`'s `backend.style` is `graphql`, the project's chosen GraphQL client's own conventions apply instead of this REST shape. The base URL is injected via `.xcconfig` build settings, never hardcoded in source; API keys/tokens are never committed.

## Persistence layer

**SwiftData**, not Core Data, for all local persistence:

```
Core/Persistence/
  Models/          @Model schema types — one type per file
  Migrations/       VersionedSchema + SchemaMigrationPlan definitions
  PersistenceController.swift   owns the ModelContainer
```

ViewModels depend on a store protocol, mirroring the networking pattern, not directly on `ModelContext`:

```swift
protocol FavoritesStoring: Sendable {
    func add(_ item: FavoriteItem) throws
    func fetchAll() throws -> [FavoriteItem]
}

@ModelActor
actor FavoritesStore: FavoritesStoring {
    func add(_ item: FavoriteItem) throws {
        modelContext.insert(item)
        try modelContext.save()
    }
    func fetchAll() throws -> [FavoriteItem] {
        try modelContext.fetch(FetchDescriptor<FavoriteItem>())
    }
}
```

`@Query` directly in a View is acceptable for simple, read-only, screen-scoped lists with no filtering/sorting/write logic — anything more goes through a store type. Every schema change ships a new `VersionedSchema` case and an explicit migration stage; an existing shipped `VersionedSchema` is never mutated in place. Unit tests against store types use an in-memory `ModelContainer` (`isStoredInMemoryOnly: true`), never the real on-disk container.

## Design system

Spacing, color, and typography are token-driven — no magic numbers or literal colors in Feature views:

```swift
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

extension Color {
    static let brandPrimary = Color("BrandPrimary")   // from Assets.xcassets
}
```

A component belongs in `Core/DesignSystem/` once it's used (or clearly reusable) across 2+ Features or is a visual primitive; otherwise it stays in `Features/<Feature>/Views/` until that reuse actually happens. Every `View` — DesignSystem or Feature — ships a `#Preview` with at least 2 states (for a ViewModel-backed screen, usually loading/empty/error per the populated-state preview; for a primitive, usually a content/size/dark-mode variant). Components support Dynamic Type and light/dark mode via color assets, not fixed sizes or hardcoded RGB.

## Folder structure

```
App/                 SwiftUI @main entry point (generated at bootstrap)
Features/<Feature>/  Views/, ViewModels/, Models/ — one subfolder per feature
Core/
  Networking/        Shared networking layer (REST or GraphQL, per bootstrap answer)
  Persistence/        Shared local persistence (SwiftData)
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

## Build system

Generator choice (XcodeGen or Tuist) is recorded in `.claude/project.json`'s `toolchain.projectGenerator` at bootstrap.

```bash
xcodegen generate   # or: tuist generate
xcodebuild -list    # confirm the scheme — never guess it
xcodebuild build -scheme <scheme> -destination 'platform=iOS Simulator,name=<simulator>'
xcodebuild test -scheme <scheme> -destination '...'
xcodebuild test -scheme <scheme> -destination '...' -only-testing:<Target>/<Class>/<method>   # one test
swift build && swift test   # pure-SPM packages, no simulator needed
```

## Testing strategy

**Unit tests** (`Tests/UnitTests/`) use **Swift Testing** (`@Test`/`#expect`), not XCTest, following Arrange-Act-Assert with descriptive names (`loadPopulatesProfileOnSuccess`, `loadSetsErrorOnNetworkFailure`). There's no enforced coverage percentage, but a non-negotiable rule: every new `@Observable` ViewModel or new service/store type ships with tests covering the success path, a typed-error failure path, and any loading-flag transition. `@Test(arguments:)` is used for parameterized variant coverage instead of copy-pasted near-identical tests.

**Snapshot tests** (`Tests/SnapshotTests/`) cover SwiftUI views under `Features/<Feature>/Views` and `Core/DesignSystem`.

**UI tests** (`UITests/`) are XCUITest end-to-end flows using accessibility-identifier-based selectors — never index-based — following a page-object pattern per screen.

## CI/CD pipeline

CI target (Xcode Cloud or GitHub Actions) is set at bootstrap and recorded in `.claude/project.json`'s `ci.target`. Stage sequence, regardless of runner:

1. **Lint** — `swiftlint lint` + `swiftformat --lint` against the whole repo (excluding `Tests/`/`UITests/`'s force-unwrap exception). Fails fast before spending build minutes.
2. **Build** — `xcodebuild build` (or `swift build`). Catches compile errors and Swift 6 strict-concurrency violations.
3. **Unit test** — `xcodebuild test -only-testing:UnitTests` (or `swift test`).
4. **UI test** — `xcodebuild test -only-testing:UITests` on a real simulator boot; slower, sometimes gated to `main`/release branches only.
5. **Archive** — `xcodebuild archive`, only on branches that trigger a release path.
6. **Upload** — `fastlane beta` or an equivalent App Store Connect API upload, only after a successful archive.

Archive/upload never run on every PR — only on the branch/tag that should trigger a TestFlight build.

## Release process

Three Fastlane lanes under `Scripts/fastlane/Fastfile` — no fourth lane without a clear gap the three don't cover:

- **`fastlane test`** — runs the same suite CI runs, as a local pre-push sanity check.
- **`fastlane beta`** — bumps build number, builds, uploads to TestFlight. This is what CI's archive/upload stage calls.
- **`fastlane release`** — promotes the current TestFlight build to App Store review. Kept separate from `beta` so App Store submission is always a deliberate, separate action — never confirm-and-run this without explicit sign-off.

Code signing uses **match** against a separate encrypted git repo (`MATCH_GIT_URL`) — `.p12`/`.mobileprovision` files are never committed to this repo. Lanes call `match(readonly: true)`; `readonly: false` (which can register devices/regenerate profiles) is a deliberate manual action, never a lane default. Secrets (`MATCH_PASSWORD`, `ASC_KEY_ID`, etc.) live in environment variables/CI secrets — never a literal in the `Fastfile`, never printed to logs.

## Security conventions

- **Keychain** — auth tokens, refresh tokens, passwords, any credential. Never `UserDefaults`, never a plain SwiftData `@Model` field, never a plain file.
- **UserDefaults** — non-sensitive preferences only (theme, feature flags, last-viewed tab).
- Every Keychain write sets an explicit `kSecAttrAccessible` value matched to the data's sensitivity (typically a `*ThisDeviceOnly` variant) — relying on the SDK default is itself a flag.
- ATS (App Transport Security) stays enabled with no blanket exceptions; certificate/public-key pinning is added where the app handles sensitive data.
- The `security-auditor` agent runs these checks (plus a Semgrep static-analysis pass where registered) automatically on changes under `Core/Networking`, `Core/Persistence`, or any auth/token/session/biometric code — see [Claude Code integration](#claude-code-integration).

## Code style and static analysis

Enforced by `.swiftlint.yml` and `.swiftformat` at the repo root — these files are the source of truth:

- Line length: warning at 120, error at 140 (`.swiftlint.yml`) / hard wrap at 120 (`.swiftformat`).
- `force_unwrapping`, `force_cast`, `force_try` are lint **errors** everywhere except `Tests/`/`UITests/`, where they're permitted.
- Explicit `self` is *removed* by SwiftFormat (`--self remove`) rather than enforced by SwiftLint — a custom rule (`explicit_self_disallowed`) flags stray `self.` that formatting should have stripped.
- Imports are alphabetically sorted and deduplicated (`sorted_imports`, `unused_import`, `--importgrouping alpha`, `--enable duplicateImports`).
- Swift version target: 5.10. Indentation: 4 spaces, LF line endings, trailing commas enabled, argument wrapping enabled.

Run locally:

```bash
swiftlint lint
swiftformat .
```

## Claude Code integration

This repo ships a full `.claude/` extension set — skills, commands, agents, and hooks tailored to Tecorb's iOS conventions:

| Type | Examples |
|---|---|
| Skills | `tecorb-ios-architecture`, `networking-layer`, `persistence-layer`, `concurrency-safety`, `ios-testing`, `swiftui-components`, `ci-pipeline`, `fastlane-conventions`, `mobile-secure-storage`, and more — each scoped to one convention area |
| Command | `/bootstrap-ios` — explicit, idempotent bootstrap re-run |
| Agents | `ios-swiftui-engineer` (builds features), `swift-code-reviewer` (read-only review), `ios-build-test-runner` / `qa-runner` / `test-engineer` (build and test), `security-auditor`, `accessibility-auditor`, `release-manager`, `docs-maintainer` |
| Hooks | 10 hooks across `PreToolUse`/`PostToolUse`/`Stop`/`SessionStart`/`Notification` — auto-format/lint on save, a blocking guard against leaked signing secrets or force-pushes to `main`, a lint gate at task completion, targeted test-run suggestions, an automatic security-review nudge on sensitive files, and more |

See [`CLAUDE.md`](CLAUDE.md) for the complete extension table and quality-gate policy, and [`.claude/hooks/README.md`](.claude/hooks/README.md) for what each hook does and why — since hook definitions live in JSON (`.claude/settings.json`), which can't hold comments, that README is the source of truth for hook rationale.
