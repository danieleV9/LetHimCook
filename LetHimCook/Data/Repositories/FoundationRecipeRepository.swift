import Foundation

final class FoundationRecipeRepository: RecipeRepository {
    /// Upper bound for the reference recipe in the prompt, so it leaves enough
    /// of the model's context window for a detailed answer.
    private static let maxReferenceLength = 900

    private let modelManager: FoundationModelManager

    init(modelManager: FoundationModelManager = .shared) {
        self.modelManager = modelManager
    }

    func recipeStream(for ingredients: [String], reference: LibraryRecipe?) -> AsyncThrowingStream<Recipe, Error> {
        modelManager.streamRecipe(prompt: Self.prompt(for: ingredients, reference: reference))
    }

    func prewarm() {
        modelManager.prewarm()
    }

    static func prompt(for ingredients: [String], reference: LibraryRecipe?) -> String {
        let ingredientsList = ingredients.joined(separator: ", ")
        guard let reference else {
            return String(format: String(localized: "recipe_prompt_format"), ingredientsList)
        }
        return String(
            format: String(localized: "recipe_prompt_with_reference_format"),
            ingredientsList,
            compactText(of: reference)
        )
    }

    /// The reference recipe as compact plain text: title, ingredients on one
    /// line, numbered steps, cut to `maxReferenceLength`.
    static func compactText(of recipe: LibraryRecipe) -> String {
        let ingredients = recipe.ingredients
            .map { ingredient in
                [ingredient.quantity, ingredient.unit, ingredient.name]
                    .compactMap { $0 }
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
            }
            .joined(separator: ", ")
        let steps = recipe.steps.enumerated()
            .map { index, step in "\(index + 1). \(step.instruction)" }
            .joined(separator: "\n")
        let text = "\(recipe.title)\n\(ingredients)\n\(steps)"
        return text.count > maxReferenceLength ? String(text.prefix(maxReferenceLength)) + "…" : text
    }
}
