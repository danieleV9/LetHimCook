import Foundation
import CoreData

final class CoreDataSavedRecipesRepository: SavedRecipeRepository {
    private let viewContext: NSManagedObjectContext

    init(container: NSPersistentContainer = PersistenceController.shared.container) {
        self.viewContext = container.viewContext
    }

    func fetchRecipes() async -> [Recipe] {
        let request = NSFetchRequest<RecipeEntity>(entityName: "RecipeEntity")
        do {
            let entities = try viewContext.fetch(request)
            return entities.compactMap { Recipe(text: $0.text) }
        } catch {
            return []
        }
    }

    func save(recipe: Recipe) async {
        let entity = RecipeEntity(context: viewContext)
        entity.text = recipe.text
        do {
            try viewContext.save()
        } catch {
            print("Failed to save: \(error)")
        }

        let request = NSFetchRequest<RecipeEntity>(entityName: "RecipeEntity")
        request.sortDescriptors = [] // No timestamp, so keep fetch order
        do {
            let allRecipes = try viewContext.fetch(request)
            if allRecipes.count > 5 {
                let toDelete = allRecipes.prefix(allRecipes.count - 5)
                for entity in toDelete {
                    viewContext.delete(entity)
                }
                try viewContext.save()
            }
        } catch {
            print("Failed to trim old recipes: \(error)")
        }
    }
}
