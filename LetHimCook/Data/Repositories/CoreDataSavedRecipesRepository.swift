import Foundation
import CoreData

final class CoreDataSavedRecipesRepository: SavedRecipeRepository {
    private let viewContext: NSManagedObjectContext

    init(container: NSPersistentContainer = PersistenceController.shared.container) {
        self.viewContext = container.viewContext
    }

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    func fetchRecipes() async -> [Recipe] {
        let request = NSFetchRequest<RecipeEntity>(entityName: "RecipeEntity")
        do {
            let entities = try viewContext.fetch(request)
            return entities.compactMap { entity in
                guard let data = entity.text.data(using: .utf8) else { return nil }
                return try? decoder.decode(Recipe.self, from: data)
            }
        } catch {
            return []
        }
    }

    func save(recipe: Recipe) async {
        guard let data = try? encoder.encode(recipe),
              let json = String(data: data, encoding: .utf8) else {
            return
        }

        let entity = RecipeEntity(context: viewContext)
        entity.text = json
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

    func deleteAll() async {
        await viewContext.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "RecipeEntity")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                try self.viewContext.execute(deleteRequest)
                try self.viewContext.save()
            } catch {
                print("Failed to delete recipes: \(error)")
            }
        }
    }
}
