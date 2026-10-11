import Foundation

/// A recipe from the local library, as stored in `recipes.json`.
struct LibraryRecipe: Codable, Sendable, Equatable, Identifiable {
    struct Ingredient: Codable, Sendable, Equatable {
        let quantity: String?
        let unit: String?
        let name: String
        /// Kitchen basics (salt, oil, water…) the user is assumed to have.
        /// They don't count when matching the user's ingredients.
        let pantry: Bool

        init(quantity: String? = nil, unit: String? = nil, name: String, pantry: Bool = false) {
            self.quantity = quantity
            self.unit = unit
            self.name = name
            self.pantry = pantry
        }

        private enum CodingKeys: String, CodingKey {
            case quantity, unit, name, pantry
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            quantity = try container.decodeIfPresent(String.self, forKey: .quantity)
            unit = try container.decodeIfPresent(String.self, forKey: .unit)
            name = try container.decode(String.self, forKey: .name)
            pantry = try container.decodeIfPresent(Bool.self, forKey: .pantry) ?? false
        }
    }

    let id: String
    /// ISO 639-1 code of the language the recipe is written in, e.g. "it".
    let language: String
    let title: String
    let tags: [String]
    let ingredients: [Ingredient]
    let steps: [RecipeStep]

    init(
        id: String,
        language: String,
        title: String,
        tags: [String] = [],
        ingredients: [Ingredient],
        steps: [RecipeStep]
    ) {
        self.id = id
        self.language = language
        self.title = title
        self.tags = tags
        self.ingredients = ingredients
        self.steps = steps
    }

    private enum CodingKeys: String, CodingKey {
        case id, language, title, tags, ingredients, steps
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        language = try container.decode(String.self, forKey: .language)
        title = try container.decode(String.self, forKey: .title)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        ingredients = try container.decode([Ingredient].self, forKey: .ingredients)
        steps = try container.decode([RecipeStep].self, forKey: .steps)
    }

    /// The library recipe as a displayable `Recipe`.
    func toRecipe(id: UUID = UUID(), origin: RecipeOrigin = .library) -> Recipe {
        Recipe(
            id: id,
            title: title,
            ingredients: ingredients.map { RecipeIngredient(quantity: $0.quantity, unit: $0.unit, name: $0.name) },
            steps: steps,
            origin: origin
        )
    }
}
