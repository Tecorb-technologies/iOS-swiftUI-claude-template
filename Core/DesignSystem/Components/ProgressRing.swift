import SwiftUI

/// Circular progress indicator with a centered label, used for the "Today's step" day counter.
struct ProgressRing: View {
    let progress: Double
    let label: String
    var size: CGFloat = 52

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColor.accentSoftBackground, lineWidth: 4)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(AppColor.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(label)
                .font(AppFont.badgeNumber)
                .foregroundStyle(AppColor.accentSoftText)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    ProgressRing(progress: 6.0 / 14.0, label: "6")
        .padding()
}
