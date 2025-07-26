import Foundation
import CoreData

final class PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer

    private init(inMemory: Bool = false) {
        let model = NSManagedObjectModel()
        // Define entity
        let recipeEntity = NSEntityDescription()
        recipeEntity.name = "RecipeEntity"
        recipeEntity.managedObjectClassName = NSStringFromClass(RecipeEntity.self)
        let textAttribute = NSAttributeDescription()
        textAttribute.name = "text"
        textAttribute.attributeType = .stringAttributeType
        textAttribute.isOptional = false
        recipeEntity.properties = [textAttribute]
        model.entities = [recipeEntity]

        container = NSPersistentContainer(name: "RecipeModel", managedObjectModel: model)
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        return controller
    }()
}

@objc(RecipeEntity)
final class RecipeEntity: NSManagedObject {
    @NSManaged var text: String
}
