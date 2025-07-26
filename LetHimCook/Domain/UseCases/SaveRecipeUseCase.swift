import Foundation

protocol SaveRecipeUseCase {
    func execute(recipe: Recipe) async
}

struct SaveRecipeUseCaseImpl: SaveRecipeUseCase {
    let repository: SavedRecipeRepository

    func execute(recipe: Recipe) async {
        await repository.save(recipe: recipe)
    }
}
