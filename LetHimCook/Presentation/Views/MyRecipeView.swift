import SwiftUI

struct MyRecipeView: View {
    @State private var viewModel: MyRecipesViewModel
    @State private var selectedRecipe: Recipe? = nil

    init(viewModel: MyRecipesViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                if viewModel.recipes.isEmpty {
                    ContentUnavailableView {
                        Label("saved_recipes_nav_title", systemImage: "bookmark")
                    }
                    .padding(.horizontal)
                } else {
                    List(viewModel.recipes) { recipe in
                        Button {
                            selectedRecipe = recipe
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                (recipe.title.isEmpty ? Text("recipe_title") : Text(recipe.title))
                                    .font(.system(.headline, design: .serif))
                                    .foregroundStyle(.primary)
                                    .lineLimit(2)

                                if !recipe.ingredients.isEmpty {
                                    Text(recipe.ingredients.joined(separator: ", "))
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(
                                .regularMaterial,
                                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("saved_recipes_nav_title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !viewModel.recipes.isEmpty {
                        Button("saved_recipes_clear_all") {
                            Task {
                                await viewModel.deleteAllRecipes()
                            }
                        }
                        .tint(.red)
                    }
                }
            }
            .sheet(item: $selectedRecipe) { recipe in
                SavedRecipeSheet(recipe: recipe)
            }
        }
        .onAppear {
            Task {
                await viewModel.loadRecipes()
            }
        }
    }
}

private struct SavedRecipeSheet: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    AppCard {
                        RecipeBody(recipe: recipe)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("recipe_title")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("ingredient_input_done_button") {
                        dismiss()
                    }
                    .bold()
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    MyRecipeView(viewModel: AppViewModelFactory.preview.makeMyRecipesViewModel())
}
