import CoreData

/// CoreData-сущность: задание из очереди.
/// - text: текст задания
/// - category: категория («Животные», «Дом», ...)
/// - sortOrder: порядок в очереди (пропущенное задание получает максимальный порядок — уходит в конец)
/// - isCompleted: выполнено ли задание
/// - createdAt: дата создания
@objc(QuestItem)
public class QuestItem: NSManagedObject {
    @NSManaged public var text: String
    @NSManaged public var category: String
    @NSManaged public var sortOrder: Int64
    @NSManaged public var isCompleted: Bool
    @NSManaged public var createdAt: Date?
}
