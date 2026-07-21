import SwiftUI

/// The five home tabs. `aiChat` is represented by the center floating action button rather than a
/// normal icon slot.
enum AppTab: String, CaseIterable, Identifiable {
    case home
    case understand
    case aiChat
    case family
    case rewards

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .home: "Home"
        case .understand: "Understand"
        case .aiChat: "AI Chat"
        case .family: "Family"
        case .rewards: "Rewards"
        }
    }

    /// Asset-catalog icon (exported from Figma) for the tab. `aiChat` uses the FAB's sparkle.
    var assetName: String {
        switch self {
        case .home: "icon-tab-home"
        case .understand: "icon-tab-understand"
        case .aiChat: "icon-sparkle-fab"
        case .family: "icon-tab-family"
        case .rewards: "icon-tab-rewards"
        }
    }

    /// SF Symbol fallback, used for the non-designed "coming soon" placeholder screens.
    var icon: String {
        switch self {
        case .home: "house"
        case .understand: "chart.bar"
        case .aiChat: "sparkles"
        case .family: "person.2"
        case .rewards: "gift"
        }
    }
}

/// Custom bottom tab bar with a raised center FAB, matching the Figma design.
struct AppTabBar: View {
    @Binding var selected: AppTab

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(AppColor.tabBarTopBorder)
                .frame(height: 1)

            ZStack(alignment: .top) {
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(AppTab.allCases) { tab in
                        tabItem(tab)
                    }
                }
                .padding(8)

                fab
                    .offset(y: -20)
            }
        }
        .background(AppColor.surface.ignoresSafeArea(edges: .bottom))
    }

    private func tabItem(_ tab: AppTab) -> some View {
        let isSelected = tab == selected
        return Button {
            selected = tab
        } label: {
            VStack(spacing: 4) {
                if tab == .aiChat {
                    // The FAB occupies this slot visually; keep the label aligned with the row.
                    Color.clear.frame(width: 24, height: 22)
                } else {
                    IconImage(tab.assetName, height: 22)
                        .frame(height: 22)
                }
                Text(tab.title)
                    .font(AppFont.tabLabel)
            }
            .foregroundStyle(isSelected ? AppColor.accentSoftText : AppColor.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var fab: some View {
        Button {
            selected = .aiChat
        } label: {
            IconImage("icon-sparkle-fab", height: 26)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(AppColor.accent, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(AppColor.surface, lineWidth: 4)
                )
                .shadow(color: AppColor.accent.opacity(0.35), radius: 8, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("AI Chat")
    }
}

#Preview {
    AppTabBar(selected: .constant(.home))
}
