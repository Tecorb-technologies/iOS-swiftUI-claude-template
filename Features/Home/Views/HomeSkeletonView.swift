import SwiftUI

/// Shimmering skeleton shown while the Home feed loads, mirroring the real feed's layout so the
/// swap to loaded content is visually stable.
struct HomeSkeletonView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                // Greeting
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonBlock().frame(width: 220, height: 26)
                    SkeletonBlock(cornerRadius: 6).frame(width: 180, height: 14)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)

                SkeletonBlock(cornerRadius: 6).frame(width: 130, height: 10)
                skeletonCard(showsMembers: true)
                skeletonCard(showsMembers: false)

                SkeletonBlock(cornerRadius: 6).frame(width: 150, height: 10)
                skeletonCard(showsMembers: false)
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 96)
        }
        .accessibilityElement()
        .accessibilityLabel("Loading")
    }

    private func skeletonCard(showsMembers: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SkeletonBlock(cornerRadius: 100).frame(width: 92, height: 22)
                Spacer()
                SkeletonBlock(cornerRadius: 100).frame(width: 56, height: 14)
            }

            SkeletonBlock(cornerRadius: 8).frame(height: 18)
            SkeletonBlock(cornerRadius: 8).frame(width: 240, height: 14)

            if showsMembers {
                ForEach(0 ..< 2, id: \.self) { _ in
                    HStack(spacing: 10) {
                        SkeletonBlock(cornerRadius: 18).frame(width: 36, height: 36)
                        VStack(alignment: .leading, spacing: 6) {
                            SkeletonBlock(cornerRadius: 6).frame(width: 80, height: 13)
                            SkeletonBlock(cornerRadius: 6).frame(height: 12)
                        }
                        Spacer(minLength: 8)
                        SkeletonBlock(cornerRadius: 6).frame(width: 72, height: 24)
                    }
                    .padding(.vertical, 4)
                }
            }

            HStack {
                Spacer()
                SkeletonBlock(cornerRadius: 100).frame(width: 128, height: 34)
            }
        }
        .padding(16)
        .cardStyle()
    }
}

#Preview {
    HomeSkeletonView()
}
