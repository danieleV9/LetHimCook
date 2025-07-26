//
//  ContentView.swift
//  LetHimCook
//
//  Created by Daniele Valentino on 13/07/25.
//

import SwiftUI

struct ContentView: View {
    @Bindable var viewModel = ContentViewModel()
    @State private var ingredientInputViewModel: IngredientInputViewModel
        = IngredientInputViewModel(ingredients: Binding(
            get: { [] }, // temporary; will reset in onAppear
            set: { _ in }
          ))

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Image(viewModel.ingredients.isEmpty ? "fridge_closed" : "fridge_opened")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .padding(.top, 0)

                // Live updated list of ingredients
                if !viewModel.ingredients.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ingredients:")
                            .font(.headline)
                            .bold()
                        ForEach(viewModel.ingredients, id: \.self) { ingredient in
                            Text(ingredient)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
            }
            .padding(.horizontal)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 100)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                if !viewModel.ingredients.isEmpty {
                    Button(action: {
                        viewModel.showRecipe()
                    }) {
                        Text("Find the recipe")
                            .font(.title2)
                            .bold()
                            .padding()
                            .frame(maxWidth: .infinity)
                    }
                    .foregroundColor(.teal)
                    .cornerRadius(12)
                }

                Button(action: {
                    viewModel.showInput()
                }) {
                    Text("Tell me what's in your fridge")
                        .bold()
                        .font(.title2)
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                .foregroundColor(.accentColor)
                .cornerRadius(12)
            }
            .padding([.horizontal, .top])
            .padding(.bottom, 8)
            .background(
                Color(.systemBackground)
                    .ignoresSafeArea()
            )
        }
        .sheet(isPresented: $viewModel.isPresentingInput) {
            IngredientInputView(viewModel: IngredientInputViewModel(ingredients: Binding(
                get: { viewModel.ingredients },
                set: { viewModel.ingredients = $0 }
            )))
            .presentationDetents([.large])
        }
        .fullScreenCover(isPresented: Binding(get: { viewModel.isPresentingRecipe }, set: { viewModel.isPresentingRecipe = $0 })) {
            RecipeView(viewModel: RecipeViewModel(ingredients: viewModel.ingredients))
        }
    }
}

#Preview {
    ContentView()
}

