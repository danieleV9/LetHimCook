import SwiftUI

struct RecipeView: View {
    @Bindable var viewModel: RecipeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    AppSectionHeader(titleKey: "recipe_title")

                    content
                }
                .padding(.horizontal)
                .padding(.top, 70)
                .padding(.bottom, 24)
            }
        }
        .safeAreaInset(edge: .top) {
            topBar
        }
        .task {
            await viewModel.loadRecipe()
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .frame(width: 36, height: 36)
                    .background(
                        .ultraThinMaterial,
                        in: Circle()
                    )
                    .accessibilityLabel("recipe_back_button")
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(
            .ultraThinMaterial
                .opacity(0.9)
        )
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            AppCard {
                generatingIndicator
            }
        case .streaming(let recipe):
            AppCard {
                VStack(alignment: .leading, spacing: 16) {
                    generatingIndicator
                    RecipeBody(recipe: recipe)
                }
            }
        case .success(let recipe):
            AppCard {
                RecipeBody(recipe: recipe)
            }
        case .failure(let message):
            AppCard {
                ContentUnavailableView {
                    Label(message, systemImage: "sparkles.slash")
                }
            }
        case .idle:
            AppCard {
                Text("recipe_placeholder")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var generatingIndicator: some View {
        HStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)

            Text("recipe_generating")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.inkMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Renders a structured recipe: title, ingredients and ordered steps.
struct RecipeBody: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if !recipe.title.isEmpty {
                Text(recipe.title)
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundStyle(AppTheme.ink)
            }

            if !recipe.ingredients.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("recipe_ingredients_header")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.inkMuted)
                        .textCase(.uppercase)

                    ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { _, ingredient in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text(ingredient)
                        }
                        .font(.system(size: 16, weight: .regular, design: .serif))
                        .foregroundStyle(AppTheme.ink)
                    }
                }
            }

            if !recipe.steps.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("recipe_steps_header")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.inkMuted)
                        .textCase(.uppercase)

                    ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .fontWeight(.semibold)
                            Text(step)
                        }
                        .font(.system(size: 16, weight: .regular, design: .serif))
                        .foregroundStyle(AppTheme.ink)
                        .lineSpacing(4)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    RecipeView(viewModel: AppViewModelFactory.preview.makeRecipeViewModel(ingredients: ["Eggs", "Milk", "Flour"]))
}
