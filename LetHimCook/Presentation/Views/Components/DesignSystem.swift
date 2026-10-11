import SwiftUI
import UIKit

/// A warm kitchen palette: terracotta for primary actions, a deep paprika
/// brown for headers, saffron used sparingly for badges/highlights, and clean,
/// solid grouped surfaces instead of heavy materials.
enum AppTheme {
    /// Brand terracotta. Slightly brightened in dark mode so it stays legible
    /// on black while still carrying white button labels.
    static let accent = adaptive(
        light: UIColor(red: 0.72, green: 0.27, blue: 0.12, alpha: 1),
        dark: UIColor(red: 0.83, green: 0.40, blue: 0.21, alpha: 1)
    )
    /// Deep paprika for hero banners (always paired with light text).
    static let accentDeep = Color(red: 0.42, green: 0.15, blue: 0.08)
    /// Saffron highlight for badges. Always paired with `onHighlight` text.
    static let highlight = Color(red: 1.00, green: 0.80, blue: 0.36)
    static let onHighlight = Color(red: 0.30, green: 0.15, blue: 0.04)
    /// Tinted fill for chips and icon backgrounds.
    static let accentSoft = adaptive(
        light: UIColor(red: 0.72, green: 0.27, blue: 0.12, alpha: 0.10),
        dark: UIColor(red: 0.88, green: 0.45, blue: 0.25, alpha: 0.18)
    )

    static let background = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let separator = Color(uiColor: .separator)

    static let cornerRadius: CGFloat = 16

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
}

struct AppBackground: View {
    var body: some View {
        AppTheme.background
            .ignoresSafeArea()
    }
}

/// A solid content surface with a soft shadow.
struct AppCard<Content: View>: View {
    var padding: CGFloat = 16
    let content: Content

    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                AppTheme.surface,
                in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
            )
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

/// An outlined pill for a single value, such as an ingredient.
struct AppChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.primary)
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(AppTheme.surface, in: Capsule(style: .continuous))
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(AppTheme.separator, lineWidth: 1)
            )
    }
}

/// A small saffron tag used to highlight a key fact.
struct AppBadge: View {
    let titleKey: LocalizedStringKey
    var systemImage: String?

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(titleKey)
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(AppTheme.onHighlight)
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(AppTheme.highlight, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

/// A photo-style placeholder for a recipe. There are no real photos, so each
/// recipe gets a stable gradient derived from `seed` (pass the recipe ID). The
/// symbol is always the same: picking one from the seed would pair dishes with
/// unrelated food, like a coffee cup on a pasta recipe.
struct RecipeArtwork: View {
    let seed: String
    var symbolSize: CGFloat = 56

    private static let palettes: [[Color]] = [
        [Color(red: 0.42, green: 0.25, blue: 0.45), Color(red: 0.25, green: 0.13, blue: 0.29)],
        [Color(red: 0.93, green: 0.49, blue: 0.24), Color(red: 0.74, green: 0.27, blue: 0.14)],
        [Color(red: 0.78, green: 0.62, blue: 0.20), Color(red: 0.52, green: 0.38, blue: 0.10)],
        [Color(red: 0.72, green: 0.25, blue: 0.29), Color(red: 0.46, green: 0.12, blue: 0.18)],
        [Color(red: 0.34, green: 0.52, blue: 0.27), Color(red: 0.18, green: 0.32, blue: 0.16)]
    ]

    /// A deterministic hash; `hashValue` is randomized per launch.
    private var stableHash: Int {
        seed.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0x7FFF_FFFF }
    }

    var body: some View {
        let palette = Self.palettes[stableHash % Self.palettes.count]

        LinearGradient(colors: palette, startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay {
                Image(systemName: "fork.knife")
                    .font(.system(size: symbolSize, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            }
            .accessibilityHidden(true)
    }
}

/// A left-to-right flowing layout that wraps its subviews onto a new line when
/// they no longer fit the proposed width. Each subview is measured at its own
/// ideal size, so content is never truncated to fit a fixed column. Ideal for
/// tag / chip collections of varying widths.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var usedWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            usedWidth = max(usedWidth, x - spacing)
        }

        return CGSize(width: min(usedWidth, maxWidth), height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let maxWidth = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > bounds.minX + maxWidth && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }

            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

struct AppSectionHeader: View {
    let titleKey: LocalizedStringKey

    var body: some View {
        Text(titleKey)
            .font(.title3.weight(.bold))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
