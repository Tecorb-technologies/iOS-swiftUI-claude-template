import SwiftUI

/// The Home screen: a sky-gradient header, a scrolling feed of cards, and a custom bottom tab bar
/// with a raised FAB. Drives the loading / error / populated states off `HomeViewModel`.
struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var selectedTab: AppTab = .home
    @State private var showingSettings = false

    init(viewModel: HomeViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColor.background.ignoresSafeArea()
            skyGradient

            VStack(spacing: 0) {
                HomeHeader(title: selectedTab.title, hasUnread: true) {
                    showingSettings = true
                }
                content
            }

            AppTabBar(selected: $selectedTab)
        }
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }

    // MARK: State routing

    @ViewBuilder
    private var content: some View {
        if selectedTab == .home {
            switch viewModel.state {
            case .loading:
                HomeSkeletonView()
            case let .failed(message):
                errorView(message)
            case let .loaded(feed):
                feedView(for: feed)
            }
        } else {
            ComingSoonView(tab: selectedTab)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(AppColor.textTertiary)
                .accessibilityHidden(true)
            Text(message)
                .font(AppFont.subtitle)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                Task { await viewModel.load() }
            } label: {
                Text("Try again")
                    .font(AppFont.pillButton)
                    .foregroundStyle(AppColor.onAccent)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AppColor.accent, in: Capsule())
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.xl)
    }

    // MARK: Feed

    private func feedView(for feed: HomeFeed) -> some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 12) {
                GreetingView(greeting: feed.greeting)

                SectionLabel(feed.primarySectionTitle)
                FamilyStatusCard(status: feed.familyStatus)
                FamilyWinCard(win: feed.familyWin)

                SectionLabel(feed.supportingSectionTitle)
                TodaysStepCard(step: feed.todaysStep)
                VideoCard(video: feed.video)

                HStack(alignment: .top, spacing: 12) {
                    ForEach(feed.utilities) { utility in
                        UtilityCard(utility: utility)
                    }
                }

                ResourcesCard(resources: feed.resources)

                Text("more content below")
                    .font(AppFont.footnoteItalic)
                    .foregroundStyle(AppColor.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 96)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    /// Soft sky wash behind the header. Taller than Figma's 240pt block, eased into the page
    /// background, and opacity-masked at the bottom so there isn't a hard cutoff line.
    private var skyGradient: some View {
        LinearGradient(stops: AppColor.skyGradientStops, startPoint: .top, endPoint: .bottom)
            .frame(height: 320)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .white, location: 0),
                        .init(color: .white, location: 0.5),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)
    }
}

/// Top header: bell (with optional unread dot), centered title, and settings gear.
private struct HomeHeader: View {
    let title: String
    var hasUnread: Bool = false
    var onSettings: () -> Void = {}

    var body: some View {
        ZStack {
            Text(title)
                .font(AppFont.screenTitle)
                .foregroundStyle(AppColor.textPrimary)

            HStack {
                circleButton(asset: "icon-bell", label: "Notifications", showsUnread: hasUnread) {}
                Spacer()
                circleButton(asset: "icon-gear", label: "Settings", showsUnread: false, action: onSettings)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }

    private func circleButton(
        asset: String,
        label: String,
        showsUnread: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack(alignment: .topLeading) {
                IconImage(asset, width: 22, height: 22)
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(AppColor.surface.opacity(0.75), in: Circle())
                    .overlay(Circle().strokeBorder(AppColor.cardBorderAccent, lineWidth: 1))

                if showsUnread {
                    // Figma unread (10:18 / 18:18): 13×13 asset (#F43F5E + ring). Ellipse is
                    // 9×9 at (23, 7); stroke overflows 2pt each side → origin (21, 5).
                    Image("icon-unread")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 13, height: 13)
                        .offset(x: 21, y: 5)
                        .accessibilityHidden(true)
                }
            }
            .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(showsUnread ? "Unread" : "")
    }
}

private struct GreetingView: View {
    let greeting: Greeting

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(greeting.title)
                .font(AppFont.greetingTitle)
                .foregroundStyle(AppColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(greeting.subtitle)
                .font(AppFont.subtitle)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }
}

private struct SectionLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text.uppercased())
            .font(AppFont.sectionLabel)
            .tracking(1.1)
            .foregroundStyle(AppColor.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ComingSoonView: View {
    let tab: AppTab

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Spacer()
            Image(systemName: tab.icon)
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(AppColor.accent)
                .accessibilityHidden(true)
            Text("\(tab.title) is coming soon")
                .font(AppFont.cardTitle)
                .foregroundStyle(AppColor.textPrimary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 96)
    }
}

#Preview("Light") {
    HomeView(viewModel: HomeViewModel(service: PreviewHomeService()))
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    HomeView(viewModel: HomeViewModel(service: PreviewHomeService()))
        .preferredColorScheme(.dark)
}
