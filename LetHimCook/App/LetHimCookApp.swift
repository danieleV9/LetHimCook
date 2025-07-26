//
//  LetHimCookApp.swift
//  LetHimCook
//
//  Created by Daniele Valentino on 13/07/25.
//

import SwiftUI

@main
struct LetHimCookApp: App {
    init() {
        Task {
            await AppContainer.configure()
        }
    }
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                MyRecinseView()
                    .tabItem {
                        Label("My recinse", systemImage: "book")
                    }
            }
        }
    }
}
