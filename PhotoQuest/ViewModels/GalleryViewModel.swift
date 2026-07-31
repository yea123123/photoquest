import SwiftUI

/// ViewModel экрана галереи.
@MainActor
final class GalleryViewModel: ObservableObject {

    @Published private(set) var items: [CompletedQuest] = []
    @Published var isExporting = false

    private let storage: StorageService

    init(storage: StorageService) {
        self.storage = storage
    }

    func refresh() {
        items = storage.fetchCompletedQuests()
    }

    /// Удаление по свайпу (вместе с файлом фото).
    func delete(at offsets: IndexSet) {
        for index in offsets where items.indices.contains(index) {
            storage.deleteCompleted(items[index])
        }
        refresh()
    }

    /// Создаёт PDF со всеми фотографиями (в фоне) и возвращает путь к файлу.
    func exportPDF() async -> URL? {
        let snapshot = items
        return await Task.detached(priority: .userInitiated) {
            ExportService.makePDF(from: snapshot)
        }.value
    }

    /// Сохраняет все фотографии в системную галерею (с запросом разрешения).
    func saveAllToLibrary() async -> Result<Void, Error> {
        await ExportService.saveAllToPhotoLibrary(items)
    }
}
