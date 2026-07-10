---
name: accessibility
description: VoiceOver labels, Dynamic Type support, minimum tap target sizes, and color-contrast checks for Tecorb iOS apps. Auto-trigger whenever new SwiftUI UI is added or an existing View is modified — not just when accessibility is explicitly requested — the same way `ios-swiftui-engineer` always applies `tecorb-ios-architecture`. Also use when explicitly asked to audit a screen for accessibility.
---

# Tecorb Accessibility Conventions

For HIG-level accessibility minimums (exact tap target sizes, contrast ratios, VoiceOver behavior spec), look up `apple-skills:hig` rather than relying on memory — this skill is the checklist for applying those minimums consistently in this codebase; `swiftui-pro:swiftui-pro` also catches several of these during general SwiftUI review.

## Apply this checklist to every new/changed View, not on request

Building or editing a `Features/<Feature>/Views/*` or `Core/DesignSystem/*` View is itself the trigger — run through the checklist below before considering the View done, the same way a new Feature always gets the `tecorb-ios-architecture` folder placement and the `swiftui-components` previews-required rule applied without being asked each time.

## VoiceOver labels — do

```swift
Button {
    toggleFavorite()
} label: {
    Image(systemName: isFavorite ? "star.fill" : "star")
}
.accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
```

```swift
// Decorative image that adds no information beyond adjacent text — hide it, don't leave
// VoiceOver announcing a redundant or meaningless label.
Image("decorative-swoosh")
    .accessibilityHidden(true)
```

## VoiceOver labels — don't

```swift
// Don't: icon-only button with no label — VoiceOver announces "button", nothing else.
Button(action: toggleFavorite) {
    Image(systemName: "star")
}

// Don't: label describing the icon rather than the action.
.accessibilityLabel("Star icon")
```

Every interactive element that isn't self-describing text needs an `.accessibilityLabel`; group a compound control (e.g. an image + caption acting as one tappable unit) with `.accessibilityElement(children: .combine)` so VoiceOver announces it once, not as fragmented children.

## Dynamic Type

- Use `Font` text styles (`.headline`, `.body`, `.caption`, per `swiftui-components`'s typography tokens) rather than fixed point sizes — text styles scale automatically with the user's Dynamic Type setting.
- Test layouts at `.accessibility3`/`.accessibility5` content size, not just the default — a `#Preview` with `.environment(\.dynamicTypeSize, .accessibility3)` catches truncation/overlap before it ships.
- Avoid `.fixedSize()` or hardcoded frame heights on text-containing views unless there's a specific, deliberate reason — these are the most common cause of Dynamic Type clipping.

## Minimum tap targets

Interactive elements need at least a 44×44pt hit area (see `apple-skills:hig` for the exact current spec). A small icon button styled at its intrinsic size needs `.frame(minWidth: 44, minHeight: 44)` or `.contentShape(Rectangle())` over a padded area — don't ship a tappable icon smaller than that just because the icon asset itself is small.

## Color contrast

- Text/icon colors come from `Core/DesignSystem` color tokens (per `swiftui-components`), which should already be contrast-checked against their expected backgrounds in both light and dark mode — if a new token is being added, verify contrast (4.5:1 for body text, 3:1 for large text) before adding it, not after a screen ships.
- Never convey state (error/success/warning) by color alone — pair it with an icon or text label, since color-blind users and VoiceOver users need a non-color signal too.

## Reviewing a screen for accessibility

Grep for likely gaps rather than relying on eyeballing:

```bash
grep -rn 'Image(systemName' Features/ | grep -v accessibilityLabel   # spot-check icon-only controls near these hits
grep -rn '\.fixedSize()' Features/
grep -rn 'frame(width: [0-9]\+, height: [0-9]\+)' Features/           # check against the 44pt minimum
```
