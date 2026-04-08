import Foundation
import CoreData

/// CRUD operations for messages in Core Data.
/// All writes happen on background context; reads can use either context.
final class MessageStore: @unchecked Sendable {

    private let stack: CoreDataStack

    init(stack: CoreDataStack = .shared) {
        self.stack = stack
    }

    // MARK: - Read

    /// Fetches all messages ordered by insertOrder. Uses background context to avoid blocking main thread.
    func getAll() -> [TypeMessage] {
        let context = stack.backgroundContext
        var result: [TypeMessage] = []
        context.performAndWait {
            let request = NSFetchRequest<MessageEntity>(entityName: Constants.messagesEntityName)
            request.sortDescriptors = [NSSortDescriptor(key: "insertOrder", ascending: true)]
            do {
                let entities = try context.fetch(request)
                result = entities.map { $0.toTypeMessage() }
            } catch {
                print("[RayaChat.MessageStore] getAll failed: \(error)")
            }
        }
        return result
    }

    /// Fetches the last message by insertOrder. Uses background context.
    func getLastMessage() -> TypeMessage? {
        let context = stack.backgroundContext
        var result: TypeMessage?
        context.performAndWait {
            let request = NSFetchRequest<MessageEntity>(entityName: Constants.messagesEntityName)
            request.sortDescriptors = [NSSortDescriptor(key: "insertOrder", ascending: false)]
            request.fetchLimit = 1
            result = (try? context.fetch(request))?.first?.toTypeMessage()
        }
        return result
    }

    /// Count of stored messages. Uses background context.
    func count() -> Int {
        let context = stack.backgroundContext
        var result = 0
        context.performAndWait {
            let request = NSFetchRequest<MessageEntity>(entityName: Constants.messagesEntityName)
            result = (try? context.count(for: request)) ?? 0
        }
        return result
    }

    // MARK: - Write (background context)

    /// Inserts or updates a message. Runs on background context.
    func insert(_ message: TypeMessage) {
        let context = stack.backgroundContext
        context.performAndWait {
            // Check if exists (upsert)
            let request = NSFetchRequest<MessageEntity>(entityName: Constants.messagesEntityName)
            request.predicate = NSPredicate(format: "id == %@", message.id)
            request.fetchLimit = 1

            let entity: MessageEntity
            if let existing = (try? context.fetch(request))?.first {
                entity = existing
            } else {
                entity = NSEntityDescription.insertNewObject(
                    forEntityName: Constants.messagesEntityName,
                    into: context
                ) as! MessageEntity
                // Assign insertOrder for ordering
                entity.insertOrder = Int64(Date().timeIntervalSince1970 * 1000)
            }

            entity.id = message.id
            entity.sender = Int32(message.sender)
            entity.messageType = Int32(message.type)
            entity.content = message.content
            entity.createdAt = message.createdAt
            entity.attachmentsJson = message.attachmentsJson
            entity.audioJson = message.audioJson

            saveContext(context)
        }
    }

    /// Trims messages to keep only the latest N (by insertOrder).
    func trimToLatest(_ limit: Int = Constants.maxMessagesInMemory) {
        let context = stack.backgroundContext
        context.performAndWait {
            let countRequest = NSFetchRequest<MessageEntity>(entityName: Constants.messagesEntityName)
            let total = (try? context.count(for: countRequest)) ?? 0

            guard total > limit else { return }

            let request = NSFetchRequest<MessageEntity>(entityName: Constants.messagesEntityName)
            request.sortDescriptors = [NSSortDescriptor(key: "insertOrder", ascending: true)]
            request.fetchLimit = total - limit

            if let toDelete = try? context.fetch(request) {
                for entity in toDelete {
                    context.delete(entity)
                }
                saveContext(context)
            }
        }
    }

    /// Deletes all messages.
    func deleteAll() {
        let context = stack.backgroundContext
        context.performAndWait {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: Constants.messagesEntityName)
            let batchDelete = NSBatchDeleteRequest(fetchRequest: request)
            do {
                try context.execute(batchDelete)
                saveContext(context)
            } catch {
                print("[RayaChat.MessageStore] deleteAll failed: \(error)")
            }
        }
    }

    // MARK: - Private

    private func saveContext(_ context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("[RayaChat.MessageStore] save failed: \(error)")
        }
    }
}
