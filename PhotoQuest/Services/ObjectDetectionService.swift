import CoreML
import UIKit
import Vision

/// Результат классификации: идентификатор класса и уверенность.
struct DetectionResult {
    let identifier: String
    let confidence: Float
}

/// Сервис детекции объектов через Core ML (MobileNetV2) + Vision.
/// Всё происходит на устройстве, без интернета.
final class ObjectDetectionService {

    static let shared = ObjectDetectionService()

    /// Готова ли модель к работе (файл .mlmodel добавлен в проект).
    private(set) var isModelAvailable: Bool

    private let model: VNCoreMLModel?

    private init() {
        // Xcode компилирует .mlmodel в .mlmodelc — ищем оба варианта.
        if let url = Bundle.main.url(forResource: Constants.modelFileName, withExtension: "mlmodelc")
            ?? Bundle.main.url(forResource: Constants.modelFileName, withExtension: "mlmodel"),
           let mlModel = try? MLModel(contentsOf: url),
           let visionModel = try? VNCoreMLModel(for: mlModel) {
            self.model = visionModel
            self.isModelAvailable = true
        } else {
            self.model = nil
            self.isModelAvailable = false
        }
    }

    // MARK: - Классификация

    /// Классифицирует изображение, возвращает топ-1 результат.
    /// Тяжёлая работа (handler.perform) выполняется в фоне;
    /// результат возвращается вызывающему коду, уже готовый к применению.
    func classify(_ image: UIImage) async -> DetectionResult? {
        guard let model, let cgImage = image.cgImage else { return nil }

        let request = VNCoreMLRequest(model: model)
        request.imageCropAndScaleOption = .centerCrop

        return await Task.detached(priority: .userInitiated) { () -> DetectionResult? in
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("Ошибка классификации: \(error)")
                return nil
            }
            guard let results = request.results as? [VNClassificationObservation],
                  let top = results.first else { return nil }
            return DetectionResult(identifier: top.identifier, confidence: top.confidence)
        }.value
    }

    // MARK: - Проверка соответствия

    /// Условие успеха: уверенность выше порога И найденный класс есть в списке
    /// ключевых слов для данного задания.
    func isMatch(result: DetectionResult, keywords: [String]) -> Bool {
        guard result.confidence >= Constants.minConfidence else { return false }
        return keywords.contains { keyword in
            Self.keywordsMatch(result.identifier, keyword: keyword)
        }
    }

    /// Сравнивает идентификатор класса из модели со словом из словаря.
    /// Сравнение по словам в нижнем регистре:
    /// - «cat» совпадёт с классом «tiger cat» (общее слово);
    /// - «cat» совпадёт с классом «tiger cat» (общее слово);
    /// - «dog» НЕ совпадёт с «housefly»-подобными составными словами
    ///   (например, с классом «dog sled» — нет, «dog» входит в «hotdog, hot dog»,
    ///   поэтому фото хот-дога может засчитаться как собака — редкий и безвредный случай);
    /// - длинное словосочетание считается совпадением, если содержится целиком
    ///   (например, «golden retriever» внутри «golden retriever, golden retriever dog»).
    static func keywordsMatch(_ identifier: String, keyword: String) -> Bool {
        let id = identifier.lowercased()
        let kw = keyword.lowercased().trimmingCharacters(in: .whitespaces)
        guard !kw.isEmpty else { return false }

        if id == kw { return true }

        let idWords = Set(id.split { !$0.isLetter }.map(String.init))
        let kwWords = Set(kw.split { !$0.isLetter }.map(String.init))
        if !idWords.isDisjoint(with: kwWords) { return true }
        if kwWords.count > 1 && id.contains(kw) { return true }
        return false
    }
}
