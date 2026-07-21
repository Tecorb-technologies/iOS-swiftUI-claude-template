import SwiftUI

/// Composition root. Wires the Home screen to a `HomeService` backed by the app's `APIClient`.
///
/// `MockAPIClient` is the active client, so the screen is driven by the bundled `home_feed.json`.
/// To move onto a real backend, swap `MockAPIClient()` for `LiveAPIClient(baseURL:)` — nothing else
/// changes. The view model is created in `body` (main-actor isolated) and retained by `HomeView`'s
/// `@State`, so it survives re-renders.
struct RootView: View {
    // Owned here (a View, not the App struct) so changing it re-renders and re-applies live.
    // The window-level override (see ThemeApplier) covers the whole app, including sheets.
    @AppStorage("app.theme.mode") private var themeMode: AppThemeMode = .system

    var body: some View {
        HomeView(viewModel: HomeViewModel(service: LiveHomeService(client: MockAPIClient())))
            .onAppear { ThemeApplier.apply(themeMode) }
            .onChange(of: themeMode) { _, newValue in
                ThemeApplier.apply(newValue)
            }
    }
}

#Preview {
    RootView()
}
