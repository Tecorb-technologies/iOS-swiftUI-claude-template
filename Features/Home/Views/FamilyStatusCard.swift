import SwiftUI

/// "Family status" card — headline plus a per-child status list with trend sparklines.
struct FamilyStatusCard: View {
    let status: FamilyStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                TagPill(title: status.tag)
                Spacer()
                Text(status.timeframe)
                    .font(AppFont.tag)
                    .foregroundStyle(AppColor.textTertiary)
            }

            Text(status.headline)
                .font(AppFont.cardHeadline)
                .foregroundStyle(AppColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 0) {
                ForEach(Array(status.members.enumerated()), id: \.element.id) { index, member in
                    MemberStatusRow(member: member)
                    if index < status.members.count - 1 {
                        DashedDivider()
                    }
                }
            }

            HStack {
                Text(status.footnote)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textTertiary)
                Spacer()
                ActionButton(title: status.actionTitle, style: .filledAccent)
            }
        }
        .padding(16)
        .cardStyle(border: AppColor.cardBorderAccent)
    }
}

/// A single child row: avatar with status dot, name + note, and a trend sparkline.
private struct MemberStatusRow: View {
    let member: Member

    var body: some View {
        HStack(spacing: 10) {
            AvatarView(name: member.name, status: member.status)

            VStack(alignment: .leading, spacing: 1) {
                Text(member.name)
                    .font(AppFont.memberName)
                    .foregroundStyle(AppColor.textPrimary)
                Text(member.note)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.memberNote)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Sparkline(values: member.trend, color: trendColor)
                .frame(width: 72, height: 28)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }

    private var trendColor: Color {
        member.status == .calm ? AppColor.accent : AppColor.statusWatch
    }
}

private struct AvatarView: View {
    let name: String
    let status: Member.Status

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(AppColor.accentSoftBackground)
                .overlay(
                    Text(initial)
                        .font(AppFont.avatarInitial)
                        .foregroundStyle(AppColor.accentSoftText)
                )

            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
                .overlay(Circle().strokeBorder(AppColor.surface, lineWidth: 2))
        }
        .frame(width: 36, height: 36)
        .accessibilityHidden(true)
    }

    private var initial: String {
        name.first.map(String.init) ?? "?"
    }

    private var statusColor: Color {
        status == .calm ? AppColor.statusCalm : AppColor.statusWatch
    }
}

#Preview {
    FamilyStatusCard(status: FamilyStatus(
        tag: "Family status",
        timeframe: "This week",
        headline: "A calm, creative week for your family.",
        members: [
            Member(
                id: "emma",
                name: "Emma",
                note: "Calm week — creative & school topics",
                status: .calm,
                trend: [3, 4, 3.5, 5, 5.5, 7, 8]
            ),
            Member(
                id: "jake",
                name: "Jake",
                note: "A couple of late-night sessions worth a look",
                status: .watch,
                trend: [4, 3.7, 5.2, 5.5, 3, 5, 8, 6.8]
            ),
        ],
        footnote: "Patterns, not surveillance",
        actionTitle: "Full picture"
    ))
    .padding()
}
