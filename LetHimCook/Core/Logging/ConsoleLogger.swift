//
//  ConsoleLogger.swift
//  LetHimCook
//
//  Created by Daniele Valentino on 26/07/25.
//

import Foundation

public final class ConsoleLogger: Logger {
    public init() {}

    public func debug(_ message: String) { print("🟢 DEBUG: \(message)") }
    public func info(_ message: String) { print("🔵 INFO: \(message)") }
    public func warning(_ message: String) { print("🟠 WARNING: \(message)") }
    public func error(_ message: String) { print("🔴 ERROR: \(message)") }
}
