import SwiftUI

/// One half of the side-by-side "utility pair" (Refer a family / Send a reward).
struct UtilityCard: View {
    let utility: Utility

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(iconBackground)
                .frame(width: 34, height: 34)
                .overlay(
                    IconImage(assetName, width: 17, height: 17)
                        .foregroundStyle(iconTint)
                )
                .accessibilityHidden(true)

            Text(utility.title)
                .font(AppFont.cardTitle)
                .foregroundStyle(AppColor.textPrimary)

            Text(utility.subtitle)
                .font(AppFont.body)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Spacer()
                ActionButton(title: utility.actionTitle, style: .link)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .cardStyle()
    }

    private var assetName: String {
        switch utility.kind {
        case .refer: "icon-refer"
        case .reward: "icon-reward"
        }
    }

    private var iconBackground: Color {
        switch utility.kind {
        case .refer: AppColor.accentSoftBackground
        case .reward: AppColor.rewardIconBackground
        }
    }

    private var iconTint: Color {
        switch utility.kind {
        case .refer: AppColor.accent
        case .reward: AppColor.rewardIconTint
        }
    }
}

#Preview {
    HStack(alignment: .top, spacing: 12) {
        UtilityCard(utility: Utility(
            id: "refer",
            kind: .refer,
            title: "Refer a family",
            subtitle: "Invite friends — it's free for them too.",
            actionTitle: "Share"
        ))
        UtilityCard(utility: Utility(
            id: "reward",
            kind: .reward,
            title: "Send a reward",
            subtitle: "ASK points for a job well done.",
            actionTitle: "Open"
        ))
    }
    .padding()
}
