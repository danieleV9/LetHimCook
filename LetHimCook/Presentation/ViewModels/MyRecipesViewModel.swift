import Foundation
import SwiftUI
import Observation
import ActorDI

@Observable
final class MyRecipesViewModel {
    @ObservationIgnored @Inject private var getSavedRecipesUseCase: GetSavedRecipesUseCase?
    @ObservationIgnored @Inject private var deleteSavedRecipesUseCase: DeleteSavedRecipesUseCase?
    @ObservationIgnored @Inject private var logger: Logger?
    private(set) var recipes: [Recipe] = []


    init() {
        Task { [weak self] in
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
