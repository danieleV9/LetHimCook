import Foundation

final class FoundationRecipeRepository: RecipeRepository {
    private let modelManager: FoundationModelManager

    init(modelManager: FoundationModelManager = .shared) {
        self.modelManager = modelManager
    }

    func fetchRecipe(for ingredients: [String]) async throws -> Recipe {
        let ingredientsList = ingredients.joined(separator: ", ")
        let promptFormat = String(localized: "recipe_prompt_format")
        let prompt = String(format: promptFormat, ingredientsList)
        let text = try await modelManager.predict(input: prompt)
        return Recipe(text: text)
    }
}
