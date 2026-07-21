import SwiftUI

/// A shimmering placeholder block for skeleton loading states: a rounded base fill with a
/// highlight that sweeps across it.
///
/// Honors Reduce Motion (per the animation-motion conventions): when the user has it enabled, the
/// block renders as a static fill with no sweeping animation.
struct SkeletonBlock: View {
    var cornerRadius: CGFloat = 8

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = 0

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(AppColor.skeletonBase)
            .overlay {
                if !reduceMotion {
                    GeometryReader { proxy in
                        let width = proxy.size.width
                        LinearGradient(
                            colors: [.clear, AppColor.skeletonHighlight, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: width * 0.5)
                        .offset(x: -width * 0.75 + phase * (width * 1.5))
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
            .accessibilityHidden(true)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        SkeletonBlock().frame(width: 220, height: 26)
        SkeletonBlock(cornerRadius: 20).frame(height: 120)
    }
    .padding()
}
