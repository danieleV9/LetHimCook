import Foundation
import SwiftUI
import ActorDI

@Observable
final class MyRecipesViewModel {
    private var getSavedRecipesUseCase: GetSavedRecipesUseCase?
    private var deleteSavedRecipesUseCase: DeleteSavedRecipesUseCase?
    private var logger: Logger?
    private(set) var recipes: [Recipe] = []

    
    init() {
        Task { [weak self] in
            self?.getSavedRecipesUseCase = try? await AppContainer.container.resolve(GetSavedRecipesUseCase.self)
            self?.deleteSavedRecipesUseCase = try? await AppContainer.container.resolve(DeleteSavedRecipesUseCase.self)
            self?.logger = try? await AppContainer.container.resolve(Logger.self)
            await self?.loadRecipes()
        }
    }

    func loadRecipes() async {
        guard let getSavedRecipesUseCase else { return }
        let result = await getSavedRecipesUseCase.execute()
        logger?.debug("Retrieved \(result.count) recipes")
        recipes = result
    }

    func deleteAllRecipes() async {
        guard let deleteSavedRecipesUseCase else { return }
        await deleteSavedRecipesUseCase.execute()
        recipes.removeAll()
        logger?.debug("Deleted all saved recipes")
    }
}
