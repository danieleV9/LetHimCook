//
//  AppContainer.swift
//  LetHimCook
//
//  Created by Daniele Valentino on 26/07/25.
//

import Foundation
import SwiftUI
import ActorDI

// MARK: - ViewModelFactory

/// Builds view models with their dependencies already injected.
///
/// The Presentation layer depends only on this abstraction: it never reaches into
/// the DI container itself. Dependencies are resolved once, at the composition root,
/// and injected inward — respecting the Clean Architecture dependency rule.
@MainActor
protocol ViewModelFactory {
    func makeIngredientInputViewModel(ingredients: Binding<[String]>) -> IngredientInputViewModel
    func makeRecipeViewModel(ingredients: [String]) -> RecipeViewModel
    func makeMyRecipesViewModel() -> MyRecipesViewModel
}

/// Default factory that injects the app's use cases into each view model.
@MainActor
final class AppViewModelFactory: ViewModelFactory {
    private let getRecipeUseCase: GetRecipeUseCase
    private let saveRecipeUseCase: SaveRecipeUseCase
    private let getSavedRecipesUseCase: GetSavedRecipesUseCase
    private let deleteSavedRecipesUseCase: DeleteSavedRecipesUseCase
    private let logger: Logger

    init(
        getRecipeUseCase: GetRecipeUseCase,
        saveRecipeUseCase: SaveRecipeUseCase,
        getSavedRecipesUseCase: GetSavedRecipesUseCase,
        deleteSavedRecipesUseCase: DeleteSavedRecipesUseCase,
        logger: Logger
    ) {
        self.getRecipeUseCase = getRecipeUseCase
        self.saveRecipeUseCase = saveRecipeUseCase
        self.getSavedRecipesUseCase = getSavedRecipesUseCase
        self.deleteSavedRecipesUseCase = deleteSavedRecipesUseCase
        self.logger = logger
    }

    func makeIngredientInputViewModel(ingredients: Binding<[String]>) -> IngredientInputViewModel {
        IngredientInputViewModel(ingredients: ingredients, logger: logger)
    }

    func makeRecipeViewModel(ingredients: [String]) -> RecipeViewModel {
        RecipeViewModel(
            ingredients: ingredients,
            getRecipeUseCase: getRecipeUseCase,
            saveRecipeUseCase: saveRecipeUseCase,
            logger: logger
        )
    }

    func makeMyRecipesViewModel() -> MyRecipesViewModel {
        MyRecipesViewModel(
            getSavedRecipesUseCase: getSavedRecipesUseCase,
            deleteSavedRecipesUseCase: deleteSavedRecipesUseCase,
            logger: logger
        )
    }
}

// MARK: - Composition Root

enum AppContainer {

    static let container: DIContainer = DIContainer.shared

    /// Wires the dependency graph and returns the factory used to build view models.
    ///
    /// This is the only place that talks to the DI container: dependencies are
    /// registered and then resolved once to populate the factory.
    @MainActor
    static func makeViewModelFactory() async -> ViewModelFactory {

        let logger = ConsoleLogger()
        let recipeRepository = FoundationRecipeRepository(modelManager: .shared)
        let savedRecipesRepository = CoreDataSavedRecipesRepository()

        await container.register(Logger.self, scope: .singleton) { logger }
        await container.register(RecipeRepository.self, scope: .singleton) { recipeRepository }
        await container.register(SavedRecipeRepository.self, scope: .singleton) { savedRecipesRepository }
        await container.register(GetRecipeUseCase.self, scope: .singleton) {
            GetRecipeUseCaseImpl(repository: recipeRepository)
        }
        await container.register(SaveRecipeUseCase.self, scope: .singleton) {
            SaveRecipeUseCaseImpl(repository: savedRecipesRepository)
        }
        await container.register(GetSavedRecipesUseCase.self, scope: .singleton) {
            GetSavedRecipesUseCaseImpl(repository: savedRecipesRepository)
        }
        await container.register(DeleteSavedRecipesUseCase.self, scope: .singleton) {
            DeleteSavedRecipesUseCaseImpl(repository: savedRecipesRepository)
        }

        // A failed resolution here means the graph above is misconfigured: that is a
        // programmer error and should crash loudly, not fail silently in the UI.
        let getRecipeUseCase = try! await container.resolve(GetRecipeUseCase.self)
        let saveRecipeUseCase = try! await container.resolve(SaveRecipeUseCase.self)
        let getSavedRecipesUseCase = try! await container.resolve(GetSavedRecipesUseCase.self)
        let deleteSavedRecipesUseCase = try! await container.resolve(DeleteSavedRecipesUseCase.self)
        let resolvedLogger = try! await container.resolve(Logger.self)

        return AppViewModelFactory(
            getRecipeUseCase: getRecipeUseCase,
            saveRecipeUseCase: saveRecipeUseCase,
            getSavedRecipesUseCase: getSavedRecipesUseCase,
            deleteSavedRecipesUseCase: deleteSavedRecipesUseCase,
            logger: resolvedLogger
        )
    }
}

#if DEBUG
extension AppViewModelFactory {
    /// A factory wired with in-memory persistence for SwiftUI previews.
    @MainActor
    static var preview: AppViewModelFactory {
        let savedRecipesRepository = CoreDataSavedRecipesRepository(container: PersistenceController.preview.container)
        let recipeRepository = FoundationRecipeRepository()
        return AppViewModelFactory(
            getRecipeUseCase: GetRecipeUseCaseImpl(repository: recipeRepository),
            saveRecipeUseCase: SaveRecipeUseCaseImpl(repository: savedRecipesRepository),
            getSavedRecipesUseCase: GetSavedRecipesUseCaseImpl(repository: savedRecipesRepository),
            deleteSavedRecipesUseCase: DeleteSavedRecipesUseCaseImpl(repository: savedRecipesRepository),
            logger: ConsoleLogger()
        )
    }
}
#endif
