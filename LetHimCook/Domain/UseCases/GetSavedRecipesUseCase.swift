import Foundation

protocol GetSavedRecipesUseCase {
    func execute() async -> [Recipe]
}

struct GetSavedRecipesUseCaseImpl: GetSavedRecipesUseCase {
    let repository: SavedRecipeRepository

    func execute() async -> [Recipe] {
        await repository.fetchRecipes()
    }
}
