import Foundation

@Observable
@MainActor
final class MyRecipesViewModel {
    private let getSavedRecipesUseCase: GetSavedRecipesUseCase
    private let deleteSavedRecipesUseCase: DeleteSavedRecipesUseCase
    private let logger: Logger?
    private(set) var recipes: [Recipe] = []

    init(
        getSavedRecipesUseCase: GetSavedRecipesUseCase,
        deleteSavedRecipesUseCase: DeleteSavedRecipesUseCase,
        logger: Logger? = nil
    ) {
        self.getSavedRecipesUseCase = getSavedRecipesUseCase
        self.deleteSavedRecipesUseCase = deleteSavedRecipesUseCase
        self.logger = logger
    }

    func loadRecipes() async {
        let result = await getSavedRecipesUseCase.execute()
        logger?.debug("Retrieved \(result.count) recipes")
        recipes = result
    }

    func deleteAllRecipes() async {
        await deleteSavedRecipesUseCase.execute()
        recipes.removeAll()
        logger?.debug("Deleted all saved recipes")
    }
}
