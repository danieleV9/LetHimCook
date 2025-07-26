//
//  Logger.swift
//  LetHimCook
//
//  Created by Daniele Valentino on 26/07/25.
//

import Foundation

public protocol Logger: Sendable {
    func debug(_ message: String)
    func info(_ message: String)
    func warning(_ message: String)
    func error(_ message: String)
}
