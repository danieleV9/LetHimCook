import SwiftUI

struct MyRecinseView: View {
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
    }
}

#Preview {
    MyRecinseView()
}
