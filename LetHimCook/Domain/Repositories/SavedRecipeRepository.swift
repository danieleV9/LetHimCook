import Foundation

protocol SavedRecipeRepository {
    func fetchRecipes() async -> [Recipe]
    func save(recipe: Recipe) async
}
