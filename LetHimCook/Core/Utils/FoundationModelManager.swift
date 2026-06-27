import Foundation
import FoundationModels

final class FoundationModelManager {
    static let shared = FoundationModelManager()
    private init() {}

    /// The structured shape the model is asked to produce via guided generation.
    @Generable
    struct GeneratedRecipe {
        @Guide(description: "A short, appetizing title for the dish")
        var title: String
        @Guide(description: "Each entry is one ingredient with its quantity, e.g. '200 g flour'", .count(1...20))
        var ingredients: [String]
        @Guide(description: "Each entry is a single, concise preparation step, in order", .count(1...15))
        var steps: [String]
    }

    enum FoundationModelError: LocalizedError {
        case deviceNotEligible
        case appleIntelligenceNotEnabled
        case modelNotReady
        case unavailable
        case guardrailViolation
        case exceededContextWindow
        case unsupportedLanguage
        case rateLimited
        case emptyResponse
        case generationFailed

        var errorDescription: String? {
            switch self {
            case .deviceNotEligible:
                return String(localized: "foundation_model_error_device_not_eligible")
            case .appleIntelligenceNotEnabled:
                return String(localized: "foundation_model_error_intelligence_not_enabled")
            case .modelNotReady:
                return String(localized: "foundation_model_error_model_not_ready")
            case .unavailable:
                return String(localized: "foundation_model_error_unavailable")
            case .guardrailViolation:
                return String(localized: "foundation_model_error_guardrail")
            case .exceededContextWindow:
                return String(localized: "foundation_model_error_context_exceeded")
            case .unsupportedLanguage:
                return String(localized: "foundation_model_error_unsupported_language")
            case .rateLimited:
                return String(localized: "foundation_model_error_rate_limited")
            case .emptyResponse:
                return String(localized: "foundation_model_error_empty_response")
            case .generationFailed:
                return String(localized: "foundation_model_error_generation_failed")
            }
        }
    }

    /// A session warmed ahead of time to cut first-response latency. Consumed by the
    /// next generation, then discarded so sessions don't accumulate context.
    private var prewarmedSession: LanguageModelSession?

    private static func instructions() -> String {
        String(localized: "recipe_instructions")
    }

    /// Loads the model into memory before the user asks for a recipe.
    func prewarm() {
        guard case .available = SystemLanguageModel.default.availability else { return }
        let session = LanguageModelSession(instructions: Self.instructions())
        session.prewarm()
        prewarmedSession = session
    }

    /// Streams a structured recipe, yielding progressively more complete snapshots.
    func streamRecipe(prompt: String) -> AsyncThrowingStream<Recipe, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try Self.checkAvailability()

                    let session = prewarmedSession ?? LanguageModelSession(instructions: Self.instructions())
                    prewarmedSession = nil

                    let options = GenerationOptions(temperature: 0.6, maximumResponseTokens: 1200)
                    let recipeID = UUID()

                    let stream = session.streamResponse(
                        to: prompt,
                        generating: GeneratedRecipe.self,
                        options: options
                    )

                    for try await snapshot in stream {
                        let partial = snapshot.content
                        continuation.yield(Recipe(
                            id: recipeID,
                            title: partial.title ?? "",
                            ingredients: partial.ingredients ?? [],
                            steps: partial.steps ?? []
                        ))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: Self.map(error))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private static func checkAvailability() throws {
        switch SystemLanguageModel.default.availability {
        case .available:
            return
        case .unavailable(.deviceNotEligible):
            throw FoundationModelError.deviceNotEligible
        case .unavailable(.appleIntelligenceNotEnabled):
            throw FoundationModelError.appleIntelligenceNotEnabled
        case .unavailable(.modelNotReady):
            throw FoundationModelError.modelNotReady
        case .unavailable:
            throw FoundationModelError.unavailable
        }
    }

    private static func map(_ error: Error) -> Error {
        if let known = error as? FoundationModelError { return known }

        guard let generationError = error as? LanguageModelSession.GenerationError else {
            return FoundationModelError.generationFailed
        }

        switch generationError {
        case .guardrailViolation:
            return FoundationModelError.guardrailViolation
        case .exceededContextWindowSize:
            return FoundationModelError.exceededContextWindow
        case .unsupportedLanguageOrLocale:
            return FoundationModelError.unsupportedLanguage
        case .rateLimited:
            return FoundationModelError.rateLimited
        default:
            return FoundationModelError.generationFailed
        }
    }
}
