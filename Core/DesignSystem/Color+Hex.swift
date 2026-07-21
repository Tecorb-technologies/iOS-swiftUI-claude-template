import SwiftUI
import UIKit

extension Color {
    /// Creates a color from a hex string (`#RRGGBB`, `RRGGBB`, or `#RRGGBBAA`).
    /// Malformed input resolves to `.clear` rather than trapping.
    init(hex: String) {
        self = Color(uiColor: UIColor(hex: hex))
    }

    /// A color that resolves to `light` in light appearance and `dark` in dark appearance,
    /// following the device/trait theme automatically. This is the primitive every semantic
    /// token in `AppColor` is built from.
    static func adaptive(light: String, dark: String) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

extension UIColor {
    convenience init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# ")).uppercased()
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)

        let red: Double
        let green: Double
        let blue: Double
        let alpha: Double

        switch sanitized.count {
        case 6:
            red = Double((value & 0xFF0000) >> 16) / 255
            green = Double((value & 0x00FF00) >> 8) / 255
            blue = Double(value & 0x0000_00FF) / 255
            alpha = 1
        case 8:
            red = Double((value & 0xFF00_0000) >> 24) / 255
            green = Double((value & 0x00FF_0000) >> 16) / 255
            blue = Double((value & 0x0000_FF00) >> 8) / 255
            alpha = Double(value & 0x0000_00FF) / 255
        default:
            red = 0
            green = 0
            blue = 0
            alpha = 0
        }

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
