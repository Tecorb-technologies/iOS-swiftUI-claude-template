import SwiftUI

/// "Today's step" card — a progress ring plus a short prompt for the day.
struct TodaysStepCard: View {
    let step: TodaysStep

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TagPill(title: step.tag)
                Spacer()
                Text(step.progressLabel)
                    .font(AppFont.tag)
                    .foregroundStyle(AppColor.textTertiary)
            }

            HStack(spacing: 14) {
                ProgressRing(progress: step.progress, label: "\(step.stepNumber)")

                VStack(alignment: .leading, spacing: 3) {
                    Text(step.title)
                        .font(AppFont.cardTitle)
                        .foregroundStyle(AppColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(step.subtitle)
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack {
                Spacer()
                ActionButton(title: step.actionTitle, style: .soft)
            }
        }
        .padding(16)
        .cardStyle()
    }
}

#Preview {
    TodaysStepCard(step: TodaysStep(
        tag: "Today's step",
        progressLabel: "Day 6 of 14",
        stepNumber: 6,
        totalSteps: 14,
        title: "Set your family's evening screen rhythm",
        subtitle: "A 2-minute read on winding down before bed.",
        actionTitle: "Start step"
    ))
    .padding()
}
