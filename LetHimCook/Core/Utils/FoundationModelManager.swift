import Foundation
import CoreML
import FoundationModels

final class FoundationModelManager {
    static let shared = FoundationModelManager()
    private init() {}

    func predict(input: String) async throws -> String {
        let session = LanguageModelSession(instructions:
            """
            Sei uno chef professionista. Quando ti viene fornita una lista di ingredienti, crei una ricetta completa usando solo quegli ingredienti (più elementi base come olio, sale, pepe, acqua). Il tuo stile è tecnico e preciso, come quello di un vero chef di cucina. Fornisci il titolo e una descrizione della ricetta con ingredienti e procedimento completo.
            """
        )
        let result = try await session.respond(to: input)
        return result.content
    }
}
