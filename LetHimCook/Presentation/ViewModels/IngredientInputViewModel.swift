// IngredientInputViewModel.swift
// LetHimCook
//
// Created by Daniele Valentino on 13/07/25.

import Foundation

@Observable
@MainActor
final class IngredientInputViewModel {

    private let logger: Logger?
    private let onIngredientsChange: ([String]) -> Void

    private(set) var ingredients: [String] {
        didSet { onIngredientsChange(ingredients) }
    }
    var currentInput: String = ""

    init(
        ingredients: [String] = [],
        logger: Logger? = nil,
        onIngredientsChange: @escaping ([String]) -> Void = { _ in }
    ) {
        self.ingredients = ingredients
        self.logger = logger
        self.onIngredientsChange = onIngredientsChange
    }

    func addIngredient() {
        let trimmed = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        ingredients.append(trimmed)
        currentInput = ""
        logger?.debug("\(#function): added ingredient \(trimmed)")
    }

    func removeIngredient(at offsets: IndexSet) {
        var updated = ingredients
        for index in offsets.sorted(by: >) {
            updated.remove(at: index)
        }
        ingredients = updated
    }

    func reset() {
        ingredients = []
        currentInput = ""
    }
}
