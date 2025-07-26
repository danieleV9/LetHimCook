// IngredientInputViewModel.swift
// LetHimCook
//
// Created by Daniele Valentino on 13/07/25.

import Foundation
import SwiftUI
import ActorDI

@Observable
final class IngredientInputViewModel {
    
    var logger: Logger?
    
    var ingredients: Binding<[String]>
    var currentInput: String = ""
    
    init(ingredients: Binding<[String]>) {
        self.ingredients = ingredients
        Task { [weak self] in
            self?.logger = try? await AppContainer.container.resolve(Logger.self)
        }
    }
    
    func addIngredient() {
        let trimmed = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        ingredients.wrappedValue.append(trimmed)
        currentInput = ""
        logger?.debug("\(#function): added ingredient \(trimmed)")
    }
    
    func removeIngredient(at offsets: IndexSet) {
        ingredients.wrappedValue.remove(atOffsets: offsets)
    }
    
    func reset() {
        ingredients.wrappedValue = []
        currentInput = ""
    }
}
