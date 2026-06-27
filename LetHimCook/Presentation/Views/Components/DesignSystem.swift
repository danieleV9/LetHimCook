import SwiftUI

enum AppTheme {
    /// Brand accent. Used as the tint for prominent controls.
    static let accent = Color(red: 0.95, green: 0.46, blue: 0.20)
    static let accentSoft = Color(red: 0.99, green: 0.76, blue: 0.58)

    static let lightBackgroundTop = Color(red: 0.99, green: 0.97, blue: 0.93)
    static let lightBackgroundBottom = Color(red: 0.98, green: 0.90, blue: 0.80)
    static let darkBackgroundTop = Color(red: 0.10, green: 0.08, blue: 0.07)
    static let darkBackgroundBottom = Color(red: 0.16, green: 0.11, blue: 0.08)
}

struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [AppTheme.darkBackgroundTop, AppTheme.darkBackgroundBottom]
                : [AppTheme.lightBackgroundTop, AppTheme.lightBackgroundBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

/// A content surface. Uses a system material so it adapts to light/dark and to
/// the Reduce Transparency / Increase Contrast accessibility settings.
struct AppCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(
                .regularMaterial,
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 8)
    }
}

struct AppChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                AppTheme.accentSoft.opacity(0.35),
                in: Capsule(style: .continuous)
            )
    }
}

struct AppSectionHeader: View {
    let titleKey: LocalizedStringKey

    var body: some View {
        Text(titleKey)
            .font(.system(.title3, design: .rounded).weight(.bold))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
