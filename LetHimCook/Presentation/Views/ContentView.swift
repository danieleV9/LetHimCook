//
//  ContentView.swift
//  LetHimCook
//
//  Created by Daniele Valentino on 13/07/25.
//

import SwiftUI
import Lottie

struct ContentView: View {
    @Bindable var viewModel = ContentViewModel()
    @State private var ingredientInputViewModel: IngredientInputViewModel
        = IngredientInputViewModel(ingredients: Binding(
            get: { [] }, // temporary; will reset in onAppear
            set: { _ in }
          ))
    @State private var isFridgeOpen = false

    var body: some View {
        VStack {
            Text("app_title")
                .font(.largeTitle)
                .bold()
                .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.13))
                .padding(.top, 16)
                .frame(maxWidth: .infinity)
                .background(.clear)
                .shadow(color: .black.opacity(0.07), radius: 6, y: 2)

            ScrollView {
                VStack(spacing: 8) {
                    LottieFoodView()
                        .frame(height: 260)
                        .padding(.top, 12)

                    // Live updated list of ingredients
                    if !viewModel.ingredients.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("home_ingredients_title")
                                .font(.title)
                                .bold()
                            ForEach(viewModel.ingredients, id: \.self) { ingredient in
                                Text("\u{2022}  " + ingredient)
                                    .font(.system(size: 19, weight: .regular))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.13))
                        .padding()
                    }
                }
                .padding(.horizontal)
            }

        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                if !viewModel.ingredients.isEmpty {
                    Button(action: {
                        viewModel.showRecipe()
                    }) {
                        Text("home_find_recipe_button")
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
                    Text("home_tell_me_prompt")
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
        .onChange(of: viewModel.ingredients) { _, newIngredients in
            guard newIngredients.isEmpty else { return }
            isFridgeOpen = false
        }
        .fullScreenCover(isPresented: Binding(get: { viewModel.isPresentingRecipe }, set: { viewModel.isPresentingRecipe = $0 })) {
            RecipeView(viewModel: RecipeViewModel(ingredients: viewModel.ingredients))
        }
    }
}

#Preview {
    ContentView()
}
