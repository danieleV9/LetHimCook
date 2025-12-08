import Foundation
import SwiftUI
import ActorDI

@Observable
final class MyRecipesViewModel {
    private var getSavedRecipesUseCase: GetSavedRecipesUseCase?
    private var deleteSavedRecipesUseCase: DeleteSavedRecipesUseCase?
    private var logger: Logger?
    private(set) var recipes: [Recipe] = []

    func loadRecipes() async {
        self.getSavedRecipesUseCase = try? await AppContainer.container.resolve(GetSavedRecipesUseCase.self)
        guard let getSavedRecipesUseCase else { return }
        let result = await getSavedRecipesUseCase.execute()
        self.logger = try? await AppContainer.container.resolve(Logger.self)
        logger?.debug("Retrieved \(result.count) recipes")
        recipes = result
    }

    func deleteAllRecipes() async {
        self.deleteSavedRecipesUseCase = try? await AppContainer.container.resolve(DeleteSavedRecipesUseCase.self)
        guard let deleteSavedRecipesUseCase else { return }
        await deleteSavedRecipesUseCase.execute()
        recipes.removeAll()
        self.logger = try? await AppContainer.container.resolve(Logger.self)
        logger?.debug("Deleted all saved recipes")
    }
}
