import Foundation
import SwiftUI
import ActorDI

@Observable
@MainActor
final class RecipeViewModel {
    enum State {
        case idle
        case loading
        case success(String)
        case failure(String)
    }

    private var getRecipeUseCase: GetRecipeUseCase?
    private var saveRecipeUseCase: SaveRecipeUseCase?
    private(set) var state: State = .idle
    private let ingredients: [String]

    init(ingredients: [String]) {
        self.ingredients = ingredients
        Task { [weak self] in
            self?.getRecipeUseCase = try? await AppContainer.container.resolve(GetRecipeUseCase.self)
            self?.saveRecipeUseCase = try? await AppContainer.container.resolve(SaveRecipeUseCase.self)
            await self?.loadRecipe()
        }
    }

    func loadRecipe() async {
        guard let getRecipeUseCase else { return }
        guard !ingredients.isEmpty else { return }
        state = .loading
        do {
            let recipe = try await getRecipeUseCase.execute(with: ingredients)
            state = .success(recipe.text)
            await saveRecipeUseCase?.execute(recipe: recipe)
        } catch {
            state = .failure("Failed to load recipe.")
        }
    }
}
