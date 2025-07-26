import Foundation

final class UserDefaultsSavedRecipesRepository: SavedRecipeRepository {
    private let userDefaults: UserDefaults
    private let key = "saved_recipes"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func fetchRecipes() async -> [Recipe] {
        guard
            let data = userDefaults.data(forKey: key),
            let recipes = try? JSONDecoder().decode([Recipe].self, from: data)
        else {
            return []
        }
        return recipes
    }

    func save(recipe: Recipe) async {
        var recipes = await fetchRecipes()
        recipes.append(recipe)
        if let data = try? JSONEncoder().encode(recipes) {
            userDefaults.set(data, forKey: key)
        }
    }
}
