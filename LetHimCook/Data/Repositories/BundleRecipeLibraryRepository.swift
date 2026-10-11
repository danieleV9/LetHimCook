import Foundation

/// Reads the recipe library shipped in the app bundle (`recipes.json`).
///
/// The file is decoded once and kept in memory. A missing or malformed file
/// is logged and treated as an empty library, so generation still works.
final class BundleRecipeLibraryRepository: RecipeLibraryRepository {
    private struct LibraryFile: Decodable {
        let recipes: [LibraryRecipe]
    }

    private let fileURL: URL?
    private let language: String
    private let logger: Logger?
    private var cache: [LibraryRecipe]?

    /// - Parameters:
    ///   - fileURL: The library file. Defaults to `recipes.json` in the main bundle.
    ///   - language: Only recipes in this language are returned. Defaults to the app's language.
    init(
        fileURL: URL? = Bundle.main.url(forResource: "recipes", withExtension: "json"),
        language: String = BundleRecipeLibraryRepository.appLanguage,
        logger: Logger? = nil
    ) {
        self.fileURL = fileURL
        self.language = language
        self.logger = logger
    }

    /// The language the app is running in, matching the bundle's localizations.
    static var appLanguage: String {
        Bundle.main.preferredLocalizations.first.map { String($0.prefix(2)) } ?? "en"
    }

    func recipes() async -> [LibraryRecipe] {
        allRecipes().filter { $0.language.lowercased() == language.lowercased() }
    }

    private func allRecipes() -> [LibraryRecipe] {
        if let cache { return cache }

        let loaded = load()
        cache = loaded
        return loaded
    }

    private func load() -> [LibraryRecipe] {
        guard let fileURL else {
            logger?.debug("Recipe library not found in bundle")
            return []
        }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(LibraryFile.self, from: data).recipes
        } catch {
            logger?.error("Failed to load recipe library: \(error)")
            return []
        }
    }
}
