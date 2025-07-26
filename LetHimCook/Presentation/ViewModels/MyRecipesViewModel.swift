import Foundation
import SwiftUI
import ActorDI

@Observable
@MainActor
final class MyRecipesViewModel {
    private var getSavedRecipesUseCase: GetSavedRecipesUseCase?
    private(set) var recipes: [Recipe] = []

    init() {
        Task { [weak self] in
            self?.getSavedRecipesUseCase = try? await AppContainer.container.resolve(GetSavedRecipesUseCase.self)
            await self?.loadRecipes()
        }
    }

    func loadRecipes() async {
        guard let getSavedRecipesUseCase else { return }
        recipes = await getSavedRecipesUseCase.execute()
    }
}
