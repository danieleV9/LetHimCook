import Foundation

protocol DeleteSavedRecipesUseCase {
    func execute() async
}

final class DeleteSavedRecipesUseCaseImpl: DeleteSavedRecipesUseCase {
    private let repository: SavedRecipeRepository

    init(repository: SavedRecipeRepository) {
        self.repository = repository
    }

    func execute() async {
        await repository.deleteAll()
    }
}
