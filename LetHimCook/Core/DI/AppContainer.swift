//
//  AppContainer.swift
//  LetHimCook
//
//  Created by Daniele Valentino on 26/07/25.
//

import Foundation
import SwiftUI
import ActorDI

enum AppContainer {
    
    static var container: DIContainer = DIContainer.shared

    static func configure() async {

        let logger = ConsoleLogger()
        let modelManager = FoundationModelManager.shared
        let repository = FoundationRecipeRepository(modelManager: modelManager)
        let useCase = GetRecipeUseCaseImpl(repository: repository)

        let savedRecipesRepository = CoreDataSavedRecipesRepository()
        let saveUseCase = SaveRecipeUseCaseImpl(repository: savedRecipesRepository)
        let getSavedUseCase = GetSavedRecipesUseCaseImpl(repository: savedRecipesRepository)
        let deleteSavedUseCase = DeleteSavedRecipesUseCaseImpl(repository: savedRecipesRepository)

        await container.register(Logger.self, scope: .singleton) {
            logger
        }

        await container.register(FoundationModelManager.self, scope: .singleton) {
            modelManager
        }

        await container.register(RecipeRepository.self, scope: .singleton) {
            repository
        }

        await container.register(GetRecipeUseCase.self, scope: .singleton) {
            useCase
        }

        await container.register(SavedRecipeRepository.self, scope: .singleton) {
            savedRecipesRepository
        }

        await container.register(SaveRecipeUseCase.self, scope: .singleton) {
            saveUseCase
        }

        await container.register(GetSavedRecipesUseCase.self, scope: .singleton) {
            getSavedUseCase
        }

        await container.register(DeleteSavedRecipesUseCase.self, scope: .singleton) {
            deleteSavedUseCase
        }

    }
}
