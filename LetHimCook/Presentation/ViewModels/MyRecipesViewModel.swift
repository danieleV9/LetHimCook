import Foundation
import SwiftUI
import ActorDI

@Observable
@MainActor
final class MyRecipesViewModel {
    private var getSavedRecipesUseCase: GetSavedRecipesUseCase?
    private var logger: Logger?
    private(set) var recipes: [Recipe] = []

    @MainActor
    init() {
        Task { [weak self] in
            self?.getSavedRecipesUseCase = try? await AppContainer.container.resolve(GetSavedRecipesUseCase.self)
            self?.logger = try? await AppContainer.container.resolve(Logger.self)
            await self?.loadRecipes()
        }
    }

    @MainActor
    func loadRecipes() async {
        guard let getSavedRecipesUseCase else { return }
        let result = await getSavedRecipesUseCase.execute()
        logger?.debug("Retrieved \(result.count) recipes")
        recipes = result
    }
}
