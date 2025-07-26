import Foundation

protocol RecipeRepository {
    func fetchRecipe(for ingredients: [String]) async throws -> Recipe
}
