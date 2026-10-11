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

    init(factory: ViewModelFactory) {
        self.factory = factory
    }

    var body: some View {
        ZStack(alignment: .top) {
            AppBackground()

            // Paints the status bar area (and the pull-to-bounce area) in brand
            // green so the scrolling header appears to extend to the top edge.
            AppTheme.accentDeep
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .ignoresSafeArea(edges: .top)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    VStack(alignment: .leading, spacing: 24) {
                        promoBanner

                        if !viewModel.ingredients.isEmpty {
                            ingredientsSection
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 24)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !viewModel.ingredients.isEmpty {
                actionBar
            }
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

    // MARK: - Header

    /// Brand-green header with a search-style entry point, like TheFork's home.
    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("app_title")
                    .font(.largeTitle.weight(.heavy))
                Text("home_subtitle")
                    .font(.body)
                    .opacity(0.85)
            }
            .foregroundStyle(.white)

            Button {
                viewModel.showInput()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppTheme.accent)
                    Text(viewModel.ingredients.isEmpty ? "home_tell_me_prompt" : "home_edit_ingredients")
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                }
                .font(.body.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(AppTheme.surface, in: Capsule(style: .continuous))
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .environment(\.colorScheme, .light)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            AppTheme.accentDeep
                .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 28, bottomTrailingRadius: 28, style: .continuous))
        }
    }

    // MARK: - Sections

    private var promoBanner: some View {
        AppCard(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                LottieFoodView()
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.accentSoft)

                VStack(alignment: .leading, spacing: 8) {
                    AppBadge(titleKey: "badge_on_device_ai", systemImage: "sparkles")
                    Text("home_banner_title")
                        .font(.title3.weight(.bold))
                    Text("home_banner_subtitle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                AppSectionHeader(titleKey: "ingredient_input_section_title")
                Button("home_edit_button") {
                    viewModel.showInput()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
            }

            FlowLayout(spacing: 8) {
                ForEach(viewModel.ingredients, id: \.self) { ingredient in
                    AppChip(text: ingredient)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Action bar

    private var actionBar: some View {
        Button {
            viewModel.showRecipe()
        } label: {
            Label("home_find_recipe_button", systemImage: "sparkles")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .tint(AppTheme.accent)
        .controlSize(.large)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

#Preview {
    ContentView(factory: AppViewModelFactory.preview)
}

#Preview("With ingredients") {
    let view = ContentView(factory: AppViewModelFactory.preview)
    view.viewModel.ingredients = ["Eggs", "Milk", "Flour", "Parmigiano", "Basil"]
    return view
}
