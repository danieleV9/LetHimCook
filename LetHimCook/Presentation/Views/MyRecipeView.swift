import SwiftUI

struct MyRecipeView: View {
    @Bindable var viewModel = MyRecipesViewModel()
    @State private var selectedRecipe: Recipe? = nil

    var body: some View {
        NavigationStack {
            List(viewModel.recipes.indices, id: \.self) { index in
                Button {
                    selectedRecipe = viewModel.recipes[index]
                } label: {
                    Text(.init(viewModel.recipes[index].text))
                        .lineLimit(2)
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("My Recipes")
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
