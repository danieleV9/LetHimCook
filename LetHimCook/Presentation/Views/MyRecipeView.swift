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
                            VStack(alignment: .leading, spacing: 8) {
                                Text("recipe_title")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.secondary)

                                Text(.init(recipe.text))
                                    .font(.system(size: 16, weight: .medium, design: .serif))
                                    .foregroundStyle(AppTheme.ink)
                                    .lineLimit(3)
                            }
                            .padding(16)
                            .background(
                                .ultraThinMaterial,
                                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(AppTheme.cardStroke, lineWidth: 1)
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
                        Text(.init(recipe.text))
                            .font(.system(size: 17, weight: .regular, design: .serif))
                            .foregroundStyle(AppTheme.ink)
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
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
