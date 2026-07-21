import SwiftUI

/// Renders a bundled template icon (exported from Figma) from the asset catalog, tinted by the
/// caller's `foregroundStyle`. Pass a width and/or height; aspect ratio is preserved.
struct IconImage: View {
    let name: String
    var width: CGFloat?
    var height: CGFloat?

    init(_ name: String, width: CGFloat? = nil, height: CGFloat? = nil) {
        self.name = name
        self.width = width
        self.height = height
    }

    var body: some View {
        Image(name)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: width, height: height)
    }
}
