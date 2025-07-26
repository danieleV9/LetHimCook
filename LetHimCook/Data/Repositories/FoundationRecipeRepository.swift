import Foundation

final class FoundationRecipeRepository: RecipeRepository {
    private let modelManager: FoundationModelManager

    init(modelManager: FoundationModelManager = .shared) {
        self.modelManager = modelManager
    }

    func fetchRecipe(for ingredients: [String]) async throws -> Recipe {
        let prompt = "Sei un esperto di cucina. Suggerisci una ricetta (esistente o nuova) usando questi ingredienti: \(ingredients.joined(separator: ", "))"
        let text = try await modelManager.predict(input: prompt)
        return Recipe(text: text)
    }
}
