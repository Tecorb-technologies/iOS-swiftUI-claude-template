import SwiftUI

/// Standard card chrome from the design: surface fill, 20-pt continuous corners, 1-pt border,
/// and a soft ambient shadow. Border color is configurable for accent/win-tinted cards.
struct CardStyle: ViewModifier {
    var borderColor: Color = AppColor.cardBorder

    func body(content: Content) -> some View {
        content
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
    }
}

extension View {
    func cardStyle(border: Color = AppColor.cardBorder) -> some View {
        modifier(CardStyle(borderColor: border))
    }
}
