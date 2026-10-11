import Foundation

protocol GetRecipeUseCase {
    func execute(with ingredients: [String]) -> AsyncThrowingStream<Recipe, Error>
    func prewarm()
}

/// Looks for a fitting recipe in the local library before generating one:
/// an exact match is returned as it is, a close one is adapted to the
/// ingredients, otherwise a new recipe is written from scratch.
struct GetRecipeUseCaseImpl: GetRecipeUseCase {
    let repository: RecipeRepository
    var library: RecipeLibraryRepository?
    var matcher = RecipeMatcher()

    func execute(with ingredients: [String]) -> AsyncThrowingStream<Recipe, Error> {
        let repository = repository
        let library = library
        let matcher = matcher

        return AsyncThrowingStream { continuation in
            let task = Task {
                let candidates = await library?.recipes() ?? []

                let reference: LibraryRecipe?
                switch matcher.bestMatch(for: ingredients, in: candidates) {
                case .exact(let recipe):
                    continuation.yield(recipe.toRecipe())
                    continuation.finish()
                    return
                case .reference(let recipe):
                    reference = recipe
                case .noMatch:
                    reference = nil
                }

                let origin: RecipeOrigin = reference.map { .adapted(fromTitle: $0.title) } ?? .generated
                do {
                    for try await snapshot in repository.recipeStream(for: ingredients, reference: reference) {
                        try Task.checkCancellation()
                        continuation.yield(snapshot.with(origin: origin))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func prewarm() {
        repository.prewarm()
    }
}
