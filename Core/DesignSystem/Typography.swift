import SwiftUI

/// Typography tokens matching the Figma design's type ramp (Home v2).
///
/// Backed by the bundled **Plus Jakarta Sans** family (see `Resources/Fonts`, registered via
/// `UIAppFonts` in the generated `Info.plist`). Each token is built with `relativeTo:` so text
/// keeps the design's base size but still scales with the user's Dynamic Type setting.
enum AppFont {
    private enum Face {
        static let regular = "PlusJakartaSans-Regular"
        static let medium = "PlusJakartaSans-Medium"
        static let semiBold = "PlusJakartaSans-SemiBold"
        static let bold = "PlusJakartaSans-Bold"
        static let extraBold = "PlusJakartaSans-ExtraBold"
        static let italic = "PlusJakartaSans-Italic"
    }

    private static func pjs(_ face: String, _ size: CGFloat, _ style: Font.TextStyle) -> Font {
        Font.custom(face, size: size, relativeTo: style)
    }

    static let greetingTitle = pjs(Face.extraBold, 24, .title)
    static let screenTitle = pjs(Face.bold, 17, .headline)
    static let cardHeadline = pjs(Face.bold, 17, .headline)
    static let cardHeadlineStrong = pjs(Face.extraBold, 17, .headline)
    static let cardTitle = pjs(Face.bold, 15, .subheadline)
    static let badgeNumber = pjs(Face.extraBold, 15, .subheadline)
    static let avatarInitial = pjs(Face.bold, 14, .subheadline)
    static let pillButton = pjs(Face.semiBold, 14, .subheadline)
    static let memberName = pjs(Face.bold, 13.5, .subheadline)
    static let subtitle = pjs(Face.medium, 13, .subheadline)
    static let linkLabel = pjs(Face.bold, 13, .subheadline)
    static let body = pjs(Face.regular, 12.5, .footnote)
    static let tag = pjs(Face.semiBold, 12, .caption)
    static let footnoteItalic = pjs(Face.italic, 12, .caption)
    static let caption = pjs(Face.regular, 11.5, .caption)
    static let badge = pjs(Face.bold, 11.5, .caption)
    static let sectionLabel = pjs(Face.extraBold, 11, .caption2)
    static let tabLabel = pjs(Face.medium, 11, .caption2)
}
