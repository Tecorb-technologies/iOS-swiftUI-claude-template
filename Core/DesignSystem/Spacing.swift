import CoreGraphics

/// 4-pt based spacing scale. Prefer these tokens over magic numbers in layout code so spacing
/// stays consistent across screens. Reconcile the scale against Figma at design time.
enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

/// Corner-radius scale for cards, buttons, and pills.
enum CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let pill: CGFloat = 999
}
