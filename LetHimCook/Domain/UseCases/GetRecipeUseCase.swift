import Foundation

protocol GetRecipeUseCase {
    func execute(with ingredients: [String]) -> AsyncThrowingStream<Recipe, Error>
    func prewarm()
}

struct GetRecipeUseCaseImpl: GetRecipeUseCase {
    let repository: RecipeRepository

    func execute(with ingredients: [String]) -> AsyncThrowingStream<Recipe, Error> {
        repository.recipeStream(for: ingredients)
    }

    func prewarm() {
        repository.prewarm()
    }
}
