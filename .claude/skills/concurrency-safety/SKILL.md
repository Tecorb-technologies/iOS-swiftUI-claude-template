---
name: concurrency-safety
description: Swift 6 strict concurrency checklist for Tecorb iOS apps — Sendable conformance rules, actor isolation placement, and fixes for the common data-race warnings this codebase's MVVM+Observation pattern produces. Use whenever writing new async code, seeing a "Sendable"/"actor-isolated"/"data race" compiler warning or error, or reviewing a ViewModel/service for concurrency correctness.
---

# Tecorb Concurrency Safety Checklist

For general Swift Concurrency API mechanics (actors, `Task`, structured concurrency, `AsyncSequence`), use `apple-skills:swift-concurrency` and `apple-skills:guide-swift-concurrency`. This skill is a checklist for the specific patterns that recur in this template's MVVM+Observation architecture under Swift 6 strict concurrency.

## The house pattern is already mostly race-free by construction

- `@Observable` ViewModels are implicitly `@MainActor` when they're only ever constructed/used from a View — annotate the class `@MainActor` explicitly rather than relying on inference, so the compiler enforces it everywhere.
- Services/stores (`APIClient`, SwiftData stores per `persistence-layer`) are `Sendable` structs or actors, called with `await` from the `@MainActor` ViewModel — the isolation boundary is the `async` call itself.

```swift
@MainActor
@Observable
final class ProfileViewModel {
    private(set) var profile: Profile?
    private let service: ProfileServicing   // Sendable protocol

    func load(userID: String) async {
        profile = try? await service.fetchProfile(userID: userID)   // crosses into non-isolated code, back to @MainActor on return
    }
}
```

## Checklist when a Sendable/actor-isolation error appears

1. **Is the type crossing an isolation boundary actually shared mutable state?** If it's a `struct` of value types (or a `let`-only class), mark it `Sendable` and move on — most "make it Sendable" fixes are this, not a real race.
2. **Is it a reference type with mutable state accessed from multiple isolation contexts?** That's a real race. Fix by either: making it an `actor`, confining all mutation to one `@MainActor`/actor, or making the mutable property `private` and only exposing `Sendable` snapshots.
3. **Is the error about a closure capturing `self` across an isolation boundary** (e.g. inside a `Task { }` or a delegate callback)? Capture only the `Sendable` values the closure needs, not `self`, unless `self` is genuinely `Sendable` or the closure is already isolated to the same actor.
4. **Never silence the error with `@unchecked Sendable` or `@preconcurrency` as a first move.** Those are last resorts for a specific, understood, already-safe pattern the compiler can't see through (e.g. wrapping a legacy Objective-C API) — not a way to make a warning go away. If you reach for one, say so explicitly and explain why the underlying access really is safe.

## Common data-race sources in this codebase's shape

- **A `Task { }` inside a View's `.onAppear`/`.task` capturing a ViewModel method that isn't `@MainActor`** — annotate the ViewModel `@MainActor` (see above) instead of wrapping every call site defensively.
- **A completion-handler-based delegate (Combine-bridged per `tecorb-ios-architecture`'s "When Combine is legitimate") calling back on an arbitrary queue** — hop to `@MainActor` explicitly at the point the ViewModel receives the callback, don't assume the delegate call already lands on the main thread.
- **A `static var` used as ad-hoc shared state** (caches, singletons) — these need to be `Sendable` and thread-safe (an `actor`, or a `let`-only immutable value) under strict concurrency; a mutable `static var class` property is almost always a latent race.

## Reviewing for concurrency correctness

When reviewing a diff, check: every `@Observable` ViewModel class has an explicit `@MainActor` (or a stated reason it doesn't), every service/store type crossing into ViewModel code is `Sendable`, and no `@unchecked Sendable`/`@preconcurrency` appears without an inline comment explaining why the access is actually safe. `swift-code-reviewer` runs this checklist automatically on nontrivial changes.
