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
    
    static var container: DIContainer = DIContainer()

    static func configure() async {

        let logger = ConsoleLogger()
        let modelManager = FoundationModelManager.shared
        let repository = FoundationRecipeRepository(modelManager: modelManager)
        let useCase = GetRecipeUseCaseImpl(repository: repository)

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

    }
}
