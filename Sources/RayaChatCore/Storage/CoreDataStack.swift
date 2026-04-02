import Foundation
import CoreData

/// Core Data stack for message persistence.
/// Uses a programmatic model definition (no .xcdatamodeld file needed for SPM).
final class CoreDataStack: @unchecked Sendable {

    static let shared = CoreDataStack()

    let container: NSPersistentContainer

    /// Background context for write operations — never blocks main thread.
    lazy var backgroundContext: NSManagedObjectContext = {
        let ctx = container.newBackgroundContext()
        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return ctx
    }()

    /// Main thread context for reads.
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    private init() {
        let model = CoreDataStack.createModel()
        container = NSPersistentContainer(name: Constants.coreDataModelName, managedObjectModel: model)

        let description = NSPersistentStoreDescription()
        description.type = NSSQLiteStoreType
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error = error {
                print("[RayaChat.CoreData] Failed to load store: \(error.localizedDescription)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// For unit tests — in-memory store.
    init(inMemory: Bool) {
        let model = CoreDataStack.createModel()
        container = NSPersistentContainer(name: Constants.coreDataModelName, managedObjectModel: model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("[RayaChat.CoreData] In-memory store failed: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    // MARK: - Programmatic Model

    private static func createModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let entity = NSEntityDescription()
        entity.name = Constants.messagesEntityName
        entity.managedObjectClassName = NSStringFromClass(MessageEntity.self)

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .stringAttributeType
        idAttr.isOptional = false

        let senderAttr = NSAttributeDescription()
        senderAttr.name = "sender"
        senderAttr.attributeType = .integer32AttributeType
        senderAttr.defaultValue = 0

        let typeAttr = NSAttributeDescription()
        typeAttr.name = "messageType"
        typeAttr.attributeType = .integer32AttributeType
        typeAttr.defaultValue = 1

        let contentAttr = NSAttributeDescription()
        contentAttr.name = "content"
        contentAttr.attributeType = .stringAttributeType
        contentAttr.isOptional = true

        let createdAtAttr = NSAttributeDescription()
        createdAtAttr.name = "createdAt"
        createdAtAttr.attributeType = .stringAttributeType
        createdAtAttr.isOptional = true

        let attachmentsJsonAttr = NSAttributeDescription()
        attachmentsJsonAttr.name = "attachmentsJson"
        attachmentsJsonAttr.attributeType = .stringAttributeType
        attachmentsJsonAttr.isOptional = true

        let audioJsonAttr = NSAttributeDescription()
        audioJsonAttr.name = "audioJson"
        audioJsonAttr.attributeType = .stringAttributeType
        audioJsonAttr.isOptional = true

        let insertOrderAttr = NSAttributeDescription()
        insertOrderAttr.name = "insertOrder"
        insertOrderAttr.attributeType = .integer64AttributeType
        insertOrderAttr.defaultValue = 0

        entity.properties = [idAttr, senderAttr, typeAttr, contentAttr, createdAtAttr, attachmentsJsonAttr, audioJsonAttr, insertOrderAttr]

        model.entities = [entity]
        return model
    }
}

// MARK: - MessageEntity (NSManagedObject)

@objc(MessageEntity)
public class MessageEntity: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var sender: Int32
    @NSManaged public var messageType: Int32
    @NSManaged public var content: String?
    @NSManaged public var createdAt: String?
    @NSManaged public var attachmentsJson: String?
    @NSManaged public var audioJson: String?
    @NSManaged public var insertOrder: Int64

    func toTypeMessage() -> TypeMessage {
        TypeMessage(
            id: id,
            sender: Int(sender),
            type: Int(messageType),
            content: content,
            createdAt: createdAt,
            attachmentsJson: attachmentsJson,
            audioJson: audioJson
        )
    }
}
