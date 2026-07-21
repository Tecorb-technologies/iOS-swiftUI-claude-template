import SwiftUI

/// A tiny trend line used in the family-status rows. Draws a smoothed curve (Catmull-Rom) through
/// the normalized series with a filled dot at the last point, matching the Figma design.
struct Sparkline: View {
    let values: [Double]
    var color: Color = AppColor.accent

    private let dotRadius: CGFloat = 3

    var body: some View {
        GeometryReader { proxy in
            let pts = points(in: proxy.size)
            ZStack(alignment: .topLeading) {
                curve(through: pts)
                    .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                if let last = pts.last {
                    Circle()
                        .fill(color)
                        .frame(width: dotRadius * 2, height: dotRadius * 2)
                        .position(last)
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func points(in size: CGSize) -> [CGPoint] {
        guard values.count > 1 else { return [] }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 1
        let range = max(maxValue - minValue, 0.0001)
        // Inset so the 2-pt stroke and the end dot aren't clipped at the edges.
        let vInset = max(dotRadius, 2)
        let usableHeight = max(size.height - vInset * 2, 1)
        let usableWidth = max(size.width - dotRadius, 1)
        let stepX = usableWidth / CGFloat(values.count - 1)

        return values.enumerated().map { index, value in
            let normalized = (value - minValue) / range
            let y = vInset + (1 - CGFloat(normalized)) * usableHeight
            return CGPoint(x: CGFloat(index) * stepX, y: y)
        }
    }

    private func curve(through pts: [CGPoint]) -> Path {
        Path { path in
            guard let first = pts.first else { return }
            path.move(to: first)

            for index in 0 ..< pts.count - 1 {
                let p0 = pts[max(index - 1, 0)]
                let p1 = pts[index]
                let p2 = pts[index + 1]
                let p3 = pts[min(index + 2, pts.count - 1)]
                // Catmull-Rom → cubic Bézier control points.
                let control1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
                let control2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
                path.addCurve(to: p2, control1: control1, control2: control2)
            }
        }
    }
}

#Preview {
    HStack(spacing: 24) {
        Sparkline(values: [3, 4, 3.5, 5, 5.5, 7, 8])
        Sparkline(values: [4, 6, 3.5, 6.5, 4, 6, 5], color: AppColor.statusWatch)
    }
    .frame(height: 28)
    .padding()
}
