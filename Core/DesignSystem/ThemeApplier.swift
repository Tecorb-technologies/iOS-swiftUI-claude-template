import SwiftUI
import UIKit

extension AppThemeMode {
    /// UIKit style. `.system` → `.unspecified`, which follows the device appearance.
    var uiUserInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: .unspecified
        case .light: .light
        case .dark: .dark
        }
    }
}

/// Applies the selected appearance by setting each window's `overrideUserInterfaceStyle`.
///
/// This is used instead of SwiftUI's `.preferredColorScheme`, because toggling that back to `nil`
/// (for "System") does not reliably revert a previously-pinned Light/Dark override. Setting the
/// window override to `.unspecified` genuinely returns control to the device, and because it's set
/// at the window level it also covers presented sheets.
enum ThemeApplier {
    @MainActor
    static func apply(_ mode: AppThemeMode) {
        let style = mode.uiUserInterfaceStyle
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = style
            }
        }
    }
}
