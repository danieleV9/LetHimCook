// ContentViewModel.swift
// LetHimCook
//
// Created by Daniele Valentino on 13/07/25.

import Foundation
import SwiftUI

@Observable
final class ContentViewModel {
    
    var isPresentingInput = false
    
    var isPresentingRecipe = false
    
    @ObservationIgnored
    var currentInput: String = ""
    
    var ingredients: [String] = []
    
    func didTapFridgeButton() {
        isPresentingInput = true
    }
    
    func cancelInput() {
        currentInput = ""
        isPresentingInput = false
    }
    
    func showRecipe() {
        isPresentingRecipe = true
    }
    
    func showInput() {
        isPresentingInput = true
    }
}
