import Foundation
import FoundationModels

final class FoundationModelManager {
    static let shared = FoundationModelManager()
    private init() {}

    enum FoundationModelError: LocalizedError {
        case deviceNotEligible
        case appleIntelligenceNotEnabled
        case modelNotReady
        case unavailable
        case emptyResponse

        var errorDescription: String? {
            switch self {
            case .deviceNotEligible:
                return "Apple Intelligence non è disponibile su questo dispositivo."
            case .appleIntelligenceNotEnabled:
                return "Attiva Apple Intelligence nelle impostazioni per usare questa funzione."
            case .modelNotReady:
                return "Il modello si sta scaricando o non è ancora pronto. Riprova tra poco."
            case .unavailable:
                return "Il modello non è disponibile in questo momento."
            case .emptyResponse:
                return "Nessuna risposta valida dal modello."
            }
        }
    }

    func predict(input: String) async throws -> String {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            break
        case .unavailable(.deviceNotEligible):
            throw FoundationModelError.deviceNotEligible
        case .unavailable(.appleIntelligenceNotEnabled):
            throw FoundationModelError.appleIntelligenceNotEnabled
        case .unavailable(.modelNotReady):
            throw FoundationModelError.modelNotReady
        case .unavailable:
            throw FoundationModelError.unavailable
        }

        let session = LanguageModelSession(
            instructions: """
            Sei uno chef professionista con uno stile tecnico e preciso. Quando ti viene fornita una lista di ingredienti, crea una ricetta usando solo quegli ingredienti (più elementi base come olio, sale, pepe, acqua, zucchero ecc. se necessari). Fornisci il titolo e una descrizione della ricetta con ingredienti e procedimento completo. Utilizza il formato Markdown per l'output.
            """
        )

        let options = GenerationOptions(temperature: 0.6)
        let result = try await session.respond(to: input, options: options)
        let response = result.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !response.isEmpty else {
            throw FoundationModelError.emptyResponse
        }

        return response
    }
}
