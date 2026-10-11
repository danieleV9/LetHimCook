import Foundation

protocol RecipeLibraryRepository {
    /// The library recipes written in the app's current language.
    func recipes() async -> [LibraryRecipe]
}
