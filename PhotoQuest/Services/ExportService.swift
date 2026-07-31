import Photos
import UIKit

/// Экспорт достижений: PDF со всеми фотографиями и сохранение в системную галерею.
enum ExportService {

    enum ExportError: LocalizedError {
        case noItems
        case photoLibraryPermissionDenied
        case unknown(String)

        var errorDescription: String? {
            switch self {
            case .noItems:
                return "Нет выполненных заданий для экспорта."
            case .photoLibraryPermissionDenied:
                return "Нет разрешения на доступ к фотоальбому. Разрешите доступ в настройках."
            case .unknown(let message):
                return message
            }
        }
    }

    // MARK: - PDF

    /// Генерирует PDF со всеми заданиями (фото + текст + дата) и возвращает путь к файлу.
    static func makePDF(from items: [CompletedQuest]) -> URL? {
        guard !items.isEmpty else { return nil }

        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 в пунктах
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let data = renderer.pdfData { context in
            for item in items {
                context.beginPage()
                draw(item, in: context)
            }
        }

        let fileManager = FileManager.default
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Exports", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let url = directory.appendingPathComponent("PhotoQuest_\(formatter.string(from: Date())).pdf")

        do {
            try data.write(to: url)
            return url
        } catch {
            print("Ошибка записи PDF: \(error)")
            return nil
        }
    }

    /// Рисует одну страницу PDF: заголовок, фото (с сохранением пропорций), текст и дату.
    private static func draw(_ item: CompletedQuest, in context: UIGraphicsPDFRendererContext) {
        let page = context.pdfContextBounds

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 20),
            .foregroundColor: UIColor.label,
        ]
        let title = "\(Constants.appName) — \(item.date?.questString() ?? "")"
        (title as NSString).draw(at: CGPoint(x: 40, y: 36), withAttributes: titleAttributes)

        var y: CGFloat = 90
        if let image = item.loadImage() {
            let maxWidth = page.width - 80
            let maxHeight = page.height - 250
            let aspect = image.size.width / max(image.size.height, 1)
            var width = maxWidth
            var height = width / aspect
            if height > maxHeight {
                height = maxHeight
                width = height * aspect
            }
            image.draw(in: CGRect(x: (page.width - width) / 2, y: y, width: width, height: height))
            y += height + 24
        }

        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15),
            .foregroundColor: UIColor.label,
        ]
        (item.questText as NSString).draw(at: CGPoint(x: 40, y: y), withAttributes: textAttributes)
    }

    // MARK: - Сохранение в системную галерею

    /// Сохраняет все фотографии заданий в общую галерею телефона
    /// (с запросом разрешения NSPhotoLibraryAddUsageDescription).
    static func saveAllToPhotoLibrary(_ items: [CompletedQuest]) async -> Result<Void, Error> {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                guard status == .authorized || status == .limited else {
                    continuation.resume(returning: .failure(ExportError.photoLibraryPermissionDenied))
                    return
                }
                PHPhotoLibrary.shared().performChanges {
                    for item in items {
                        if let image = item.loadImage() {
                            PHAssetChangeRequest.creationRequestForAsset(from: image)
                        }
                    }
                } completionHandler: { success, error in
                    if success {
                        continuation.resume(returning: .success(()))
                    } else {
                        continuation.resume(returning: .failure(error ?? ExportError.unknown("Не удалось сохранить фотографии")))
                    }
                }
            }
        }
    }
}
