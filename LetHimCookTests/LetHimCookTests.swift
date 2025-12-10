//
//  LetHimCookTests.swift
//  LetHimCookTests
//
//  Created by Daniele Valentino on 13/07/25.
//

import Testing
import SwiftUI
import ActorDI
@testable import LetHimCook

struct LetHimCookTests {

    @Test func getRecipeUseCaseDelegatesToRepository() async throws {
        let repository = MockRecipeRepository()
        let useCase = GetRecipeUseCaseImpl(repository: repository)
        let ingredients = ["tomato", "basil"]

        let recipe = try await useCase.execute(with: ingredients)

        #expect(repository.receivedIngredients == ingredients)
        #expect(recipe.text == MockRecipeRepository.mockText)
    }

    @Test func saveRecipeUseCasePersistsRecipe() async {
        let repository = MockSavedRecipeRepository()
        let useCase = SaveRecipeUseCaseImpl(repository: repository)
        let recipe = Recipe(text: "Tasty soup")

        await useCase.execute(recipe: recipe)

        #expect(repository.savedRecipes.contains(where: { $0.text == recipe.text }))
    }

    @Test func ingredientInputViewModelAddsTrimmedIngredient() async {
        var ingredients: [String] = []
        let binding = Binding(get: { ingredients }, set: { ingredients = $0 })
        let viewModel = IngredientInputViewModel(ingredients: binding)

        viewModel.currentInput = "  Tomato "
        viewModel.addIngredient()

        #expect(ingredients == ["Tomato"])
        #expect(viewModel.currentInput.isEmpty)
    }

    @Test func ingredientInputViewModelIgnoresWhitespace() async {
        var ingredients: [String] = []
        let binding = Binding(get: { ingredients }, set: { ingredients = $0 })
        let viewModel = IngredientInputViewModel(ingredients: binding)

        viewModel.currentInput = "   "
        viewModel.addIngredient()

        #expect(ingredients.isEmpty)
    }

    @MainActor
    @Test func recipeViewModelLoadsRecipeAndSavesIt() async throws {
        let container = DIContainer()
        AppContainer.container = container
        let getUseCase = MockGetRecipeUseCase()
        let saveUseCase = MockSaveRecipeUseCase()
        let logger = MockLogger()

        await container.register(GetRecipeUseCase.self, scope: .singleton) { getUseCase }
        await container.register(SaveRecipeUseCase.self, scope: .singleton) { saveUseCase }
        await container.register(Logger.self, scope: .singleton) { logger }

        let viewModel = RecipeViewModel(ingredients: ["pasta", "tomato"])
        await viewModel.loadRecipe()

        guard case .success(let text) = viewModel.state else {
            Issue.record("RecipeViewModel did not reach success state")
            return
        }

        #expect(text == MockGetRecipeUseCase.text)
        #expect(saveUseCase.savedRecipes.contains(where: { $0.text == MockGetRecipeUseCase.text }))
    }

    @MainActor
    @Test func recipeViewModelDoesNotLoadWithEmptyIngredients() async {
        let container = DIContainer()
        AppContainer.container = container
        let getUseCase = MockGetRecipeUseCase()
        let saveUseCase = MockSaveRecipeUseCase()

        await container.register(GetRecipeUseCase.self, scope: .singleton) { getUseCase }
        await container.register(SaveRecipeUseCase.self, scope: .singleton) { saveUseCase }

        let viewModel = RecipeViewModel(ingredients: [])
        await viewModel.loadRecipe()

        if case .idle = viewModel.state {
            #expect(true)
        } else {
            #expect(false)
        }
        #expect(saveUseCase.savedRecipes.isEmpty)
    }
}

// MARK: - Mocks

final class MockRecipeRepository: RecipeRepository, @unchecked Sendable {
    static let mockText = "Mock recipe text"
    var receivedIngredients: [String] = []

    func fetchRecipe(for ingredients: [String]) async throws -> Recipe {
        receivedIngredients = ingredients
        return Recipe(text: Self.mockText)
    }
}

final class MockSavedRecipeRepository: SavedRecipeRepository, @unchecked Sendable {
    private(set) var savedRecipes: [Recipe] = []

    func fetchRecipes() async -> [Recipe] {
        savedRecipes
    }

    func save(recipe: Recipe) async {
        savedRecipes.append(recipe)
    }

    func deleteAll() async {
        savedRecipes.removeAll()
    }
}

final class MockGetRecipeUseCase: GetRecipeUseCase, @unchecked Sendable {
    static let text = "Delicious recipe"
    func execute(with ingredients: [String]) async throws -> Recipe {
        Recipe(text: Self.text)
    }
}

final class MockSaveRecipeUseCase: SaveRecipeUseCase, @unchecked Sendable {
    private(set) var savedRecipes: [Recipe] = []

    func execute(recipe: Recipe) async {
        savedRecipes.append(recipe)
    }
}

final class MockLogger: Logger {
    func debug(_ message: String) {}
    func info(_ message: String) {}
    func warning(_ message: String) {}
    func error(_ message: String) {}
}
