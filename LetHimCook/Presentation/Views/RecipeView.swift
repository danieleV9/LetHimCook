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

/// Full-bleed hero artwork with a rounded content sheet overlapping it, like
/// a restaurant detail page on TheFork. Once the content sheet scrolls up to
/// the top controls, a solid bar fades in behind them so the content never
/// runs under the status bar or the back button.
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

/// Renders a structured recipe: title, key facts, ingredients and ordered steps.
struct RecipeBody: View {
    let recipe: Recipe
    var isSaved = false

    /// Ingredients the user has ticked off while cooking. View-only state.
    @State private var checkedIngredients: Set<Int> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            titleBlock

            if !recipe.ingredients.isEmpty || !recipe.steps.isEmpty {
                factsRow
            }

            if !recipe.ingredients.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    AppSectionHeader(titleKey: "recipe_ingredients_header")
                        .padding(.bottom, 8)

                    ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                        ingredientRow(ingredient, at: index)

                        if index < recipe.ingredients.count - 1 {
                            Divider().padding(.leading, 36)
                        }
                    }
                }
            }

            if !recipe.steps.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    AppSectionHeader(titleKey: "recipe_steps_header")

                    ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                        stepRow(step, number: index + 1)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Pieces

    @ViewBuilder
    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                AppBadge(titleKey: "badge_on_device_ai", systemImage: "sparkles")
                if isSaved {
                    AppBadge(titleKey: "recipe_saved_badge", systemImage: "bookmark.fill")
                }
            }

            if !recipe.title.isEmpty {
                Text(recipe.title)
                    .font(.title.weight(.bold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var factsRow: some View {
        HStack(spacing: 12) {
            factTile(value: recipe.ingredients.count, titleKey: "recipe_ingredients_header", systemImage: "basket")
            factTile(value: recipe.steps.count, titleKey: "recipe_steps_header", systemImage: "list.number")
        }
    }

    private func factTile(value: Int, titleKey: LocalizedStringKey, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(AppTheme.accent)
            VStack(alignment: .leading, spacing: 0) {
                Text(value, format: .number)
                    .font(.headline)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text(titleKey)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(AppTheme.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func ingredientRow(_ ingredient: String, at index: Int) -> some View {
        let isChecked = checkedIngredients.contains(index)

        return Button {
            withAnimation(.snappy) {
                if isChecked {
                    checkedIngredients.remove(index)
                } else {
                    checkedIngredients.insert(index)
                }
            }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isChecked ? AppTheme.accent : .secondary)
                Text(ingredient)
                    .font(.body)
                    .foregroundStyle(isChecked ? .secondary : .primary)
                    .strikethrough(isChecked)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isChecked ? .isSelected : [])
    }

    private func stepRow(_ step: String, number: Int) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number, format: .number)
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(AppTheme.accent, in: Circle())
                .accessibilityHidden(true)

            Text(step)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(number). \(step)"))
    }
}

#Preview("Recipe detail") {
    RecipeDetailLayout(artworkSeed: "Carbonara", title: "Creamy Egg & Parmigiano Pasta") {
        RecipeBody(
            recipe: Recipe(
                title: "Creamy Egg & Parmigiano Pasta",
                ingredients: ["200 g spaghetti", "2 eggs", "50 g Parmigiano", "Black pepper", "Salt"],
                steps: [
                    "Boil the spaghetti in salted water until al dente.",
                    "Whisk the eggs with the grated Parmigiano and plenty of pepper.",
                    "Toss the drained pasta off the heat with the egg mixture, adding pasta water until creamy."
                ]
            ),
            isSaved: true
        )
    }
}

#Preview {
    RecipeView(viewModel: AppViewModelFactory.preview.makeRecipeViewModel(ingredients: ["Eggs", "Milk", "Flour"]))
}
