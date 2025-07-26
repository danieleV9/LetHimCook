import Foundation
import CoreML
import FoundationModels

final class FoundationModelManager {
    static let shared = FoundationModelManager()
    private init() {}

    func predict(input: String) async throws -> String {
        let session = LanguageModelSession()
        let result = try await session.respond(to: input)
        return result.content
    }
}
