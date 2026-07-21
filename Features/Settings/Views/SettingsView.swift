import SwiftUI

/// Settings screen, presented as a sheet from the Home header's gear button. Not part of the Figma
/// design — built from the app's design system. Hosts the light/dark theme switch plus placeholder
/// preference rows.
struct SettingsView: View {
    @AppStorage("app.theme.mode") private var themeMode: AppThemeMode = .system
    @AppStorage("settings.notifications.push") private var pushEnabled = true
    @AppStorage("settings.notifications.weekly") private var weeklyEnabled = true

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        appearanceSection
                        notificationsSection
                        familySection
                        aboutSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
        }
    }

    private var header: some View {
        ZStack {
            Text("Settings")
                .font(AppFont.screenTitle)
                .foregroundStyle(AppColor.textPrimary)
            HStack {
                Spacer()
                doneButton
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }

    /// Circular icon button matching the Home header's gear/bell button styling, so the sheet's
    /// dismiss control reads as part of the same visual language rather than a text link.
    private var doneButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "checkmark")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColor.textPrimary)
                .frame(width: 40, height: 40)
                .background(AppColor.surface.opacity(0.75), in: Circle())
                .overlay(Circle().strokeBorder(AppColor.cardBorderAccent, lineWidth: 1))
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Done")
    }

    // MARK: Sections

    private var appearanceSection: some View {
        SettingsSection(title: "Appearance") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Theme")
                    .font(AppFont.subtitle)
                    .foregroundStyle(AppColor.textPrimary)
                ThemeModePicker(selection: $themeMode)
                Text("“System” follows your device’s appearance setting.")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textTertiary)
            }
            .padding(14)
        }
    }

    private var notificationsSection: some View {
        SettingsSection(title: "Notifications") {
            VStack(spacing: 0) {
                SettingsRow(icon: "bell.fill", tint: AppColor.accent, title: "Push notifications") {
                    Toggle("", isOn: $pushEnabled).labelsHidden().tint(AppColor.accent)
                }
                DashedDivider().padding(.horizontal, 14)
                SettingsRow(icon: "calendar", tint: AppColor.accent, title: "Weekly summary") {
                    Toggle("", isOn: $weeklyEnabled).labelsHidden().tint(AppColor.accent)
                }
            }
        }
    }

    private var familySection: some View {
        SettingsSection(title: "Family") {
            VStack(spacing: 0) {
                SettingsRow(icon: "person.2.fill", tint: AppColor.accent, title: "Manage family") { chevron }
                DashedDivider().padding(.horizontal, 14)
                SettingsRow(icon: "person.badge.plus", tint: AppColor.accent, title: "Add a child") { chevron }
            }
        }
    }

    private var aboutSection: some View {
        SettingsSection(title: "About") {
            VStack(spacing: 0) {
                SettingsRow(icon: "info.circle.fill", tint: AppColor.textTertiary, title: "Version") {
                    Text(Self.appVersion)
                        .font(AppFont.subtitle)
                        .foregroundStyle(AppColor.textTertiary)
                }
                DashedDivider().padding(.horizontal, 14)
                SettingsRow(icon: "lock.fill", tint: AppColor.textTertiary, title: "Privacy Policy") { chevron }
                DashedDivider().padding(.horizontal, 14)
                SettingsRow(icon: "doc.text.fill", tint: AppColor.textTertiary, title: "Terms of Service") { chevron }
            }
        }
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AppColor.textTertiary)
            .accessibilityHidden(true)
    }

    private static var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        return version
    }
}

/// Section header + a rounded card wrapping the section's rows.
private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(AppFont.sectionLabel)
                .tracking(1.1)
                .foregroundStyle(AppColor.textTertiary)
                .padding(.leading, 4)
            VStack(spacing: 0) { content }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
        }
    }
}

/// A single settings row: tinted icon, title, and a trailing accessory (toggle / chevron / value).
private struct SettingsRow<Trailing: View>: View {
    let icon: String
    let tint: Color
    let title: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(tint.opacity(0.15))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(tint)
                )
                .accessibilityHidden(true)
            Text(title)
                .font(AppFont.subtitle)
                .foregroundStyle(AppColor.textPrimary)
            Spacer(minLength: 8)
            trailing
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

/// Segmented control for `AppThemeMode`, styled to match the app rather than the native picker.
struct ThemeModePicker: View {
    @Binding var selection: AppThemeMode

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppThemeMode.allCases) { mode in
                let isSelected = mode == selection
                Button {
                    selection = mode
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.iconName)
                            .font(.system(size: 12, weight: .semibold))
                        Text(mode.title)
                            .font(AppFont.pillButton)
                    }
                    .foregroundStyle(isSelected ? AppColor.onAccent : AppColor.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(
                        isSelected ? AppColor.accent : Color.clear,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(mode.title)
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(4)
        .background(AppColor.accentSoftBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    SettingsView()
}
