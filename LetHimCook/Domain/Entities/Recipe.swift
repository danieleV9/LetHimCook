import Foundation

/// One ingredient line, split so quantities can be shown (and later scaled)
/// apart from the name. `quantity` is text to allow values like "1/2" or "q.b.".
struct RecipeIngredient: Codable, Sendable, Equatable, Hashable {
    let quantity: String?
    let unit: String?
    let name: String

    init(quantity: String? = nil, unit: String? = nil, name: String) {
        self.quantity = quantity
        self.unit = unit
        self.name = name
    }

    /// Quantity and unit joined for display, e.g. "200 g". Nil when neither is set.
    var amount: String? {
        let parts = [quantity, unit]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }
}

/// One preparation step: a short title plus the full instruction.
struct RecipeStep: Codable, Sendable, Equatable, Hashable {
    let title: String
    let instruction: String
    let durationMinutes: Int?

    init(title: String = "", instruction: String, durationMinutes: Int? = nil) {
        self.title = title
        self.instruction = instruction
        self.durationMinutes = durationMinutes
    }

    private enum CodingKeys: String, CodingKey {
        case title, instruction, durationMinutes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        instruction = try container.decode(String.self, forKey: .instruction)
        durationMinutes = try container.decodeIfPresent(Int.self, forKey: .durationMinutes)
    }
}

/// Where a recipe comes from.
enum RecipeOrigin: Codable, Sendable, Equatable, Hashable {
    /// Written from scratch for the user's ingredients.
    case generated
    /// Taken as-is from the local recipe library.
    case library
    /// Generated using a library recipe as its base.
    case adapted(fromTitle: String)
}

struct Recipe: Codable, Sendable, Identifiable, Equatable {
    let id: UUID
    let title: String
    let ingredients: [RecipeIngredient]
    let steps: [RecipeStep]
    let origin: RecipeOrigin

    init(
        id: UUID = UUID(),
        title: String,
        ingredients: [RecipeIngredient],
        steps: [RecipeStep],
        origin: RecipeOrigin = .generated
    ) {
        self.id = id
        self.title = title
        self.ingredients = ingredients
        self.steps = steps
        self.origin = origin
    }

    /// The same recipe under another identity.
    func with(id: UUID) -> Recipe {
        Recipe(id: id, title: title, ingredients: ingredients, steps: steps, origin: origin)
    }

    /// The same recipe from another origin.
    func with(origin: RecipeOrigin) -> Recipe {
        Recipe(id: id, title: title, ingredients: ingredients, steps: steps, origin: origin)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, ingredients, steps, origin
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        origin = try container.decodeIfPresent(RecipeOrigin.self, forKey: .origin) ?? .generated

        // Recipes saved before ingredients and steps were structured stored
        // both as plain strings: read either shape.
        if let structured = try? container.decode([RecipeIngredient].self, forKey: .ingredients) {
            ingredients = structured
        } else {
            ingredients = try container.decode([String].self, forKey: .ingredients).map { RecipeIngredient(name: $0) }
        }

        if let structured = try? container.decode([RecipeStep].self, forKey: .steps) {
            steps = structured
        } else {
            steps = try container.decode([String].self, forKey: .steps).map { RecipeStep(instruction: $0) }
        }
    }
}
