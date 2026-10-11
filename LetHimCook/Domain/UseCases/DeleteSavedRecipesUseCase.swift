import Foundation

protocol DeleteSavedRecipesUseCase {
    func execute() async
}

struct DeleteSavedRecipesUseCaseImpl: DeleteSavedRecipesUseCase {
    let repository: SavedRecipeRepository

    func execute() async {
        await repository.deleteAll()
    }
}
