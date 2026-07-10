---
name: test-data-builders
description: How to add fixtures/mock data builders for Tecorb iOS apps so tests, previews, and mocks don't hand-roll model literals everywhere. Use whenever writing a test or #Preview that needs sample model data, or when the same model literal is being constructed inline in more than one test/preview.
---

# Test Data Builders

A model literal constructed inline in more than one place (a test, a `#Preview`, a mock service's default) is a maintenance liability — adding a required property means hunting down every inline construction site. Fixtures live next to the model they build, as static factory properties/methods.

## Pattern — do

```swift
// Features/Profile/Models/Profile.swift (or a +Fixtures.swift extension file if the
// project wants to keep production types free of test-only code — pick one and be consistent)
extension Profile {
    static let preview = Profile(id: "1", name: "Ada Lovelace", email: "ada@tecorb.com")

    static func mock(
        id: String = "1",
        name: String = "Ada Lovelace",
        email: String = "ada@tecorb.com"
    ) -> Profile {
        Profile(id: id, name: name, email: email)
    }
}
```

```swift
// Used identically in a test, a preview, and a mock service default:
#Preview { ProfileView(viewModel: .init(service: MockProfileService(result: .success(.preview)))) }

@Test
func loadPopulatesProfileOnSuccess() async {
    let viewModel = ProfileViewModel(service: MockProfileService(result: .success(.mock(name: "Grace Hopper"))))
    await viewModel.load(userID: "1")
    #expect(viewModel.profile?.name == "Grace Hopper")
}
```

## Pattern — don't

```swift
// Don't: the same literal, slightly different each time, scattered across test files —
// a new required property means finding and fixing every one of these.
let profile = Profile(id: "1", name: "Ada Lovelace", email: "ada@tecorb.com")   // in TestA
let profile2 = Profile(id: "1", name: "Ada L.", email: "ada@tecorb.com")        // in TestB, subtly different
```

## `.preview` vs `.mock(...)`

- `.preview` (a static constant, no parameters) — the single default fixture used across `#Preview`s and tests that don't care about specific field values, just "a valid instance."
- `.mock(...)` (a factory function with defaulted parameters) — for tests that need to vary a specific field while keeping everything else at a sane default, without repeating the full initializer at every call site.

## Where builders live for shared vs. Feature-specific types

- `Features/<Feature>/Models/*+Fixtures.swift` — fixtures for a Feature-local model type.
- `Core/Persistence/Models/*+Fixtures.swift` or `Core/Networking/*+Fixtures.swift` — fixtures for shared/persisted domain types (per `persistence-layer`/`networking-layer`).

Keep fixture extensions in the main target (not a separate test target) if `#Preview`s need them — Swift Testing files can only see test-target-only fixtures if the fixture is in the test target itself, so a fixture needed by both a preview and a test must live in the main target.

## When collections are needed

```swift
extension Profile {
    static let previewList: [Profile] = [.preview, .mock(id: "2", name: "Grace Hopper")]
}
```

Build list fixtures the same way — a named static property, not an inline array literal repeated per call site.
