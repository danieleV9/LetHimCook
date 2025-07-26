import SwiftUI

struct RecipeView: View {
    var ingredients: [String]

    @State private var recipe: String?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recipe")
                .font(.largeTitle)
                .bold()
                .padding(.top)
            Divider()

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else if let recipe {
                ScrollView {
                    Text(.init(recipe))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom)
                }
            } else if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            } else {
                Text("Welcome! Your recipe will appear here.")
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .task {
            guard !ingredients.isEmpty else { return }
            errorMessage = nil
            isLoading = true
            let prompt = "Sei un esperto di cucina. Suggerisci una ricetta (già esistente o nuova) usando questi ingredienti: \(ingredients.joined(separator: ", "))"
            do {
                recipe = try await FoundationModelManager.shared.predict(input: prompt)
            } catch {
                errorMessage = "Failed to load recipe."
                recipe = nil
            }
            isLoading = false
        }
    }
}

#Preview {
    RecipeView(ingredients: ["Eggs", "Milk", "Flour"])
}
