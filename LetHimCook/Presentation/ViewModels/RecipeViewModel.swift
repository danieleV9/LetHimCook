import Foundation

@Observable
@MainActor
final class RecipeViewModel {
    enum State {
        case idle
        case loading
        case streaming(Recipe)
        case success(Recipe)
        case failure(String)
    }

    private let ingredients: [String]
    private let getRecipeUseCase: GetRecipeUseCase
    private let saveRecipeUseCase: SaveRecipeUseCase
    private let logger: Logger?
    private(set) var state: State = .idle
    /// Assigned up front so the recipe keeps one identity (and one artwork)
    /// from the first loading frame through to the saved copy.
    let recipeID = UUID()

    init(
        ingredients: [String],
        getRecipeUseCase: GetRecipeUseCase,
        saveRecipeUseCase: SaveRecipeUseCase,
        logger: Logger? = nil
    ) {
        self.ingredients = ingredients
        self.getRecipeUseCase = getRecipeUseCase
        self.saveRecipeUseCase = saveRecipeUseCase
        self.logger = logger
    }

    func loadRecipe() async {
        guard !ingredients.isEmpty else { return }
        state = .loading
        do {
            var lastRecipe: Recipe?
            for try await snapshot in getRecipeUseCase.execute(with: ingredients) {
                let recipe = snapshot.with(id: recipeID)
                lastRecipe = recipe
                state = .streaming(recipe)
            }

            guard let recipe = lastRecipe, !recipe.title.isEmpty || !recipe.steps.isEmpty else {
                state = .failure(String(localized: "foundation_model_error_empty_response"))
                return
            }

            state = .success(recipe)
            logger?.debug("Generated recipe: \(recipe.title)")
            await saveRecipeUseCase.execute(recipe: recipe)
        } catch {
            let localizedError = error as? LocalizedError
            let message = localizedError?.errorDescription
                ?? localizedError?.localizedDescription
                ?? String(localized: "recipe_error_message")
            state = .failure(message)
        }
    }
}
