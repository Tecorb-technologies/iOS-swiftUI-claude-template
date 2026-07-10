---
name: swiftui-components
description: Design-system component conventions for Tecorb iOS apps — the spacing scale, color/typography tokens, when a component belongs in Core/DesignSystem vs a one-off Feature view, and the previews-required rule (every View ships a #Preview with at least 2 states). Use whenever building a new reusable SwiftUI component, extracting a repeated view pattern into Core/DesignSystem, or reviewing whether a View is styled with tokens vs hardcoded values. Complements tecorb-ios-architecture (structure/data flow) — this skill is about visual/component conventions specifically.
---

# Tecorb SwiftUI Component Conventions

For SwiftUI API mechanics (view builders, layout protocols, modifiers), use `apple-skills:swiftui` and `apple-skills:guide-swiftui-ui-patterns`. This skill is about *this org's* design-system conventions on top of those APIs. For visual/aesthetic direction on a new screen, pair this with `frontend-design`.

## Token scale — do

```swift
// Core/DesignSystem/Spacing.swift
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

// Core/DesignSystem/ColorTokens.swift
extension Color {
    static let brandPrimary = Color("BrandPrimary")     // from Assets.xcassets, not a literal
    static let surfaceElevated = Color("SurfaceElevated")
}

// Core/DesignSystem/Typography.swift
extension Font {
    static let headline = Font.system(.headline, design: .rounded).weight(.semibold)
    static let bodyDefault = Font.system(.body)
}
```

```swift
VStack(spacing: Spacing.md) {
    Text("Title").font(.headline)
}
.padding(Spacing.lg)
```

## Token scale — don't

```swift
// Don't: hardcoded magic numbers and literal colors bypass the token scale
VStack(spacing: 17) {
    Text("Title").font(.system(size: 15))
}
.padding(.horizontal, 22)
.foregroundStyle(Color(red: 0.2, green: 0.4, blue: 0.9))
```

If a new screen needs a spacing/color/type value that doesn't fit the existing scale, that's a signal to extend the token file — flag it and add the token, don't invent an inline one-off value.

## Where a component belongs

- **`Core/DesignSystem/`** — used (or clearly reusable) across 2+ Features, or is a primitive (button style, card, badge, loading indicator). No Feature-specific business logic or model types.
- **`Features/<Feature>/Views/`** — composes DesignSystem primitives for one screen's specific layout. If you find yourself copy-pasting a Feature view's body into another Feature, that's the signal to promote it into `Core/DesignSystem/`, not before.

## Building a new Core/DesignSystem component

1. Name it by what it *is*, not where it's used (`PrimaryButtonStyle`, `StatusBadge`, not `HomeScreenButton`).
2. Accept content/configuration via parameters or a `ButtonStyle`/`ViewModifier` conformance — don't hardcode strings, colors, or spacing that should come from a call site or a token.
3. Support both light and dark mode via `Color` assets (not hardcoded RGB) — verify with the Xcode preview's appearance toggle.
4. Support Dynamic Type — use `Font.system(_:)` text styles or `.dynamicTypeSize` ranges, not fixed point sizes, unless a fixed size is a deliberate design decision (rare — flag it if so).

## Previews-required rule

Every `View` — DesignSystem component or Feature view — ships a `#Preview` with **at least 2 states**. What counts as a second state depends on the view:

```swift
#Preview("Populated") {
    StatusBadge(status: .active)
}

#Preview("Long text") {
    StatusBadge(status: .pendingReviewFromAnotherTeam)
}
```

For a Feature view backed by a ViewModel, the second state is usually loading/empty/error — see `ui-states-checklist` for the full state matrix that Feature screens need. For a DesignSystem primitive, the second state is usually a content/size/dark-mode variant. A component with only one `#Preview` state is incomplete — don't ship it that way.

## Reviewing existing views for token compliance

When asked to review or refactor a View for design-system compliance, grep for suspicious literals rather than reading every line by eye:

```bash
grep -rn '\.padding([0-9]' Features/ Core/DesignSystem/
grep -rn 'Color(red:' Features/ Core/DesignSystem/
grep -rn 'font(.system(size:' Features/ Core/DesignSystem/
```

Each hit is either a legitimate one-off (rare, should be commented as such) or a missing token — flag it, don't silently "fix" it into a guessed token without confirming the value matches an existing scale step.
