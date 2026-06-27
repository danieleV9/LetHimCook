import Foundation

final class FoundationRecipeRepository: RecipeRepository {
    private let modelManager: FoundationModelManager

    init(modelManager: FoundationModelManager = .shared) {
        self.modelManager = modelManager
    }

    func recipeStream(for ingredients: [String]) -> AsyncThrowingStream<Recipe, Error> {
        let ingredientsList = ingredients.joined(separator: ", ")
        let promptFormat = String(localized: "recipe_prompt_format")
        let prompt = String(format: promptFormat, ingredientsList)
        return modelManager.streamRecipe(prompt: prompt)
    }

    func prewarm() {
        modelManager.prewarm()
    }
}
