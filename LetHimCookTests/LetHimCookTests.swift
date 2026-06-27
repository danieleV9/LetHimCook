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

    /// Reference box backing a `Binding<[String]>` for testing.
    final class Box {
        var value: [String]
        init(_ value: [String] = []) { self.value = value }
    }

    private func makeViewModel(_ box: Box) -> IngredientInputViewModel {
        IngredientInputViewModel(ingredients: Binding(get: { box.value }, set: { box.value = $0 }))
    }

    @Test func addIngredientAppendsTrimmedValueAndClearsInput() {
        let box = Box()
        let viewModel = makeViewModel(box)

        viewModel.currentInput = "  Tomato  "
        viewModel.addIngredient()

        #expect(box.value == ["Tomato"])
        #expect(viewModel.currentInput == "")
    }

    @Test func addIngredientIgnoresWhitespaceOnlyInput() {
        let box = Box()
        let viewModel = makeViewModel(box)

        viewModel.currentInput = "   "
        viewModel.addIngredient()

        #expect(box.value.isEmpty)
    }

    @Test func removeIngredientRemovesAtGivenOffsets() {
        let box = Box(["A", "B", "C"])
        let viewModel = makeViewModel(box)

        viewModel.removeIngredient(at: IndexSet(integer: 1))

        #expect(box.value == ["A", "C"])
    }

    @Test func resetClearsListAndInput() {
        let box = Box(["A", "B"])
        let viewModel = makeViewModel(box)
        viewModel.currentInput = "pending"

        viewModel.reset()

        #expect(box.value.isEmpty)
        #expect(viewModel.currentInput == "")
    }
}

// MARK: - View Models backed by the DI container
//
// These tests resolve dependencies through `DIContainer.shared`, so they are
// grouped in a single serialized suite that resets the container before each
// test to avoid cross-test interference.

@Suite(.serialized)
struct ContainerBackedViewModelTests {

    init() async {
        await DIContainer.shared.resetAll()
    }

    @MainActor
    @Test func recipeViewModelLoadsAndSavesOnSuccess() async {
        let recipeRepository = MockRecipeRepository(result: .success(Recipe(text: "Risotto")))
        let savedRepository = MockSavedRecipeRepository()

        await DIContainer.shared.register(GetRecipeUseCase.self, scope: .singleton) {
            GetRecipeUseCaseImpl(repository: recipeRepository)
        }
        await DIContainer.shared.register(SaveRecipeUseCase.self, scope: .singleton) {
            SaveRecipeUseCaseImpl(repository: savedRepository)
        }

        let viewModel = RecipeViewModel(ingredients: ["rice"])
        await viewModel.loadRecipe()

        if case .success(let text) = viewModel.state {
            #expect(text == "Risotto")
        } else {
            Issue.record("Expected .success state, got \(viewModel.state)")
        }
        #expect(savedRepository.saveCallCount == 1)
    }

    @MainActor
    @Test func recipeViewModelEntersFailureStateOnError() async {
        let recipeRepository = MockRecipeRepository(result: .failure(MockRecipeRepository.MockError.failed))

        await DIContainer.shared.register(GetRecipeUseCase.self, scope: .singleton) {
            GetRecipeUseCaseImpl(repository: recipeRepository)
        }
        await DIContainer.shared.register(SaveRecipeUseCase.self, scope: .singleton) {
            SaveRecipeUseCaseImpl(repository: MockSavedRecipeRepository())
        }

        let viewModel = RecipeViewModel(ingredients: ["rice"])
        await viewModel.loadRecipe()

        if case .failure = viewModel.state {
            // expected
        } else {
            Issue.record("Expected .failure state, got \(viewModel.state)")
        }
    }

    @MainActor
    @Test func recipeViewModelStaysIdleWithoutIngredients() async {
        await DIContainer.shared.register(GetRecipeUseCase.self, scope: .singleton) {
            GetRecipeUseCaseImpl(repository: MockRecipeRepository())
        }
        await DIContainer.shared.register(SaveRecipeUseCase.self, scope: .singleton) {
            SaveRecipeUseCaseImpl(repository: MockSavedRecipeRepository())
        }

        let viewModel = RecipeViewModel(ingredients: [])
        await viewModel.loadRecipe()

        if case .idle = viewModel.state {
            // expected
        } else {
            Issue.record("Expected .idle state, got \(viewModel.state)")
        }
    }

    @Test func myRecipesViewModelLoadsRecipes() async {
        let repository = MockSavedRecipeRepository(storedRecipes: [Recipe(text: "A"), Recipe(text: "B")])
        await DIContainer.shared.register(GetSavedRecipesUseCase.self, scope: .singleton) {
            GetSavedRecipesUseCaseImpl(repository: repository)
        }

        let viewModel = MyRecipesViewModel()
        await viewModel.loadRecipes()

        #expect(viewModel.recipes.map(\.text) == ["A", "B"])
    }

    @Test func myRecipesViewModelDeletesAllRecipes() async {
        let repository = MockSavedRecipeRepository(storedRecipes: [Recipe(text: "A")])
        await DIContainer.shared.register(GetSavedRecipesUseCase.self, scope: .singleton) {
            GetSavedRecipesUseCaseImpl(repository: repository)
        }
        await DIContainer.shared.register(DeleteSavedRecipesUseCase.self, scope: .singleton) {
            DeleteSavedRecipesUseCaseImpl(repository: repository)
        }

        let viewModel = MyRecipesViewModel()
        await viewModel.loadRecipes()
        await viewModel.deleteAllRecipes()

        #expect(viewModel.recipes.isEmpty)
        #expect(repository.deleteAllCallCount == 1)
    }
}
