import Foundation

protocol RecipeRepository {
    /// Streams a recipe for the given ingredients, emitting progressively
    /// more complete snapshots until generation finishes.
    func recipeStream(for ingredients: [String]) -> AsyncThrowingStream<Recipe, Error>

    /// Warms up the underlying model ahead of a request.
    func prewarm()
}
