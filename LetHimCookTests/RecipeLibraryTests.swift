//
//  RecipeLibraryTests.swift
//  LetHimCookTests
//

import Testing
import Foundation
@testable import LetHimCook

func makeLibraryRecipe(
    _ title: String,
    ingredients: [String],
    pantry: [String] = []
) -> LibraryRecipe {
    LibraryRecipe(
        id: title,
        language: "it",
        title: title,
        ingredients: ingredients.map { LibraryRecipe.Ingredient(quantity: "1", name: $0) }
            + pantry.map { LibraryRecipe.Ingredient(name: $0, pantry: true) },
        steps: [RecipeStep(title: "Step", instruction: "Do it", durationMinutes: 5)]
    )
}

// MARK: - GetRecipeUseCase with a library

@MainActor
struct GetRecipeUseCaseLibraryTests {

    @Test func servesExactLibraryMatchWithoutGenerating() async throws {
        let carbonara = makeLibraryRecipe("Carbonara", ingredients: ["spaghetti", "guanciale", "tuorli d'uovo"], pantry: ["sale"])
        let repository = MockRecipeRepository()
        let useCase = GetRecipeUseCaseImpl(
            repository: repository,
            library: MockRecipeLibraryRepository(stored: [carbonara])
        )

        var received: [Recipe] = []
        for try await recipe in useCase.execute(with: ["Spaghetti", "Guanciale", "Uova"]) {
            received.append(recipe)
        }

        #expect(received.count == 1)
        #expect(received.first?.title == "Carbonara")
        #expect(received.first?.origin == .library)
        #expect(received.first?.steps == carbonara.steps)
        #expect(repository.streamCallCount == 0)
    }

    @Test func adaptsPartialLibraryMatch() async throws {
        let carbonara = makeLibraryRecipe("Carbonara", ingredients: ["spaghetti", "guanciale", "uova", "pecorino"])
        let repository = MockRecipeRepository()
        let useCase = GetRecipeUseCaseImpl(
            repository: repository,
            library: MockRecipeLibraryRepository(stored: [carbonara])
        )

        var received: [Recipe] = []
        for try await recipe in useCase.execute(with: ["spaghetti", "uova", "zucchine"]) {
            received.append(recipe)
        }

        #expect(repository.receivedReference == carbonara)
        #expect(received.allSatisfy { $0.origin == .adapted(fromTitle: "Carbonara") })
    }

    @Test func generatesFromScratchWithoutLibraryMatch() async throws {
        let carbonara = makeLibraryRecipe("Carbonara", ingredients: ["spaghetti", "guanciale", "uova", "pecorino"])
        let repository = MockRecipeRepository()
        let useCase = GetRecipeUseCaseImpl(
            repository: repository,
            library: MockRecipeLibraryRepository(stored: [carbonara])
        )

        var received: [Recipe] = []
        for try await recipe in useCase.execute(with: ["riso", "zafferano"]) {
            received.append(recipe)
        }

        #expect(repository.streamCallCount == 1)
        #expect(repository.receivedReference == nil)
        #expect(received.allSatisfy { $0.origin == .generated })
    }
}

// MARK: - RecipeMatcher

@MainActor
struct RecipeMatcherTests {
    let matcher = RecipeMatcher()

    @Test func exactWhenAllRequiredIngredientsAreAvailable() {
        let recipe = makeLibraryRecipe("Bruschetta", ingredients: ["pane", "pomodori"], pantry: ["olio", "sale"])

        let outcome = matcher.bestMatch(for: ["Pane", "Pomodoro"], in: [recipe])

        #expect(outcome == .exact(recipe))
    }

    @Test func pantryIngredientsDoNotCount() {
        let recipe = makeLibraryRecipe("Bruschetta", ingredients: ["pane", "pomodori"], pantry: ["olio", "sale", "aglio"])

        let outcome = matcher.bestMatch(for: ["pane", "pomodori"], in: [recipe])

        #expect(outcome == .exact(recipe))
    }

