import SwiftUI

enum AppTheme {
    static let accent = Color(red: 0.95, green: 0.46, blue: 0.20)
    static let accentSoft = Color(red: 0.99, green: 0.76, blue: 0.58)
    static let ink = Color(red: 0.20, green: 0.15, blue: 0.12)
    static let inkMuted = Color(red: 0.40, green: 0.32, blue: 0.28)
    static let cardStroke = Color.white.opacity(0.35)
    static let shadow = Color.black.opacity(0.12)

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

struct AppCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(AppTheme.cardStroke, lineWidth: 1)
            )
            .shadow(color: AppTheme.shadow, radius: 12, x: 0, y: 8)
    }
}

struct AppPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [AppTheme.accent, AppTheme.accentSoft],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .shadow(color: AppTheme.shadow, radius: 12, x: 0, y: 6)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

struct AppSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundStyle(AppTheme.accent)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppTheme.accent.opacity(0.35), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

struct AppChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(AppTheme.ink)
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
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundStyle(AppTheme.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
