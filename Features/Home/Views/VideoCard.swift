import SwiftUI

/// Video card — an indigo gradient "poster" with a play button and title overlay, plus a footer.
struct VideoCard: View {
    let video: VideoItem

    var body: some View {
        VStack(spacing: 0) {
            media

            HStack {
                Text(video.source)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textTertiary)
                Spacer()
                ActionButton(title: video.actionTitle, style: .soft)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .cardStyle()
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var media: some View {
        ZStack {
            RadialGradient(
                colors: AppColor.videoGradient,
                center: .center,
                startRadius: 4,
                endRadius: 240
            )

            LinearGradient(
                colors: [.clear, .black.opacity(0.4)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(spacing: 0) {
                HStack {
                    Text(video.badge)
                        .font(AppFont.badge)
                        .foregroundStyle(AppColor.accentSoftText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppColor.surface.opacity(0.9), in: Capsule())
                    Spacer()
                }
                Spacer()
                HStack {
                    Text(video.title)
                        .font(AppFont.cardTitle)
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            playButton
        }
        .frame(height: 150)
        .clipped()
    }

    private var playButton: some View {
        IconImage("icon-play", width: 14, height: 16)
            .foregroundStyle(AppColor.accent)
            .frame(width: 44, height: 44)
            .background(Color.white.opacity(0.94), in: Circle())
            .shadow(color: .black.opacity(0.3), radius: 6, y: 4)
            .accessibilityHidden(true)
    }
}

#Preview {
    VideoCard(video: VideoItem(
        badge: "Watch · 5 min",
        title: "Talking to kids about what they see online",
        source: "From the Permission library",
        actionTitle: "Play video"
    ))
    .padding()
}
