import Foundation

/// Picks the library recipe that best fits the user's ingredients.
///
/// Matching works on normalized word sets: lowercase, no accents, a light
/// plural stemming for Italian and English, and filler words dropped. Two
/// ingredient names match when the words of one are all found in the other,
/// so "pomodori" matches "pomodori pelati" and "eggs" matches "egg".
struct RecipeMatcher: Sendable {
    enum Outcome: Equatable {
        /// The user has everything the recipe needs: show it as it is.
        case exact(LibraryRecipe)
        /// The recipe is close enough to be adapted to the user's ingredients.
        case reference(LibraryRecipe)
        case noMatch
    }

    /// Share of the recipe's ingredients the user must have for an exact match.
    static let exactRecipeCoverage = 1.0
    /// Share of the user's ingredients an exact match must use, so a three-item
    /// recipe isn't served to someone who listed ten ingredients.
    static let exactInputUsage = 0.6
    /// Share of the recipe's ingredients the user must have to adapt it.
    static let referenceRecipeCoverage = 0.5

    private static let fillerWords: Set<String> = [
        "d", "l", "di", "da", "del", "della", "dello", "dei", "degli", "delle", "al", "alla", "e", "in", "con",
        "fresco", "fresca", "freschi", "fresche",
        "of", "the", "a", "and", "with", "fresh"
    ]

    func bestMatch(for ingredients: [String], in library: [LibraryRecipe]) -> Outcome {
        let userItems = ingredients.map { Self.normalize($0) }.filter { !$0.isEmpty }
        guard !userItems.isEmpty else { return .noMatch }

        var best: (outcome: Outcome, rank: Int, score: Double)?

        for recipe in library {
            let recipeItems = recipe.ingredients.map { (words: Self.normalize($0.name), pantry: $0.pantry) }
            let required = recipeItems.filter { !$0.pantry && !$0.words.isEmpty }.map { $0.words }
            guard !required.isEmpty else { continue }

            let covered = required.filter { item in userItems.contains { Self.matches($0, item) } }
            let recipeCoverage = Double(covered.count) / Double(required.count)

            let used = userItems.filter { user in recipeItems.contains { Self.matches(user, $0.words) } }
            let inputUsage = Double(used.count) / Double(userItems.count)

            let outcome: Outcome
            let rank: Int
            if recipeCoverage >= Self.exactRecipeCoverage && inputUsage >= Self.exactInputUsage {
                outcome = .exact(recipe)
                rank = 2
            } else if recipeCoverage >= Self.referenceRecipeCoverage {
                outcome = .reference(recipe)
                rank = 1
            } else {
                continue
            }

            let score = recipeCoverage + inputUsage
            if let current = best, current.rank > rank || (current.rank == rank && current.score >= score) {
                continue
            }
            best = (outcome, rank, score)
        }

        return best?.outcome ?? .noMatch
    }

    // MARK: - Normalization

    static func normalize(_ name: String) -> Set<String> {
        let folded = name
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .lowercased()
        let words = folded
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { !$0.isEmpty && !fillerWords.contains($0) }
        return Set(words.map { stem($0) })
    }

    /// Drops a plural "s" and trailing vowels so singular and plural forms
    /// meet: "pomodori" and "pomodoro" become "pomodor", "eggs" becomes "egg".
    static func stem(_ word: String) -> String {
        var result = Substring(word)
        if result.count > 3, result.hasSuffix("s") {
            result = result.dropLast()
        }
        while result.count > 3, let last = result.last, "aeiou".contains(last) {
            result = result.dropLast()
        }
        return String(result)
    }

    static func matches(_ lhs: Set<String>, _ rhs: Set<String>) -> Bool {
        guard !lhs.isEmpty, !rhs.isEmpty else { return false }
        return lhs.isSubset(of: rhs) || rhs.isSubset(of: lhs)
    }
}
