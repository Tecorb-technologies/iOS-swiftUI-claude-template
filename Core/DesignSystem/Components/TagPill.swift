import SwiftUI

/// Small rounded "chip" used for card category labels (e.g. "Family status", "Family win").
struct TagPill: View {
    let title: String
    var background: Color = AppColor.accentSoftBackground
    var foreground: Color = AppColor.accentSoftText

    var body: some View {
        Text(title)
            .font(AppFont.tag)
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(background, in: Capsule())
    }
}

#Preview {
    HStack {
        TagPill(title: "Family status")
        TagPill(
            title: "Family win",
            background: AppColor.winTagBackground,
            foreground: AppColor.winTagText
        )
    }
    .padding()
}
