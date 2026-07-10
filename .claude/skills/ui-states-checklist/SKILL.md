---
name: ui-states-checklist
description: Enforces building loading/empty/error/populated/offline states for every screen backed by a ViewModel — not just the happy path. Use whenever building a new Feature screen, reviewing a screen for completeness, or when a ViewModel exposes async-loaded data (isLoading/error/data properties) that the View isn't yet fully rendering for each state.
---

# UI States Checklist

A screen backed by an `@Observable` ViewModel (per `tecorb-ios-architecture`) that loads data asynchronously has, at minimum, these states — build and preview all of them before considering the screen done, not just the populated/happy-path state.

## The state matrix

| State | When | View must show |
|---|---|---|
| Loading | `viewModel.isLoading == true`, no data yet | A loading indicator, not a blank/empty-looking screen |
| Empty | Load succeeded, result set is genuinely empty | An explicit empty state (icon + message), not a blank list |
| Error | `viewModel.error != nil` | A user-facing message + retry action, not a silently blank screen |
| Populated | Load succeeded, data present | The actual content |
| Offline | Device has no network connectivity | A distinct message from a generic error — "you're offline" is actionable differently than "something went wrong" |

Not every screen needs all five (a screen with no network dependency has no offline state) — but for any screen that loads over the network, treat all five as required unless there's a stated reason one doesn't apply.

## Implementation pattern — do

```swift
struct ProfileView: View {
    @State private var viewModel: ProfileViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.error {
                ContentUnavailableView(
                    "Couldn't load profile",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error.localizedDescription)
                )
                Button("Retry") { Task { await viewModel.load() } }
            } else if viewModel.profile == nil {
                ContentUnavailableView("No profile yet", systemImage: "person.crop.circle")
            } else {
                ProfileContent(profile: viewModel.profile!)
            }
        }
        .task { await viewModel.load() }
    }
}
```

## Implementation pattern — don't

```swift
// Don't: only the populated path is handled — loading and error states fall through
// to a blank screen.
struct ProfileView: View {
    var body: some View {
        if let profile = viewModel.profile {
            ProfileContent(profile: profile)
        }
        // nothing rendered while loading, on error, or when data is nil after a failed load
    }
}
```

## Previews for every state

Per `swiftui-components`'s previews-required rule, a screen View's `#Preview`s should cover this state matrix using the mock service/store from `networking-layer`/`persistence-layer`, not just a populated mock:

```swift
#Preview("Loading") {
    ProfileView(viewModel: .init(service: MockProfileService(delay: .seconds(999))))
}
#Preview("Error") {
    ProfileView(viewModel: .init(service: MockProfileService(result: .failure(APIError.offline))))
}
#Preview("Empty") {
    ProfileView(viewModel: .init(service: MockProfileService(result: .success(nil))))
}
```

## Reviewing a screen against this checklist

When reviewing a Feature screen, check the ViewModel's exposed state properties (`isLoading`, `error`, the data property) against what the View's body actually branches on. A ViewModel that exposes `error` but a View that never reads it is the most common gap — that's a silent failure from the user's perspective, not a passing test.
