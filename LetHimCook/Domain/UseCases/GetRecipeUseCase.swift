import Foundation

protocol GetRecipeUseCase {
    func execute(with ingredients: [String]) async throws -> Recipe
}

struct GetRecipeUseCaseImpl: GetRecipeUseCase {
    let repository: RecipeRepository

    func execute(with ingredients: [String]) async throws -> Recipe {
        try await repository.fetchRecipe(for: ingredients)
    }
}