    @Test func referenceWhenHalfTheIngredientsAreAvailable() {
        let recipe = makeLibraryRecipe("Carbonara", ingredients: ["spaghetti", "guanciale", "uova", "pecorino"])

        let outcome = matcher.bestMatch(for: ["spaghetti", "uova"], in: [recipe])

        #expect(outcome == .reference(recipe))
    }

    @Test func referenceWhenRecipeUsesFewOfTheUserIngredients() {
        let recipe = makeLibraryRecipe("Uova sode", ingredients: ["uova"])

        let outcome = matcher.bestMatch(for: ["uova", "zucchine", "riso", "funghi"], in: [recipe])

        #expect(outcome == .reference(recipe))
    }

    @Test func noneWhenTooFewIngredientsMatch() {
        let recipe = makeLibraryRecipe("Carbonara", ingredients: ["spaghetti", "guanciale", "uova", "pecorino"])

        #expect(matcher.bestMatch(for: ["spaghetti"], in: [recipe]) == .noMatch)
        #expect(matcher.bestMatch(for: [], in: [recipe]) == .noMatch)
        #expect(matcher.bestMatch(for: ["spaghetti"], in: []) == .noMatch)
    }

    @Test func ignoresCaseAccentsAndPlurals() {
        let recipe = makeLibraryRecipe("Omelette", ingredients: ["Eggs", "Café cream"])

        let outcome = matcher.bestMatch(for: ["egg", "cafe cream"], in: [recipe])

        #expect(outcome == .exact(recipe))
    }

    @Test func multiWordNamesMatchWhenOneContainsTheOther() {
        let recipe = makeLibraryRecipe("Sugo", ingredients: ["pomodori pelati", "basilico fresco"])

        let outcome = matcher.bestMatch(for: ["pomodoro", "basilico"], in: [recipe])

        #expect(outcome == .exact(recipe))
    }

    @Test func doesNotMatchOnSharedSubstrings() {
        let recipe = makeLibraryRecipe("Dolce", ingredients: ["zucchero", "farina"])

        #expect(matcher.bestMatch(for: ["formaggio cheddar", "farro"], in: [recipe]) == .noMatch)
    }

    @Test func prefersExactOverReferenceAndHigherScore() {
        let partial = makeLibraryRecipe("Partial", ingredients: ["pasta", "uova", "pecorino"])
        let narrow = makeLibraryRecipe("Narrow", ingredients: ["pasta", "uova"])
        let wide = makeLibraryRecipe("Wide", ingredients: ["pasta", "uova", "burro"])

        let outcome = matcher.bestMatch(for: ["pasta", "uova", "burro"], in: [partial, narrow, wide])

        #expect(outcome == .exact(wide))
    }
}

// MARK: - Recipe library

@MainActor
struct BundleRecipeLibraryRepositoryTests {

    @Test func loadsBundledLibraryFilteredByLanguage() async {
        let italian = await BundleRecipeLibraryRepository(language: "it").recipes()
        let english = await BundleRecipeLibraryRepository(language: "en").recipes()

        #expect(!italian.isEmpty)
        #expect(!english.isEmpty)
        #expect(italian.allSatisfy { $0.language == "it" })
        #expect(english.allSatisfy { $0.language == "en" })
        #expect(italian.allSatisfy { !$0.ingredients.isEmpty && !$0.steps.isEmpty })
    }

    @Test func missingFileYieldsEmptyLibrary() async {
        let repository = BundleRecipeLibraryRepository(fileURL: nil, language: "it")

        #expect(await repository.recipes().isEmpty)
    }

    @Test func referencePromptIncludesTheLibraryRecipe() {
        let recipe = makeLibraryRecipe("Carbonara", ingredients: ["spaghetti", "guanciale"])

        let prompt = FoundationRecipeRepository.prompt(for: ["spaghetti"], reference: recipe)

        #expect(prompt.contains("Carbonara"))
        #expect(prompt.contains("1 guanciale"))
        #expect(prompt.contains("1. Do it"))
    }
}
