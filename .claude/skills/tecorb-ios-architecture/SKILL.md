---
name: tecorb-ios-architecture
description: The definitive architecture and conventions reference for Tecorb iOS SwiftUI client projects — MVVM + Swift Concurrency + @Observable, SPM-only, the Features/<Feature>/{Views,ViewModels,Models} + Core/{Networking,Persistence,DesignSystem,Utilities,Extensions} folder convention, naming rules, and the SwiftLint/SwiftFormat ruleset rationale. Use whenever building, reviewing, or reasoning about structure in any Tecorb iOS app from this template — invoked by ios-swiftui-engineer and swift-code-reviewer on every nontrivial task.
---

# Tecorb iOS Architecture Conventions

This is the house style for every iOS app built from this template. For API-level reference (SwiftUI view types, concurrency primitives, etc.), use the built-in `apple-skills:swiftui`, `apple-skills:guide-swift-concurrency`, and `apple-skills:guide-swiftui-ui-patterns` skills instead of duplicating them here — this skill is about *this org's* conventions on top of those APIs.

## ViewModel pattern — do

```swift
@Observable
final class ProfileViewModel {
    private(set) var profile: Profile?
    private(set) var isLoading = false
    private(set) var error: Error?

    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func load(userID: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            profile = try await client.fetchProfile(userID: userID)
        } catch {
            self.error = error
        }
    }
}
```

## ViewModel pattern — don't

```swift
// Don't: ObservableObject + @Published is the pre-Observation pattern. Use @Observable instead.
final class ProfileViewModel: ObservableObject {
    @Published var profile: Profile?
}

// Don't: business/network logic living in the View.
struct ProfileView: View {
    var body: some View {
        Text("...")
            .task { self.profile = try? await URLSession.shared.data(from: url) } // belongs in a ViewModel
    }
}
```

## Networking pattern (REST) — do

```swift
struct APIClient {
    private let baseURL: URL
    private let session: URLSession

    func fetchProfile(userID: String) async throws -> Profile {
        let (data, response) = try await session.data(from: baseURL.appending(path: "/users/\(userID)"))
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.badResponse
        }
        return try JSONDecoder().decode(Profile.self, from: data)
    }
}
```

Prefer `async`/`await` over completion handlers and over Combine publishers for new networking code. If `backend.style` in `.claude/project.json` is `graphql`, use the project's chosen GraphQL client instead of hand-rolling REST calls.

## When UIKit is legitimate

- A UIKit-only API with no SwiftUI equivalent (e.g. certain `UIActivityViewController` flows, some `PHPickerViewController` edge cases).
- Bridge it with `UIViewControllerRepresentable`/`UIViewRepresentable`, keep the bridge itself thin, and put any logic back into an `@Observable` ViewModel the bridge talks to — don't let a UIKit view controller own app state.

## When Combine is legitimate

- Bridging a delegate-based or Combine-only third-party API with no async alternative. Convert to an `AsyncSequence`/`async` call at the boundary as soon as possible rather than threading Combine publishers through the ViewModel layer.

## Standing up a new Feature end-to-end

1. `Features/<FeatureName>/Models/` — plain structs/enums for this feature's domain data (not shared across features — shared types go in `Core/`).
2. `Features/<FeatureName>/ViewModels/` — one `@Observable` class per screen or major UI unit, taking its dependencies (e.g. `APIClient`) via `init`, not by reaching into globals/singletons.
3. `Features/<FeatureName>/Views/` — SwiftUI views that own a ViewModel instance (or receive one) and render its state; no business logic.
4. `Tests/UnitTests/<FeatureName>/` — tests for the ViewModel, mocking dependencies at the `init` boundary.

## Naming and style

Naming, force-unwrap policy, import sorting, and explicit-self policy are enforced by `.swiftlint.yml`/`.swiftformat` at the repo root — those files are the source of truth; this skill explains the *why*, not a restated rulebook.

## Lightweight dependency injection

Favor plain `init`-based dependency passing over a DI framework. A single small `Core/Utilities/Dependencies.swift`-style container is acceptable once a feature genuinely needs 3+ shared dependencies threaded through multiple ViewModels — don't introduce a DI framework speculatively before that need is real.
