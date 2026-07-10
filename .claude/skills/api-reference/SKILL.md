---
name: api-reference
description: Generates reference documentation for a backend or public SDK surface this app exposes, sourced from doc comments, and flags undocumented public symbols. Use if/when this app ships a backend API contract or a public SDK/framework surface of its own (not Apple's APIs — this is for documenting this project's own public code) and that surface changes, or when asked to audit doc-comment coverage on public symbols.
---

# API Reference Generation

This skill only applies once this project actually has a public surface of its own to document — a backend API contract it defines, or a Swift Package/framework it exposes to other consumers. Most Tecorb client apps built from this template never reach that point (the app is the product, not an SDK) — check `.claude/project.json`'s `backend.style` and whether any `Package.swift` in this repo declares a `library` product before assuming this skill applies. If neither exists, say so rather than generating reference docs for internal-only app code.

## Doc comment convention

Swift doc comments (`///`) on every symbol that's part of the public surface (`public`/`open` access level):

```swift
/// Fetches the current user's profile.
///
/// - Parameter userID: The unique identifier of the user to fetch.
/// - Returns: The decoded `Profile` for the given user.
/// - Throws: `APIError.badResponse` if the server returns a non-2xx status,
///   `APIError.decoding` if the response body doesn't match the expected shape.
public func fetchProfile(userID: String) async throws -> Profile
```

## Generating reference docs

Prefer Apple's DocC over a hand-rolled markdown generator — it reads `///` doc comments directly and produces browsable reference docs with cross-linking, which a markdown scraper would have to reimplement badly:

```bash
swift package generate-documentation --target <TargetName>
# or, for an Xcode-built framework target:
xcodebuild docbuild -scheme <scheme> -destination 'generic/platform=iOS'
```

## Flagging undocumented public symbols

```bash
# Find public declarations, then check each has a preceding /// doc comment —
# a public symbol with no doc comment immediately above it is a gap.
grep -rn '^public \|^    public ' Sources/ Core/ 2>/dev/null
```

Report gaps as a list of `file:line` plus the symbol signature — don't auto-generate a placeholder doc comment for a gap, since a fabricated description is worse than an honestly-flagged missing one. Ask the developer (or infer conservatively from the implementation, clearly caveated as inferred) rather than inventing behavior.

## Scope

This is about *this project's own* public API surface. For Apple framework API lookups (what SwiftUI/HealthKit/StoreKit APIs exist and how they work), use the relevant `apple-skills:*` reference skill instead — this skill has nothing to add there.
