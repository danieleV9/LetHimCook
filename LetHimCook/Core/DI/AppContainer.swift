//
//  AppContainer.swift
//  LetHimCook
//
//  Created by Daniele Valentino on 26/07/25.
//

import Foundation
import SwiftUI
import ActorDI

enum AppContainer {
    
    static var container: DIContainer = DIContainer()

    static func configure() async {
        
        await container.register(Logger.self, scope: .singleton) {
            ConsoleLogger()
        }
        
    }
}
