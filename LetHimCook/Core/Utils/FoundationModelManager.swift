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
        @Guide(description: "Every ingredient needed, with a realistic quantity for the dish", .count(1...20))
        var ingredients: [GeneratedIngredient]
        @Guide(description: "The preparation steps in the order they are carried out", .count(3...12))
        var steps: [GeneratedStep]
    }

    @Generable
    struct GeneratedIngredient {
        @Guide(description: "The amount as a number or fraction, e.g. '200' or '1/2'; empty when used to taste")
        var quantity: String
        @Guide(description: "The unit of measure, e.g. 'g', 'ml', 'tbsp'; empty for countable items like eggs")
        var unit: String
        @Guide(description: "The ingredient name only, without quantity, e.g. 'spaghetti'")
        var name: String
    }

    @Generable
    struct GeneratedStep {
        @Guide(description: "A short imperative title of two to four words, e.g. 'Brown the onion'")
        var title: String
        @Guide(description: "Two or three sentences: what to do, heat level, timing and the cue that tells when it is done")
        var instruction: String
        @Guide(description: "How many minutes the step takes; 0 when it is immediate", .range(0...240))
        var durationMinutes: Int
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

                    // Top-p sampling keeps some variety between recipes while never
                    // picking unlikely tokens, which keeps quantities and times sensible.
                    let options = GenerationOptions(
                        sampling: .random(probabilityThreshold: 0.9),
                        temperature: 0.5,
                        maximumResponseTokens: 2500
                    )
                    let recipeID = UUID()

                    let stream = session.streamResponse(
                        to: prompt,
                        generating: GeneratedRecipe.self,
                        options: options
                    )

                    for try await snapshot in stream {
                        continuation.yield(Self.recipe(from: snapshot.content, id: recipeID))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: Self.map(error))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Maps a partial snapshot, leaving out entries that are still empty so
    /// half-written rows don't flash in the UI while the recipe streams in.
    private static func recipe(from partial: GeneratedRecipe.PartiallyGenerated, id: UUID) -> Recipe {
        let ingredients = (partial.ingredients ?? []).compactMap { item -> RecipeIngredient? in
            guard let name = item.name, !name.isEmpty else { return nil }
            return RecipeIngredient(quantity: nonEmpty(item.quantity), unit: nonEmpty(item.unit), name: name)
        }
        let steps = (partial.steps ?? []).compactMap { item -> RecipeStep? in
            guard let instruction = item.instruction, !instruction.isEmpty else { return nil }
            let minutes = item.durationMinutes.flatMap { $0 > 0 ? $0 : nil }
            return RecipeStep(title: item.title ?? "", instruction: instruction, durationMinutes: minutes)
        }
        return Recipe(id: id, title: partial.title ?? "", ingredients: ingredients, steps: steps)
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
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
