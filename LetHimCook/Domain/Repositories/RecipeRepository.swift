import Foundation

protocol RecipeRepository {
    /// Streams a recipe for the given ingredients, emitting progressively
    /// more complete snapshots until generation finishes.
    ///
    /// - Parameter reference: A library recipe to adapt to the ingredients,
    ///   or nil to write one from scratch.
    func recipeStream(for ingredients: [String], reference: LibraryRecipe?) -> AsyncThrowingStream<Recipe, Error>

    /// Warms up the underlying model ahead of a request.
    func prewarm()
}
