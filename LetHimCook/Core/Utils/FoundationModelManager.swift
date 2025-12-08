import Foundation
import CoreML
import FoundationModels

final class FoundationModelManager {
    static let shared = FoundationModelManager()
    private init() {}

    func predict(input: String) async throws -> String {
        let session = LanguageModelSession(instructions:
            """
            Sei uno chef professionista con uno stile tecnico e preciso. Quando ti viene fornita una lista di ingredienti, crea una ricetta usando solo quegli ingredienti (più elementi base come olio, sale, pepe, acqua, zucchero ecc. se necessari). Fornisci il titolo e una descrizione della ricetta con ingredienti e procedimento completo. Utilizza il formato Markdown per l'output.
            """
        )
        let result = try await session.respond(to: input)
        return result.content
    }
}
