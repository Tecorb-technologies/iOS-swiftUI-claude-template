import SwiftUI

/// A 1-pt horizontal dashed rule, matching the divider between family-status rows.
struct DashedDivider: View {
    var color: Color = AppColor.separator

    var body: some View {
        Line()
            .stroke(color, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            .frame(height: 1)
            .accessibilityHidden(true)
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            Path { path in
                path.move(to: CGPoint(x: 0, y: rect.midY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            }
        }
    }
}
