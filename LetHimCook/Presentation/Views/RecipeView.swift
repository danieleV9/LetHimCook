import SwiftUI

struct RecipeView: View {
    @Bindable var viewModel: RecipeViewModel

    var body: some View {
        RecipeDetailLayout(artworkSeed: viewModel.recipeID.uuidString, title: title) {
            content
        }
        .task {
            await viewModel.loadRecipe()
        }
    }

    private var title: String {
        switch viewModel.state {
        case .streaming(let recipe), .success(let recipe): recipe.title
        default: ""
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            generatingIndicator
        case .streaming(let recipe):
            VStack(alignment: .leading, spacing: 20) {
                generatingIndicator
                RecipeBody(recipe: recipe)
            }
        case .success(let recipe):
            RecipeBody(recipe: recipe, isSaved: true)
        case .failure(let message):
            ContentUnavailableView {
                Label(message, systemImage: "sparkles.slash")
            }
        case .idle:
            Text("recipe_placeholder")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var generatingIndicator: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(AppTheme.accent)

            Text("recipe_generating")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(AppTheme.accentSoft, in: Capsule(style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// Full-bleed hero artwork with a rounded content sheet overlapping it. Once
/// the content sheet scrolls up to the top controls, a solid bar fades in
/// behind them so the content never runs under the status bar or the back
/// button.
struct RecipeDetailLayout<Content: View>: View {
    /// Where the layout is shown, which decides who owns the top controls.
    enum Chrome {
        /// Full-screen cover: the layout draws its own back button and title.
        case standalone
        /// Pushed on a `NavigationStack`: the system bar keeps the back button
        /// and swipe-to-go-back, and shows the title once the bar appears.
        case navigationStack
    }

    let artworkSeed: String
    var title: String = ""
    var chrome: Chrome = .standalone
    let content: Content

    @Environment(\.dismiss) private var dismiss

    private static var heroHeight: CGFloat { 280 }
    private static var sheetOverlap: CGFloat { 28 }
    /// Height of the area below the status bar that holds the custom back
    /// button. A navigation bar is already part of the top safe area.
    private static var standaloneBarHeight: CGFloat { 60 }

    @State private var isBarVisible = false

    init(
        artworkSeed: String,
        title: String = "",
        chrome: Chrome = .standalone,
        @ViewBuilder content: () -> Content
    ) {
        self.artworkSeed = artworkSeed
        self.title = title
        self.chrome = chrome
        self.content = content()
    }

    private var barHeight: CGFloat {
        chrome == .standalone ? Self.standaloneBarHeight : 0
    }

    var body: some View {
        GeometryReader { proxy in
            let topInset = proxy.safeAreaInsets.top

            ScrollView {
                VStack(spacing: 0) {
                    RecipeArtwork(seed: artworkSeed, symbolSize: 72)
                        .frame(height: Self.heroHeight)

                    content
                        .padding(20)
                        .padding(.bottom, 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            AppTheme.surface,
                            in: UnevenRoundedRectangle(
                                topLeadingRadius: Self.sheetOverlap,
                                topTrailingRadius: Self.sheetOverlap,
                                style: .continuous
                            )
                        )
                        .padding(.top, -Self.sheetOverlap)
                }
            }
            .onScrollGeometryChange(for: Bool.self) { geometry in
                let sheetTop = Self.heroHeight - Self.sheetOverlap - geometry.contentOffset.y
                return sheetTop <= topInset + barHeight
            } action: { _, reachedBar in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isBarVisible = reachedBar
                }
            }
            // The system navigation bar would otherwise blur and wash out the
            // top of the hero; the solid top bar takes over once it scrolls.
            .scrollEdgeEffectHidden(true, for: .top)
            .ignoresSafeArea(edges: .top)
            .overlay(alignment: .top) {
                topBar(topInset: topInset)
                    .opacity(isBarVisible ? 1 : 0)
                    .allowsHitTesting(false)
                    .ignoresSafeArea(edges: .top)
            }
            .overlay(alignment: .topLeading) {
                if chrome == .standalone {
                    backButton
                }
            }
        }
        .background(AppTheme.surface)
        .toolbar {
            if chrome == .navigationStack {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                        .opacity(isBarVisible ? 1 : 0)
                }
            }
        }
    }

    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.backward")
                .font(.headline)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .controlSize(.large)
        .accessibilityLabel("recipe_back_button")
        .padding(.horizontal)
        .padding(.top, 8)
    }

    /// Solid backing for the top controls. In `.standalone` it also carries
    /// the title; in `.navigationStack` the system bar shows it instead.
    private func topBar(topInset: CGFloat) -> some View {
        Text(chrome == .standalone ? title : "")
            .font(.headline)
            .lineLimit(1)
            .padding(.horizontal, 72)
            .padding(.top, topInset)
            .frame(maxWidth: .infinity)
            .frame(height: topInset + barHeight)
            .background(AppTheme.surface)
            .overlay(alignment: .bottom) {
                Divider()
            }
            .accessibilityHidden(true)
    }
}

#Preview {
    RecipeView(viewModel: AppViewModelFactory.preview.makeRecipeViewModel(ingredients: ["Eggs", "Milk", "Flour"]))
}
