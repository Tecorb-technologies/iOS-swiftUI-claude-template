import SwiftUI

/// User-selectable appearance. `system` defers to the device setting (the default); `light`/`dark`
/// pin the app. Persisted via `@AppStorage("app.theme.mode")` and applied at the app root with
/// `.preferredColorScheme(mode.colorScheme)`.
enum AppThemeMode: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var iconName: String {
        switch self {
        case .system: "iphone"
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        }
    }

    /// `nil` follows the device appearance.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
