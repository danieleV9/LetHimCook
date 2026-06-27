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
    @State private var isFridgeOpen = false

    private let factory: ViewModelFactory

    private let chipColumns: [GridItem] = [
        GridItem(.adaptive(minimum: 90), spacing: 8, alignment: .leading)
    ]

    init(factory: ViewModelFactory) {
        self.factory = factory
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    AppCard {
                        VStack(spacing: 12) {
                            LottieFoodView()
                                .frame(height: 220)
                        }
                    }

                    if !viewModel.ingredients.isEmpty {
                        AppCard {
                            VStack(alignment: .leading, spacing: 12) {
                                AppSectionHeader(titleKey: "home_ingredients_title")

                                LazyVGrid(columns: chipColumns, alignment: .leading, spacing: 8) {
                                    ForEach(viewModel.ingredients, id: \.self) { ingredient in
                                        AppChip(text: ingredient)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 96)
            }
        }
        .safeAreaInset(edge: .bottom) {
            actionBar
        }
        .sheet(isPresented: $viewModel.isPresentingInput) {
            IngredientInputView(viewModel: factory.makeIngredientInputViewModel(
                ingredients: viewModel.ingredients,
                onChange: { viewModel.ingredients = $0 }
            ))
            .presentationDetents([.large])
        }
        .onChange(of: viewModel.ingredients) { _, newIngredients in
            guard newIngredients.isEmpty else { return }
            isFridgeOpen = false
        }
        .onChange(of: viewModel.isPresentingInput) { _, isPresenting in
            // Warm up the model while the user is entering ingredients.
            if isPresenting { factory.prewarmRecipeGeneration() }
        }
        .fullScreenCover(isPresented: Binding(get: { viewModel.isPresentingRecipe }, set: { viewModel.isPresentingRecipe = $0 })) {
            RecipeView(viewModel: factory.makeRecipeViewModel(ingredients: viewModel.ingredients))
        }
    }

    private var header: some View {
        Text("app_title")
            .font(.system(.largeTitle, design: .serif).weight(.bold))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionBar: some View {
        VStack(spacing: 12) {
            if viewModel.ingredients.isEmpty {
                // No ingredients yet: entering them is the primary action.
                Button {
                    viewModel.showInput()
                } label: {
                    Label("home_tell_me_prompt", systemImage: "plus")
                        .font(.system(.headline, design: .rounded))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(AppTheme.accent)
                .controlSize(.large)
            } else {
                // Ingredients present: generating the recipe is the primary action.
                Button {
                    viewModel.showRecipe()
                } label: {
                    Label("home_find_recipe_button", systemImage: "sparkles")
                        .font(.system(.headline, design: .rounded))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(AppTheme.accent)
                .controlSize(.large)

                Button {
                    viewModel.showInput()
                } label: {
                    Label("home_tell_me_prompt", systemImage: "pencil")
                        .font(.system(.headline, design: .rounded))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .controlSize(.large)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

#Preview {
    ContentView(factory: AppViewModelFactory.preview)
}
