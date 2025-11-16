import SwiftUI

struct RecipeView: View {
    @Bindable var viewModel: RecipeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Label("recipe_back_button", systemImage: "chevron.backward")
                }
                .labelStyle(.titleAndIcon)
            }
            Text("recipe_title")
                .font(.largeTitle)
                .bold()
                .padding(.top)
            Divider()

            if case .loading = viewModel.state {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else if case let .success(recipe) = viewModel.state {
                ScrollView {
                    Text(.init(recipe))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom)
                }
            } else if case let .failure(message) = viewModel.state {
                Text(message)
                    .foregroundColor(.red)
            } else {
                Text("recipe_placeholder")
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .task {
            await viewModel.loadRecipe()
        }
    }
}

#Preview {
    RecipeView(viewModel: RecipeViewModel(ingredients: ["Eggs", "Milk", "Flour"]))
}
