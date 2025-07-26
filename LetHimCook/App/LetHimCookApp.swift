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
                                Label("Home", systemImage: "house")
                            }
                        MyRecipeView()
                            .tabItem {
                                Label("My recipes", systemImage: "book")
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
