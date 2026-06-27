//
//  LetHimCookTests.swift
//  LetHimCookTests
//
//  Created by Daniele Valentino on 13/07/25.
//

import Testing
import SwiftUI
@testable import LetHimCook

// MARK: - Test Doubles

/// A configurable stub/spy for `RecipeRepository`.
final class MockRecipeRepository: RecipeRepository {
    enum MockError: Error { case failed }

    var result: Result<Recipe, Error>
    private(set) var receivedIngredients: [String]?

    init(result: Result<Recipe, Error> = .success(Recipe(text: "Mock recipe"))) {
        self.result = result
    }

    func fetchRecipe(for ingredients: [String]) async throws -> Recipe {
        receivedIngredients = ingredients
        return try result.get()
    }
}

/// An in-memory spy for `SavedRecipeRepository`.
final class MockSavedRecipeRepository: SavedRecipeRepository {
    var storedRecipes: [Recipe]
    private(set) var saveCallCount = 0
    private(set) var deleteAllCallCount = 0

    init(storedRecipes: [Recipe] = []) {
        self.storedRecipes = storedRecipes
    }

    func fetchRecipes() async -> [Recipe] {
        storedRecipes
    }

    func save(recipe: Recipe) async {
        saveCallCount += 1
        storedRecipes.append(recipe)
    }

    func deleteAll() async {
        deleteAllCallCount += 1
        storedRecipes.removeAll()
    }
}

// MARK: - Entity

struct RecipeTests {

    @Test func idIsDerivedFromText() {
        let recipe = Recipe(text: "Carbonara")
        #expect(recipe.id == "Carbonara")
    }

    @Test func encodesAndDecodesWithoutLoss() throws {
        let original = Recipe(text: "Tiramisù")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Recipe.self, from: data)
        #expect(decoded.text == original.text)
        #expect(decoded.id == original.id)
    }
}

// MARK: - Use Cases

struct GetRecipeUseCaseTests {

    @Test func forwardsIngredientsAndReturnsRecipe() async throws {
        let repository = MockRecipeRepository(result: .success(Recipe(text: "Pancakes")))
        let useCase = GetRecipeUseCaseImpl(repository: repository)

        let recipe = try await useCase.execute(with: ["flour", "eggs"])

        #expect(recipe.text == "Pancakes")
        #expect(repository.receivedIngredients == ["flour", "eggs"])
    }

    @Test func propagatesRepositoryError() async {
        let repository = MockRecipeRepository(result: .failure(MockRecipeRepository.MockError.failed))
        let useCase = GetRecipeUseCaseImpl(repository: repository)

        await #expect(throws: MockRecipeRepository.MockError.self) {
            _ = try await useCase.execute(with: ["water"])
        }
    }
}

struct SaveRecipeUseCaseTests {

    @Test func savesRecipeToRepository() async {
        let repository = MockSavedRecipeRepository()
        let useCase = SaveRecipeUseCaseImpl(repository: repository)

        await useCase.execute(recipe: Recipe(text: "Minestrone"))

        #expect(repository.saveCallCount == 1)
        #expect(repository.storedRecipes.map(\.text) == ["Minestrone"])
    }
}

struct GetSavedRecipesUseCaseTests {

    @Test func returnsRecipesFromRepository() async {
        let repository = MockSavedRecipeRepository(storedRecipes: [Recipe(text: "A"), Recipe(text: "B")])
        let useCase = GetSavedRecipesUseCaseImpl(repository: repository)

        let result = await useCase.execute()

        #expect(result.map(\.text) == ["A", "B"])
    }
}

struct DeleteSavedRecipesUseCaseTests {

    @Test func deletesAllFromRepository() async {
        let repository = MockSavedRecipeRepository(storedRecipes: [Recipe(text: "A"), Recipe(text: "B")])
        let useCase = DeleteSavedRecipesUseCaseImpl(repository: repository)

        await useCase.execute()

        #expect(repository.deleteAllCallCount == 1)
        #expect(repository.storedRecipes.isEmpty)
    }
}

// MARK: - IngredientInputViewModel

@MainActor
struct IngredientInputViewModelTests {

    /// Captures the values pushed through the view model's change callback.
    final class ChangeRecorder {
        private(set) var lastValue: [String]?
        func record(_ value: [String]) { lastValue = value }
    }

    @Test func addIngredientAppendsTrimmedValueAndClearsInput() {
        let recorder = ChangeRecorder()
        let viewModel = IngredientInputViewModel(onIngredientsChange: recorder.record)

        viewModel.currentInput = "  Tomato  "
        viewModel.addIngredient()

        #expect(viewModel.ingredients == ["Tomato"])
        #expect(viewModel.currentInput == "")
        #expect(recorder.lastValue == ["Tomato"])
    }

