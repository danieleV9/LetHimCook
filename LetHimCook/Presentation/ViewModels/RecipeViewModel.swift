import Foundation
import SwiftUI
import Observation
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

    @ObservationIgnored @Inject private var getRecipeUseCase: GetRecipeUseCase?
    @ObservationIgnored @Inject private var saveRecipeUseCase: SaveRecipeUseCase?
    @ObservationIgnored @Inject private var logger: Logger?
    private(set) var state: State = .idle
    private let ingredients: [String]

    init(ingredients: [String]) {
        self.ingredients = ingredients
        Task { [weak self] in
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
            logger?.debug("The saved recipe is: \(recipe)")
            await saveRecipeUseCase?.execute(recipe: recipe)
        } catch {
            state = .failure(String(localized: "recipe_error_message"))
        }
    }
}
