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

    var snapshots: [Recipe]
    var error: Error?
    private(set) var receivedIngredients: [String]?
    private(set) var prewarmCallCount = 0

    init(
        snapshots: [Recipe] = [Recipe(title: "Mock recipe", ingredients: ["Water"], steps: ["Mix"])],
        error: Error? = nil
    ) {
        self.snapshots = snapshots
        self.error = error
    }

    func recipeStream(for ingredients: [String]) -> AsyncThrowingStream<Recipe, Error> {
        receivedIngredients = ingredients
        let snapshots = snapshots
        let error = error
        return AsyncThrowingStream { continuation in
            for snapshot in snapshots {
                continuation.yield(snapshot)
            }
            if let error {
                continuation.finish(throwing: error)
            } else {
                continuation.finish()
            }
        }
    }

    func prewarm() {
        prewarmCallCount += 1
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

private func makeRecipe(_ title: String) -> Recipe {
    Recipe(title: title, ingredients: [], steps: [])
}

// MARK: - Entity

struct RecipeTests {

    @Test func encodesAndDecodesWithoutLoss() async throws {
        let original = Recipe(title: "Tiramisù", ingredients: ["Mascarpone", "Coffee"], steps: ["Whisk", "Layer"])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Recipe.self, from: data)
        #expect(decoded == original)
    }

    @Test func eachRecipeHasAUniqueIdentity() async {
        let first = makeRecipe("Soup")
        let second = makeRecipe("Soup")
        #expect(first.id != second.id)
    }
}

// MARK: - Use Cases

struct GetRecipeUseCaseTests {

    @Test func forwardsIngredientsAndStreamsRecipe() async throws {
        let expected = Recipe(title: "Pancakes", ingredients: ["Flour"], steps: ["Mix", "Cook"])
        let repository = MockRecipeRepository(snapshots: [expected])
        let useCase = GetRecipeUseCaseImpl(repository: repository)

        var received: [Recipe] = []
        for try await recipe in useCase.execute(with: ["flour", "eggs"]) {
            received.append(recipe)
        }

        #expect(received == [expected])
        #expect(repository.receivedIngredients == ["flour", "eggs"])
    }

    @Test func propagatesRepositoryError() async {
        let repository = MockRecipeRepository(snapshots: [], error: MockRecipeRepository.MockError.failed)
        let useCase = GetRecipeUseCaseImpl(repository: repository)

        await #expect(throws: MockRecipeRepository.MockError.self) {
            for try await _ in useCase.execute(with: ["water"]) {}
        }
    }

    @Test func prewarmDelegatesToRepository() async {
        let repository = MockRecipeRepository()
        let useCase = GetRecipeUseCaseImpl(repository: repository)

        useCase.prewarm()

        #expect(repository.prewarmCallCount == 1)
    }
}

struct SaveRecipeUseCaseTests {

    @Test func savesRecipeToRepository() async {
        let repository = MockSavedRecipeRepository()
        let useCase = SaveRecipeUseCaseImpl(repository: repository)

        await useCase.execute(recipe: makeRecipe("Minestrone"))

        #expect(repository.saveCallCount == 1)
        #expect(repository.storedRecipes.map(\.title) == ["Minestrone"])
    }
}

struct GetSavedRecipesUseCaseTests {

    @Test func returnsRecipesFromRepository() async {
        let repository = MockSavedRecipeRepository(storedRecipes: [makeRecipe("A"), makeRecipe("B")])
        let useCase = GetSavedRecipesUseCaseImpl(repository: repository)

        let result = await useCase.execute()

        #expect(result.map(\.title) == ["A", "B"])
    }
}

struct DeleteSavedRecipesUseCaseTests {

    @Test func deletesAllFromRepository() async {
        let repository = MockSavedRecipeRepository(storedRecipes: [makeRecipe("A"), makeRecipe("B")])
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

    @Test func streamsThenSucceedsAndSaves() async {
        let finalRecipe = Recipe(title: "Risotto", ingredients: ["Rice"], steps: ["Cook"])
        let recipeRepository = MockRecipeRepository(snapshots: [finalRecipe])
        let savedRepository = MockSavedRecipeRepository()
        let viewModel = RecipeViewModel(
            ingredients: ["rice"],
            getRecipeUseCase: GetRecipeUseCaseImpl(repository: recipeRepository),
            saveRecipeUseCase: SaveRecipeUseCaseImpl(repository: savedRepository)
        )

        await viewModel.loadRecipe()

        if case .success(let recipe) = viewModel.state {
            #expect(recipe == finalRecipe)
        } else {
            Issue.record("Expected .success state, got \(viewModel.state)")
        }
        #expect(savedRepository.saveCallCount == 1)
    }

    @Test func entersFailureStateOnError() async {
        let recipeRepository = MockRecipeRepository(snapshots: [], error: MockRecipeRepository.MockError.failed)
        let savedRepository = MockSavedRecipeRepository()
        let viewModel = RecipeViewModel(
            ingredients: ["rice"],
            getRecipeUseCase: GetRecipeUseCaseImpl(repository: recipeRepository),
            saveRecipeUseCase: SaveRecipeUseCaseImpl(repository: savedRepository)
        )

        await viewModel.loadRecipe()

        if case .failure = viewModel.state {
            // expected
        } else {
            Issue.record("Expected .failure state, got \(viewModel.state)")
        }
        #expect(savedRepository.saveCallCount == 0)
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
        let repository = MockSavedRecipeRepository(storedRecipes: [makeRecipe("A"), makeRecipe("B")])
        let viewModel = MyRecipesViewModel(
            getSavedRecipesUseCase: GetSavedRecipesUseCaseImpl(repository: repository),
            deleteSavedRecipesUseCase: DeleteSavedRecipesUseCaseImpl(repository: repository)
        )

        await viewModel.loadRecipes()

        #expect(viewModel.recipes.map(\.title) == ["A", "B"])
    }

    @Test func deletesAllRecipes() async {
        let repository = MockSavedRecipeRepository(storedRecipes: [makeRecipe("A")])
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
