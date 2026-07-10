---
name: networking-layer
description: API client conventions for Tecorb iOS apps — the async/await URLSession wrapper shape, typed error handling, retry/backoff policy, and the protocol + live + mock pattern for adding a new endpoint. Use whenever adding a new network endpoint, building or reviewing Core/Networking code, or wiring a ViewModel to a network call. Builds on the brief networking pattern already in tecorb-ios-architecture — this skill is the deeper reference for endpoint-by-endpoint conventions.
---

# Tecorb Networking Layer Conventions

See `tecorb-ios-architecture` for the top-level networking pattern (async/await over Combine/completion handlers, REST-vs-GraphQL routing via `.claude/project.json`'s `backend.style`). This skill covers endpoint-level conventions once that choice is made. Assumes REST; if `backend.style` is `graphql`, use the project's chosen GraphQL client's own conventions instead — don't force this REST shape onto it.

## Protocol + live + mock — do

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

    func fetchProfile(userID: String) async throws -> Profile {
        try result.get()
    }
}
```

A ViewModel depends on the protocol, not the concrete type — the live implementation is injected in `App`, the mock in previews/tests:

```swift
@Observable
final class ProfileViewModel {
    private let service: ProfileServicing
    init(service: ProfileServicing) { self.service = service }
}
```

## Protocol + live + mock — don't

```swift
// Don't: ViewModel talks to a concrete APIClient/URLSession directly — untestable without a live network.
final class ProfileViewModel {
    func load() async {
        let (data, _) = try await URLSession.shared.data(from: profileURL)
    }
}
```

## Typed errors

```swift
enum APIError: Error, Equatable {
    case badResponse(statusCode: Int)
    case decoding(underlying: String)
    case unauthorized
    case offline
}
```

Map transport/HTTP failures into this enum at the `APIClient` boundary — don't let raw `URLError`/`DecodingError` leak up into ViewModels. ViewModels switch on `APIError` cases to decide user-facing messaging (e.g. `.unauthorized` triggers a re-auth flow, `.offline` shows a retry banner), which they can't do cleanly against untyped `Error`.

## Retry/backoff

Only retry idempotent requests (GET) automatically; never auto-retry POST/PUT/DELETE without explicit idempotency handling. A simple exponential backoff at the `APIClient` level is enough — don't reach for a third-party retry library for this:

```swift
func get<T: Decodable>(_ path: String, as type: T.Type, retries: Int = 2) async throws -> T {
    do {
        return try await performGet(path, as: type)
    } catch let error as APIError where retries > 0 && error.isRetryable {
        try await Task.sleep(for: .seconds(Double(3 - retries)))
        return try await get(path, as: type, retries: retries - 1)
    }
}
```

`isRetryable` should cover transient network errors and 5xx responses, not 4xx client errors.

## Adding a new endpoint end-to-end

1. Add the method to the relevant service protocol (or create a new `<Feature>Servicing` protocol if this is the first endpoint for a Feature).
2. Implement it on the live `<Feature>Service`.
3. Add/extend the mock implementation with representative fixtures — see `test-data-builders` for how fixtures are structured.
4. Inject the protocol type into the consuming ViewModel's `init`.
5. Add a unit test against the mock (`ios-testing`) covering success, a typed-error case, and — if relevant — a retry path.

## Base URL and secrets

Base URL comes from an `.xcconfig`-injected build setting, not a hardcoded string in source — see `.claude/project.json`'s `backend.baseURLPlaceholder` for where this is wired per-environment. Never commit API keys/tokens to source; see `mobile-secure-storage` for where runtime secrets and auth tokens should actually live (Keychain, not `UserDefaults` or a plist).
