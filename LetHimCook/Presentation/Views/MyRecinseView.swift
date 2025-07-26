import SwiftUI

struct MyRecipeView: View {
    @Bindable var viewModel = MyRecipesViewModel()

    var body: some View {
        NavigationStack {
            List(viewModel.recipes.indices, id: \.self) { index in
                Text(.init(viewModel.recipes[index].text))
                    .lineLimit(2)
            }
            .navigationTitle("My Recipes")
        }
        .task {
            await viewModel.loadRecipes()
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
