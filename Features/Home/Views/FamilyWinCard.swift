import SwiftUI

/// "Family win" card — a celebratory, lime-tinted card with a gradient background.
struct FamilyWinCard: View {
    let win: FamilyWin

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                TagPill(
                    title: win.tag,
                    background: AppColor.winTagBackground,
                    foreground: AppColor.winTagText
                )
                Spacer()
                IconImage("icon-win-sparkle", width: 16, height: 16)
                    .foregroundStyle(AppColor.winTagText)
                    .accessibilityHidden(true)
            }

            Text(win.headline)
                .font(AppFont.cardHeadlineStrong)
                .foregroundStyle(AppColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(win.subtitle)
                .font(AppFont.body)
                .foregroundStyle(AppColor.textSecondary)

            HStack {
                Spacer()
                ActionButton(title: win.actionTitle, style: .filledWin)
            }
        }
        .padding(16)
        // Shadow cast from the shape (stable shadow path), not the card's composited alpha, so it
        // doesn't re-rasterize on sub-pixel movement during slow scrolling. See CardStyle.
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppColor.winCardTop, AppColor.surface],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(AppColor.winBorder, lineWidth: 1)
        )
    }
}

#Preview {
    FamilyWinCard(win: FamilyWin(
        tag: "Family win",
        headline: "Emma read more than she gamed this week.",
        subtitle: "That's two weeks in a row.",
        actionTitle: "Celebrate"
    ))
    .padding()
}
