import SwiftUI

/// The recurring call-to-action control on the home cards. Renders a trailing arrow and supports
/// the four visual styles in the design: filled accent, filled "win", soft accent pill, and a
/// bare text link.
struct ActionButton: View {
    enum Style {
        case filledAccent
        case filledWin
        case soft
        case link
    }

    let title: String
    var style: Style = .soft
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text("\(title) →")
                .font(isLink ? AppFont.linkLabel : AppFont.pillButton)
                .foregroundStyle(foreground)
                .padding(.horizontal, isLink ? 0 : 14)
                .padding(.vertical, isLink ? 0 : 6)
                .background(background, in: Capsule())
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private var isLink: Bool {
        style == .link
    }

    private var foreground: Color {
        switch style {
        case .filledAccent: AppColor.onAccent
        case .filledWin: AppColor.winButtonText
        case .soft, .link: AppColor.accentSoftText
        }
    }

    private var background: Color {
        switch style {
        case .filledAccent: AppColor.accent
        case .filledWin: AppColor.winButtonBackground
        case .soft: AppColor.accentSoftBackgroundStrong
        case .link: .clear
        }
    }
}

#Preview {
    VStack(alignment: .trailing, spacing: 12) {
        ActionButton(title: "Full picture", style: .filledAccent)
        ActionButton(title: "Celebrate", style: .filledWin)
        ActionButton(title: "Start step", style: .soft)
        ActionButton(title: "Share", style: .link)
    }
    .padding()
}
