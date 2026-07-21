import SwiftUI

/// Semantic color tokens for CloudToFigma, extracted from the Figma design
/// (`design.figmaFileUrl` in `.claude/project.json`, Home v2 light `9:5` / dark `9:9`).
///
/// Every token resolves per the active light/dark appearance, so the app follows the device theme
/// automatically (the app never pins a `preferredColorScheme`). All raw hex lives in this one file,
/// so a design refresh is a single reviewable diff. 8-digit hex is `#RRGGBBAA`.
enum AppColor {
    // MARK: Base surfaces

    static let background = Color.adaptive(light: "#FFFFFF", dark: "#121117")
    static let surface = Color.adaptive(light: "#FFFFFF", dark: "#1B1A22")
    static let cardBorder = Color.adaptive(light: "#E2E8F0", dark: "#2A2833")
    static let cardBorderAccent = Color.adaptive(light: "#4F46E51F", dark: "#CACDFF24")
    static let separator = Color.adaptive(light: "#E2E8F0", dark: "#2A2833")
    static let tabBarTopBorder = Color.adaptive(light: "#E2E8F0", dark: "#25232F")

    /// Skeleton placeholder base + moving highlight, used while content loads.
    static let skeletonBase = Color.adaptive(light: "#ECEEF2", dark: "#22212B")
    static let skeletonHighlight = Color.adaptive(light: "#FFFFFFB3", dark: "#FFFFFF14")

    // MARK: Text

    static let textPrimary = Color.adaptive(light: "#1E293B", dark: "#F4F2F8")
    static let textSecondary = Color.adaptive(light: "#64748B", dark: "#928DA5")
    static let textTertiary = Color.adaptive(light: "#94A3B8", dark: "#736E82")
    static let textMuted = Color.adaptive(light: "#A8A29E", dark: "#5B5668")
    static let memberNote = Color.adaptive(light: "#475569", dark: "#A9A4B8")

    // MARK: Accent (indigo)

    static let accent = Color(hex: "#4F46E5")
    static let onAccent = Color(hex: "#FFFFFF")
    static let accentSoftBackground = Color.adaptive(light: "#EEF2FF", dark: "#4F46E547")
    static let accentSoftBackgroundStrong = Color.adaptive(light: "#E0E7FF", dark: "#4F46E547")
    static let accentSoftText = Color.adaptive(light: "#4F46E5", dark: "#CACDFF")

    // MARK: Win accent (lime)

    static let winCardTop = Color.adaptive(light: "#F7FEE7", dark: "#232B14")
    static let winBorder = Color.adaptive(light: "#D9F99D", dark: "#A3E63638")
    static let winTagBackground = Color.adaptive(light: "#ECFCCB", dark: "#A3E63626")
    static let winTagText = Color.adaptive(light: "#4D7C0F", dark: "#BEF264")
    static let winButtonBackground = Color.adaptive(light: "#4D7C0F", dark: "#A3E635")
    static let winButtonText = Color.adaptive(light: "#FFFFFF", dark: "#1A2E05")

    // MARK: Reward accent (amber)

    static let rewardIconBackground = Color.adaptive(light: "#FEF9C3", dark: "#FBBF2424")
    static let rewardIconTint = Color.adaptive(light: "#CA8A04", dark: "#FBBF24")

    // MARK: Resources "books" icon (multi-tone, so not a template asset)

    static let booksBack = Color.adaptive(light: "#C7D2FE", dark: "#312E81")
    static let booksMid = Color.adaptive(light: "#A5B4FC", dark: "#4338CA")
    static let booksFront = Color.adaptive(light: "#4F46E5", dark: "#6366F1")

    // MARK: Status indicators

    static let statusCalm = Color.adaptive(light: "#22C55E", dark: "#4ADE80")
    /// Watch-status amber — Figma Jake sparkline + status dot (`#F59E0B` in light and dark).
    static let statusWatch = Color(hex: "#F59E0B")

    // MARK: Misc

    static let homeIndicator = Color.adaptive(light: "#1E293B", dark: "#F4F2F8")

    // MARK: Gradients (top → bottom)

    /// Header "sky" gradient behind the top of the screen.
    static let skyGradient = [
        Color.adaptive(light: "#E0E7FF", dark: "#2E2A5E"),
        Color.adaptive(light: "#EEF2FF", dark: "#1E1B4B"),
        Color.adaptive(light: "#F8FAFC", dark: "#121117"),
    ]

    /// Radial indigo fill used behind the video card media.
    static let videoGradient = [
        Color.adaptive(light: "#CACDFF", dark: "#6D74E8"),
        Color.adaptive(light: "#7170F2", dark: "#4A44B8"),
        Color.adaptive(light: "#4F46E5", dark: "#241E63"),
    ]
}
