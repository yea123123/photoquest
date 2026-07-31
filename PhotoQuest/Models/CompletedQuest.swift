import CoreData
import UIKit

/// CoreData-сущность: выполненное задание с фотографией.
/// Само фото лежит в папке Documents/CompletedPhotos, в базе хранится путь к файлу.
@objc(CompletedQuest)
public class CompletedQuest: NSManagedObject {
    @NSManaged public var photoPath: String
    @NSManaged public var questText: String
    @NSManaged public var date: Date?

    /// Загружает фотографию задания из файловой системы.
    func loadImage() -> UIImage? {
        guard !photoPath.isEmpty else { return nil }
        return UIImage(contentsOfFile: photoPath)
    }
}
