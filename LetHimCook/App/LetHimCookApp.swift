//
//  LetHimCookApp.swift
//  LetHimCook
//
//  Created by Daniele Valentino on 13/07/25.
//

import SwiftUI

@main
struct LetHimCookApp: App {
    @State private var factory: ViewModelFactory?

    var body: some Scene {
        WindowGroup {
            Group {
                if let factory {
                    TabView {
                        ContentView(factory: factory)
                            .tabItem {
                                Label("tab_home_title", systemImage: "fork.knife")
                            }
                        MyRecipeView(viewModel: factory.makeMyRecipesViewModel())
                            .tabItem {
                                Label("tab_saved_recipes_title", systemImage: "bookmark")
                            }
                    }
                    .tint(AppTheme.accent)
                } else {
                    ProgressView().task {
                        factory = await AppContainer.makeViewModelFactory()
                    }
                }
            }
        }
    }
}
