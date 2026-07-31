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

    /// Классифицирует изображение и возвращает топ-5 результатов (по убыванию уверенности).
    /// Кадр анализируется тремя способами обрезки (центр/растяжение/вписать), результаты
    /// объединяются по классам — так объект находится, даже если он не в центре кадра.
    /// Тяжёлая работа (handler.perform) выполняется в фоне.
    func classify(_ image: UIImage) async -> [DetectionResult] {
        guard let model, let cgImage = image.cgImage else { return [] }

        return await Task.detached(priority: .userInitiated) { () -> [DetectionResult] in
            let crops: [VNImageCropAndScaleOption] = [.centerCrop, .scaleFill, .scaleFit]
            var bestByClass: [String: Float] = [:]

            for crop in crops {
                let request = VNCoreMLRequest(model: model)
                request.imageCropAndScaleOption = crop
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                } catch {
                    print("Ошибка классификации: \(error)")
                    continue
                }
                guard let observations = request.results as? [VNClassificationObservation] else { continue }
                for observation in observations where observation.confidence > 0.01 {
                    bestByClass[observation.identifier] = max(bestByClass[observation.identifier] ?? 0,
                                                               observation.confidence)
                }
            }

            return bestByClass
                .map { DetectionResult(identifier: $0.key, confidence: $0.value) }
                .sorted { $0.confidence > $1.confidence }
                .prefix(10)
                .map { $0 }
        }.value
    }

    // MARK: - Проверка соответствия

    /// Условие успеха: класс из списка ключевых слов попал в топ-10 результатов.
    /// Первые три ответа модели — её главные кандидаты: если среди них есть
    /// нужный класс, задание засчитывается (порог почти символический).
    /// Остальные места топ-10 проверяются с порогом из настроек
    /// («Чувствительность детекта»), чтобы не засчитывать случайные догадки.
    @MainActor
    func isMatch(results: [DetectionResult], keywords: [String]) -> Bool {
        let sensitivity = GameSettings.shared.sensitivity
        for (index, result) in results.enumerated() {
            let threshold: Float = index < 3 ? sensitivity.topFloor : sensitivity.restThreshold
            guard result.confidence >= threshold else { continue }
            if keywords.contains(where: { Self.keywordsMatch(result.identifier, keyword: $0) }) {
                return true
            }
        }
        return false
    }

    /// Находит ключ словаря, которому модель дала максимальную уверенность
    /// (для «Угадай-ки»: что лучше всего подходит к этому фото).
    func bestKey(for results: [DetectionResult]) -> (key: String, confidence: Float)? {
        var best: (key: String, confidence: Float)?
        for (key, classes) in QuestKeywords.all {
            let score = classes.reduce(Float(0)) { partial, className in
                max(partial, results.first { Self.keywordsMatch($0.identifier, keyword: className) }?.confidence ?? 0)
            }
            if score > (best?.confidence ?? 0) {
                best = (key, score)
            }
        }
        return best
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
