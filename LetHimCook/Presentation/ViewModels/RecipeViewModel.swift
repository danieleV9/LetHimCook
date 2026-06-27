import Foundation

@Observable
@MainActor
final class RecipeViewModel {
    enum State {
        case idle
        case loading
        case success(String)
        case failure(String)
    }

    private let ingredients: [String]
    private let getRecipeUseCase: GetRecipeUseCase
    private let saveRecipeUseCase: SaveRecipeUseCase
    private let logger: Logger?
    private(set) var state: State = .idle

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
            let recipe = try await getRecipeUseCase.execute(with: ingredients)
            state = .success(recipe.text)
            logger?.debug("The saved recipe is: \(recipe)")
            await saveRecipeUseCase.execute(recipe: recipe)
        } catch {
            let localizedError = error as? LocalizedError
            let message = localizedError?.errorDescription ?? localizedError?.localizedDescription ?? String(localized: "recipe_error_message")
            state = .failure(message)
        }
    }
}
