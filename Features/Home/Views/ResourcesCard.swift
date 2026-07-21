import SwiftUI

/// "Resources library" row card — icon, title/subtitle, and a browse action.
struct ResourcesCard: View {
    let resources: ResourceLibrary

    var body: some View {
        HStack(spacing: 14) {
            BooksIcon()

            VStack(alignment: .leading, spacing: 2) {
                Text(resources.title)
                    .font(AppFont.cardTitle)
                    .foregroundStyle(AppColor.textPrimary)
                Text(resources.subtitle)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            ActionButton(title: resources.actionTitle, style: .soft)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .cardStyle()
    }
}

/// Layered "books" glyph reconstructed from the Figma design (multi-tone, so not a template asset):
/// two tilted book covers behind a front cover with three page lines.
private struct BooksIcon: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            cover(AppColor.booksBack)
                .rotationEffect(.degrees(6))
                .offset(x: 9, y: 0)
            cover(AppColor.booksMid)
                .rotationEffect(.degrees(-4))
                .offset(x: 5, y: 0)
            ZStack {
                cover(AppColor.booksFront)
                VStack(spacing: 3) {
                    line(1.0)
                    line(0.7)
                    line(0.4)
                }
            }
            .offset(x: 0, y: 4)
        }
        .frame(width: 44, height: 40, alignment: .topLeading)
        .accessibilityHidden(true)
    }

    private func cover(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(color)
            .frame(width: 30, height: 34)
    }

    private func line(_ opacity: Double) -> some View {
        Capsule()
            .fill(Color.white.opacity(opacity))
            .frame(width: 14, height: 2)
    }
}

#Preview {
    ResourcesCard(resources: ResourceLibrary(
        title: "Resources library",
        subtitle: "Articles & guides — always free",
        actionTitle: "Browse"
    ))
    .padding()
}
