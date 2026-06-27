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
                    .font(.headline)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .accessibilityLabel("recipe_back_button")

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 8)
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
                    .font(.system(.body, design: .rounded))
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
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// Renders a structured recipe: title, ingredients and ordered steps.
struct RecipeBody: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if !recipe.title.isEmpty {
                Text(recipe.title)
                    .font(.system(.title2, design: .serif).weight(.bold))
                    .foregroundStyle(.primary)
            }

            if !recipe.ingredients.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("recipe_ingredients_header")

                    ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { _, ingredient in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("•")
                            Text(ingredient)
                        }
                        .font(.system(.body, design: .serif))
                        .foregroundStyle(.primary)
                    }
                }
            }

            if !recipe.steps.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("recipe_steps_header")

                    ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\(index + 1).")
                                .fontWeight(.semibold)
                                .monospacedDigit()
                            Text(step)
                        }
                        .font(.system(.body, design: .serif))
                        .foregroundStyle(.primary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionLabel(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.system(.caption, design: .rounded).weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }
}

#Preview {
    RecipeView(viewModel: AppViewModelFactory.preview.makeRecipeViewModel(ingredients: ["Eggs", "Milk", "Flour"]))
}
