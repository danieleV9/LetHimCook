//
//  LetHimCookApp.swift
//  LetHimCook
//
//  Created by Daniele Valentino on 13/07/25.
//

import SwiftUI

@main
struct LetHimCookApp: App {
    @State private var isConfigured = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isConfigured {
                    TabView {
                        ContentView()
                            .tabItem {
                                Label("tab_home_title", systemImage: "house")
                            }
                        MyRecipeView()
                            .tabItem {
                                Label("tab_saved_recipes_title", systemImage: "book")
                            }
                    }
                } else {
                    ProgressView().task {
                        await AppContainer.configure()
                        isConfigured = true
                    }
                }
            }
        }
    }
}
