import SwiftUI

struct MyRecipeView: View {
    @Bindable var viewModel = MyRecipesViewModel()
    @State private var selectedRecipe: Recipe? = nil

    var body: some View {
        NavigationStack {
            List(viewModel.recipes) { recipe in
                Button {
                    selectedRecipe = recipe
                } label: {
                    Text(.init(recipe.text))
                        .lineLimit(2)
                }
                .buttonStyle(.plain)
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
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(.init(recipe.text))
                            .padding()
                    }
                }
                .presentationDetents([.medium, .large])
            }
        }
        .onAppear {
            Task {
                await viewModel.loadRecipes()
            }
        }
    }
}

#Preview {
    MyRecipeView()
}
