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
                    Label("Back", systemImage: "chevron.backward")
                }
                .labelStyle(.titleAndIcon)
            }
            Text("Recipe")
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
                Text("Welcome! Your recipe will appear here.")
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
