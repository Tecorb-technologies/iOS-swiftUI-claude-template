---
name: design-to-code
description: Given a Figma frame/link or screenshot, extracts spacing, color, and typography values and maps them onto this project's existing Core/DesignSystem tokens — flagging any value that doesn't match the token scale instead of inventing a new one. Use whenever implementing a screen from a Figma design or screenshot, or when a design handoff mentions specific pixel/hex/point values that need reconciling against the app's tokens.
---

# Design-to-Code Token Mapping

This skill governs *token reconciliation* specifically. For the broader design→code implementation workflow (reading a Figma node, reusing Code Connect mappings, adapting the reference output to this project's components), use `figma:figma-design-to-code` and `figma:figma-swiftui` — load those first if starting from an actual Figma URL. This skill is what you do once you have concrete spacing/color/type values in hand, Figma-sourced or from a screenshot estimate.

## The rule: map, don't invent

Every spacing, color, and font value extracted from a design must resolve to an existing token in `Core/DesignSystem/{Spacing,ColorTokens,Typography}.swift` (see `swiftui-components` for the token scale itself). A value that doesn't cleanly match an existing token is a **flag**, not a silent new one-off:

```swift
// Design shows 18pt padding. Nearest existing tokens: Spacing.sm (8), Spacing.md (16).
// Don't silently pick one — flag: "Design spec is 18pt, doesn't match Spacing.md (16) or
// lg (24). Use Spacing.md and treat 2pt as design tolerance, or extend the scale?"
```

## Extraction workflow

1. **Spacing** — read padding/gap values between elements in the design; round to the nearest existing `Spacing` token only if within a small, explicitly-stated tolerance (e.g. ≤2pt); otherwise flag the mismatch rather than guessing.
2. **Color** — read hex/RGB values; match against `Assets.xcassets` color sets backing `ColorTokens` (see `swiftui-components`), not by eye — compare the actual hex values. An exact or near-exact match uses the existing token; anything else is flagged as a potential new token or a design inconsistency to confirm with the designer.
3. **Typography** — read font family/weight/size/line-height; match against `Typography` tokens. A design using a font size between two existing type-scale steps is a flag, not an automatic new `Font` extension.

## Screenshot-only input

Without live Figma data (no Code Connect metadata, no exact values), extracted values are estimates — say so explicitly in your output rather than presenting guessed pixel values as if they were exact. Prefer mapping to the nearest existing token over reproducing an estimated exact value, since the token scale is more likely to be "correct" than a pixel-measurement from a screenshot.

## Output format

When reconciling a design against tokens, report three groups:
- **Matched** — design value → existing token, used directly.
- **Rounded within tolerance** — design value → nearest token, with the delta stated.
- **Flagged** — design value with no reasonable token match; needs a human decision (extend the scale, or the design should be corrected to an existing token).

Don't proceed to writing SwiftUI code with an invented inline value for anything in the "flagged" group — surface it and wait, unless the developer has already said "extend the scale as needed" for this task.