    @Test func addIngredientIgnoresWhitespaceOnlyInput() {
        let viewModel = IngredientInputViewModel()

        viewModel.currentInput = "   "
        viewModel.addIngredient()

        #expect(viewModel.ingredients.isEmpty)
    }

    @Test func removeIngredientRemovesAtGivenOffsets() {
        let recorder = ChangeRecorder()
        let viewModel = IngredientInputViewModel(ingredients: ["A", "B", "C"], onIngredientsChange: recorder.record)

        viewModel.removeIngredient(at: IndexSet(integer: 1))

        #expect(viewModel.ingredients == ["A", "C"])
        #expect(recorder.lastValue == ["A", "C"])
    }

    @Test func resetClearsListAndInput() {
        let viewModel = IngredientInputViewModel(ingredients: ["A", "B"])
        viewModel.currentInput = "pending"

        viewModel.reset()

        #expect(viewModel.ingredients.isEmpty)
        #expect(viewModel.currentInput == "")
    }
}

// MARK: - RecipeViewModel
//
// Dependencies are injected directly through the initializer — no global
// container, no shared state, no test serialization required.

@MainActor
struct RecipeViewModelTests {

    @Test func loadsAndSavesOnSuccess() async {
        let recipeRepository = MockRecipeRepository(result: .success(Recipe(text: "Risotto")))
        let savedRepository = MockSavedRecipeRepository()
        let viewModel = RecipeViewModel(
            ingredients: ["rice"],
            getRecipeUseCase: GetRecipeUseCaseImpl(repository: recipeRepository),
            saveRecipeUseCase: SaveRecipeUseCaseImpl(repository: savedRepository)
        )

        await viewModel.loadRecipe()

        if case .success(let text) = viewModel.state {
            #expect(text == "Risotto")
        } else {
            Issue.record("Expected .success state, got \(viewModel.state)")
        }
        #expect(savedRepository.saveCallCount == 1)
    }

    @Test func entersFailureStateOnError() async {
        let recipeRepository = MockRecipeRepository(result: .failure(MockRecipeRepository.MockError.failed))
        let viewModel = RecipeViewModel(
            ingredients: ["rice"],
            getRecipeUseCase: GetRecipeUseCaseImpl(repository: recipeRepository),
            saveRecipeUseCase: SaveRecipeUseCaseImpl(repository: MockSavedRecipeRepository())
        )

        await viewModel.loadRecipe()

        if case .failure = viewModel.state {
            // expected
        } else {
            Issue.record("Expected .failure state, got \(viewModel.state)")
        }
    }

    @Test func staysIdleWithoutIngredients() async {
        let savedRepository = MockSavedRecipeRepository()
        let viewModel = RecipeViewModel(
            ingredients: [],
            getRecipeUseCase: GetRecipeUseCaseImpl(repository: MockRecipeRepository()),
            saveRecipeUseCase: SaveRecipeUseCaseImpl(repository: savedRepository)
        )

        await viewModel.loadRecipe()

        if case .idle = viewModel.state {
            // expected
        } else {
            Issue.record("Expected .idle state, got \(viewModel.state)")
        }
        #expect(savedRepository.saveCallCount == 0)
    }
}

// MARK: - MyRecipesViewModel

@MainActor
struct MyRecipesViewModelTests {

    @Test func loadsRecipes() async {
        let repository = MockSavedRecipeRepository(storedRecipes: [Recipe(text: "A"), Recipe(text: "B")])
        let viewModel = MyRecipesViewModel(
            getSavedRecipesUseCase: GetSavedRecipesUseCaseImpl(repository: repository),
            deleteSavedRecipesUseCase: DeleteSavedRecipesUseCaseImpl(repository: repository)
        )

        await viewModel.loadRecipes()

        #expect(viewModel.recipes.map(\.text) == ["A", "B"])
    }

    @Test func deletesAllRecipes() async {
        let repository = MockSavedRecipeRepository(storedRecipes: [Recipe(text: "A")])
        let viewModel = MyRecipesViewModel(
            getSavedRecipesUseCase: GetSavedRecipesUseCaseImpl(repository: repository),
            deleteSavedRecipesUseCase: DeleteSavedRecipesUseCaseImpl(repository: repository)
        )

        await viewModel.loadRecipes()
        await viewModel.deleteAllRecipes()

        #expect(viewModel.recipes.isEmpty)
        #expect(repository.deleteAllCallCount == 1)
    }
}
