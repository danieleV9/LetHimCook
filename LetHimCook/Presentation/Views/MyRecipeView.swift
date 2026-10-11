import SwiftUI

struct MyRecipeView: View {
    @State private var viewModel: MyRecipesViewModel
    @State private var selectedRecipeID: Recipe.ID? = nil
    @State private var isConfirmingClearAll = false

    init(viewModel: MyRecipesViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                if viewModel.recipes.isEmpty {
                    ContentUnavailableView {
                        Label("saved_recipes_empty_title", systemImage: "bookmark")
                    } description: {
                        Text("saved_recipes_empty_description")
                    }
                    .padding(.horizontal)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.recipes) { recipe in
                                Button {
                                    selectedRecipeID = recipe.id
                                } label: {
                                    SavedRecipeRow(recipe: recipe)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("saved_recipes_nav_title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !viewModel.recipes.isEmpty {
                        Button("saved_recipes_clear_all", role: .destructive) {
                            isConfirmingClearAll = true
                        }
                        .tint(.red)
                    }
                }
            }
            .confirmationDialog(
                "saved_recipes_clear_confirm_title",
                isPresented: $isConfirmingClearAll,
                titleVisibility: .visible
            ) {
                Button("saved_recipes_clear_all", role: .destructive) {
                    Task {
                        await viewModel.deleteAllRecipes()
                    }
                }
            }
            .navigationDestination(item: $selectedRecipeID) { id in
                if let recipe = viewModel.recipes.first(where: { $0.id == id }) {
                    RecipeDetailLayout(artworkSeed: recipe.id.uuidString, title: recipe.title, chrome: .navigationStack) {
                        RecipeBody(recipe: recipe, isSaved: true)
                    }
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadRecipes()
            }
        }
    }
}

/// A listing card with a thumbnail on the left.
private struct SavedRecipeRow: View {
    let recipe: Recipe

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RecipeArtwork(seed: recipe.id.uuidString, symbolSize: 32)
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                (recipe.title.isEmpty ? Text("recipe_title") : Text(recipe.title))
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if !recipe.ingredients.isEmpty {
                    Text(recipe.ingredients.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 12) {
                    Label {
                        Text(recipe.ingredients.count, format: .number)
                    } icon: {
                        Image(systemName: "basket")
                    }
                    .accessibilityLabel(Text("recipe_ingredients_header") + Text(" \(recipe.ingredients.count)"))

                    Label {
                        Text(recipe.steps.count, format: .number)
                    } icon: {
                        Image(systemName: "list.number")
                    }
                    .accessibilityLabel(Text("recipe_steps_header") + Text(" \(recipe.steps.count)"))
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.forward")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
                .accessibilityHidden(true)
        }
        .padding(12)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
    }
}

#Preview {
    MyRecipeView(viewModel: AppViewModelFactory.preview.makeMyRecipesViewModel())
}
