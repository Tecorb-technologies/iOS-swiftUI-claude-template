---
name: localization
description: How to add and update user-facing strings via String Catalogs for Tecorb iOS apps — pluralization rules, RTL layout considerations, and the no-hardcoded-strings-in-Views rule. Use whenever adding new user-facing text to a View, adding a string that needs a plural/count-dependent form, or reviewing a screen for localization/RTL readiness.
---

# Tecorb Localization Conventions

String Catalogs (`Resources/Localizable.xcstrings`) are the only localization mechanism — no `.strings`/`.stringsdict` files, no third-party localization SDK, unless a specific unmet need arises (translation management integration, etc.) — flag and confirm before introducing one.

## Adding a string — do

```swift
Text("welcome.title")
// or, with String Catalog's automatic extraction from literal Text/String(localized:):
Text("Welcome back!")
Label(String(localized: "settings.signOut", comment: "Sign out button in Settings"), systemImage: "arrow.right.square")
```

Xcode auto-extracts string literals passed to `Text`, `String(localized:)`, and similar APIs into `Localizable.xcstrings` on build — write the English string as the literal, then translate it in the catalog. Add a `comment:` argument whenever the string alone is ambiguous out of context (a bare "Open" button vs. "Open" meaning "the door is open").

## Adding a string — don't

```swift
// Don't: string built by concatenation — untranslatable, and breaks in languages
// with different word order.
Text("You have " + String(count) + " new messages")

// Don't: user-facing text buried in a ViewModel/service as a raw literal returned to the View.
func statusMessage() -> String { "Order shipped" }   // won't get extracted or translated
```

Compose interpolated/pluralized strings as a single localized format string (see below), not by concatenating translated fragments — grammar and word order vary by language.

## Pluralization

Use a String Catalog plural variation, not manual `count == 1 ? ... : ...` branching:

```swift
Text("messages.count \(count)")
// In Localizable.xcstrings, "messages.count" is configured with a plural
// variation keyed on the %lld/%d argument: one -> "1 new message",
// other -> "%lld new messages".
```

Manual singular/plural branching in Swift doesn't scale to languages with more than two plural forms (e.g. Arabic, Polish) — the String Catalog plural mechanism does.

## RTL considerations

- Use layout-direction-aware modifiers/APIs (`.leading`/`.trailing` alignment, `HStack`, `Image(systemName:)` SF Symbols that already mirror) instead of `.left`/`.right` — SwiftUI's leading/trailing already flips correctly under RTL locales; hardcoded left/right doesn't.
- Icons that convey directionality (arrows, chevrons pointing "forward") should use SF Symbols' built-in mirroring (most already mirror automatically) rather than a manually rotated/flipped custom asset.
- Preview RTL behavior with `.environment(\.layoutDirection, .rightToLeft)` in a `#Preview` for any screen with directional layout, not just by eye-checking LTR.

## Reviewing a screen for localization readiness

Grep for likely offenders rather than reading every line:

```bash
grep -rn 'Text("' Features/ | grep -v 'Text(String(localized'   # spot-check for literal English left unextracted is fine; look for concatenation instead
grep -rn '+ String(' Features/
grep -rn '\.leading\|\.trailing' Features/   # sanity check these aren't paired with a stray .left/.right nearby
```

A string that's already a `Text("literal")` is fine — String Catalogs auto-extract it. The actual red flags are concatenation, manual plural branching, and hardcoded `.left`/`.right` positioning.
