import CoreData
import UIKit

/// Сервис хранения: CoreData + файловая система.
///
/// - Модель CoreData создаётся программно (без .xcdatamodeld), поэтому
///   весь код готов к копированию в любой проект.
/// - Фотографии сохраняются в Documents/CompletedPhotos,
///   в базе хранится только путь к файлу.
/// - Все методы вызываются с главного потока (viewContext).
final class StorageService {

    static let shared = StorageService()

    private let container: NSPersistentContainer
    /// Папка, куда сохраняются фотографии выполненных заданий.
    let photosDirectory: URL

    private init() {
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        photosDirectory = documents.appendingPathComponent("CompletedPhotos", isDirectory: true)
        try? fileManager.createDirectory(at: photosDirectory, withIntermediateDirectories: true)

        container = NSPersistentContainer(name: "PhotoQuest", managedObjectModel: Self.makeManagedObjectModel())

        let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? fileManager.createDirectory(at: support, withIntermediateDirectories: true)
        let storeURL = support.appendingPathComponent("PhotoQuest.sqlite")

        let description = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error {
                // Повреждённое хранилище: удаляем и создаём заново.
                print("Ошибка загрузки хранилища: \(error). Пересоздаём...")
                try? fileManager.removeItem(at: storeURL)
                try? fileManager.removeItem(at: storeURL.appendingPathExtension("sqlite-wal"))
                try? fileManager.removeItem(at: storeURL.appendingPathExtension("sqlite-shm"))
                self.container.loadPersistentStores { _, secondError in
                    if let secondError {
                        assertionFailure("Не удалось создать хранилище CoreData: \(secondError)")
                    }
                }
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true

    private var context: NSManagedObjectContext { container.viewContext }

    private func saveContext() {
        guard context.hasChanges else { return }
        do { try context.save() }
        catch { print("Ошибка сохранения CoreData: \(error)") }
    }

    // MARK: - Программная модель CoreData

    private static func makeManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let questEntity = NSEntityDescription()
        questEntity.name = "QuestItem"
        questEntity.managedObjectClassName = NSStringFromClass(QuestItem.self)
        questEntity.properties = [
            attribute("text", .stringAttributeType),
            attribute("category", .stringAttributeType),
            attribute("sortOrder", .integer64AttributeType),
            attribute("isCompleted", .booleanAttributeType),
            attribute("createdAt", .dateAttributeType),
        ]

        let completedEntity = NSEntityDescription()
        completedEntity.name = "CompletedQuest"
        completedEntity.managedObjectClassName = NSStringFromClass(CompletedQuest.self)
        completedEntity.properties = [
            attribute("photoPath", .stringAttributeType),
            attribute("questText", .stringAttributeType),
            attribute("date", .dateAttributeType),
        ]

        model.entities = [questEntity, completedEntity]
        return model
    }

    private static func attribute(_ name: String, _ type: NSAttributeType) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        switch type {
        case .stringAttributeType: attribute.defaultValue = ""
        case .booleanAttributeType: attribute.defaultValue = false
        case .integer64AttributeType: attribute.defaultValue = 0
        default: break
        }
        return attribute
    }

    // MARK: - Очередь заданий

    /// Создаёт стартовую очередь из 100 перемешанных заданий (только при первом запуске).
    func seedIfNeeded(quests: [QuestDefinition]) {
        let request = NSFetchRequest<QuestItem>(entityName: "QuestItem")
        let count = (try? context.count(for: request)) ?? 0
        guard count == 0 else { return }
        for (index, quest) in quests.shuffled().enumerated() {
            let item = QuestItem(context: context)
            item.text = quest.text
            item.category = quest.category
            item.sortOrder = Int64(index)
            item.isCompleted = false
            item.createdAt = Date()
        }
        saveContext()
    }

    /// Текущее задание — первое невыполненное в очереди.
    func currentQuest() -> QuestItem? {
        let request = NSFetchRequest<QuestItem>(entityName: "QuestItem")
        request.predicate = NSPredicate(format: "isCompleted == NO")
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }

    private func questItem(withText text: String) -> QuestItem? {
        let request = NSFetchRequest<QuestItem>(entityName: "QuestItem")
        request.predicate = NSPredicate(format: "text == %@", text)
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }

    /// «Пропуск»: задание получает максимальный порядок и уходит в конец очереди.
    func moveToEnd(text: String) {
        guard let item = questItem(withText: text), !item.isCompleted else { return }
        let request = NSFetchRequest<QuestItem>(entityName: "QuestItem")
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: false)]
        request.fetchLimit = 1
        let maxOrder = (try? context.fetch(request))?.first?.sortOrder ?? 0
        item.sortOrder = maxOrder + 1
        saveContext()
    }

    /// Завершает задание: сохраняет фото в Documents/CompletedPhotos
    /// и создаёт запись CompletedQuest в базе.
    @discardableResult
    func completeQuest(text: String, image: UIImage) -> Bool {
        guard let item = questItem(withText: text) else { return false }
        guard let data = image.jpegData(compressionQuality: 0.85) else { return false }

        let fileName = UUID().uuidString + ".jpg"
        let fileURL = photosDirectory.appendingPathComponent(fileName)
        do { try data.write(to: fileURL) } catch { return false }

        item.isCompleted = true

        let completed = CompletedQuest(context: context)
        completed.questText = item.text
        completed.photoPath = fileURL.path
        completed.date = Date()

        saveContext()
        return true
    }

    /// Прогресс: количество выполненных заданий и общее число.
    func counts() -> (done: Int, total: Int) {
        let totalRequest = NSFetchRequest<QuestItem>(entityName: "QuestItem")
        let total = (try? context.count(for: totalRequest)) ?? 0
        let doneRequest = NSFetchRequest<QuestItem>(entityName: "QuestItem")
        doneRequest.predicate = NSPredicate(format: "isCompleted == YES")
        let done = (try? context.count(for: doneRequest)) ?? 0
        return (done, total)
    }

    /// «Начать заново»: удаляет все задания и заново создаёт перемешанную очередь.
    /// История галереи (CompletedQuest) при этом сохраняется.
    func resetQuests() {
        let request = NSFetchRequest<QuestItem>(entityName: "QuestItem")
        if let items = try? context.fetch(request) {
            for item in items { context.delete(item) }
            saveContext()
        }
    }

    // MARK: - Выполненные задания

    /// Последние выполненные задания (для миниатюр на главном экране).
    func recentCompleted(limit: Int = 5) -> [CompletedQuest] {
        let request = NSFetchRequest<CompletedQuest>(entityName: "CompletedQuest")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        request.fetchLimit = limit
        return (try? context.fetch(request)) ?? []
    }

    /// Все выполненные задания, свежие сверху.
    func fetchCompletedQuests() -> [CompletedQuest] {
        let request = NSFetchRequest<CompletedQuest>(entityName: "CompletedQuest")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    /// Удаляет задание из галереи вместе с файлом фото.
    func deleteCompleted(_ quest: CompletedQuest) {
        try? FileManager.default.removeItem(atPath: quest.photoPath)
        context.delete(quest)
        saveContext()
    }
}
