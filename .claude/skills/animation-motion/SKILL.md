---
name: animation-motion
description: SwiftUI animation conventions for Tecorb iOS apps — standard spring parameters, matchedGeometryEffect usage, and the required Reduce Motion accessibility fallback. Use whenever adding a transition, animating a state change, using matchedGeometryEffect for a shared-element transition, or reviewing animation code for accessibility.
---

# Tecorb Animation & Motion Conventions

For SwiftUI animation API mechanics (implicit/explicit animations, transitions, phase/keyframe animations, `Animatable`), use `apple-skills:guide-swiftui-animations`. This skill is the house standard on top of those APIs, plus the accessibility requirement that's easy to skip.

## Standard spring — do

```swift
extension Animation {
    static let tecorbSpring = Animation.spring(response: 0.35, dampingFraction: 0.8)
    static let tecorbQuick = Animation.spring(response: 0.2, dampingFraction: 0.85)
}

withAnimation(.tecorbSpring) {
    isExpanded.toggle()
}
```

Use `.tecorbSpring` for most state-driven UI changes (expand/collapse, card flips, sheet-adjacent transitions) and `.tecorbQuick` for small, frequent feedback animations (button press states, toggle switches). Don't hand-tune a bespoke `response`/`dampingFraction` per call site — if neither standard preset fits, that's a signal to discuss adding a third named preset, not to inline a one-off spring.

## matchedGeometryEffect — do

```swift
@Namespace private var heroNamespace

// In the source view:
Image(item.thumbnail)
    .matchedGeometryEffect(id: item.id, in: heroNamespace)

// In the destination view, same id + namespace:
Image(item.fullImage)
    .matchedGeometryEffect(id: item.id, in: heroNamespace)
```

Keep the `@Namespace` scoped to the smallest shared parent view that contains both the source and destination — a namespace declared too high up (e.g. at the App root) invites id collisions across unrelated features as the app grows.

## matchedGeometryEffect — don't

```swift
// Don't: matchedGeometryEffect with no Reduce Motion fallback — this animation can be
// disorienting for users who've enabled Reduce Motion specifically to avoid it.
Image(item.thumbnail)
    .matchedGeometryEffect(id: item.id, in: heroNamespace)
```

## Reduce Motion fallback — required

Every non-trivial custom animation (shared-element transitions, custom spring-driven layout changes, parallax/motion effects) needs a Reduce Motion fallback — a simpler crossfade or an instant state change instead of the full motion:

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

var body: some View {
    content
        .matchedGeometryEffect(id: item.id, in: heroNamespace, isSource: !reduceMotion)
        .animation(reduceMotion ? .none : .tecorbSpring, value: isExpanded)
}
```

Simple, brief implicit animations (a button's built-in press state, a standard `NavigationStack` push) don't need a manual check — the system already respects Reduce Motion for those. The fallback requirement is specifically for custom, pronounced motion this codebase adds on top.

## Reviewing animation code

Check that any `matchedGeometryEffect`, custom `.spring(...)` with non-standard parameters, or transform-based motion (scale/rotation/offset driven by gesture or state) has a corresponding `accessibilityReduceMotion` check nearby — flag its absence rather than assuming it's handled elsewhere. `swiftui-pro:swiftui-pro` also flags common animation/state bugs during general review.
