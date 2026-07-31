import SwiftUI
import UIKit

/// ViewModel экрана камеры: съёмка, детекция, состояния успеха/ошибки.
@MainActor
final class CameraViewModel: ObservableObject {

    enum Phase {
        case idle      // видоискатель
        case checking  // идёт проверка нейросетью
        case success   // зелёная галочка
        case failure   // не похоже на задание
    }

    @Published var phase: Phase = .idle
    /// Последний снимок — показывается поверх видоискателя во время проверки.
    @Published var capturedPhoto: UIImage?
    /// Что распознала нейросеть (топ-3 класса, для сообщения об ошибке).
    @Published var detectedLabel: String?
    @Published var permissionDenied = false
    @Published var modelMissing = false
    @Published var cameraUnavailable = false
    @Published var flashOn = false
    @Published var showFailureAlert = false
    @Published var showModelSheet = false
    /// Очки за последний снимок (показываются в оверлее успеха).
    @Published private(set) var lastPointsEarned = 0
    /// Бонус за первый квест дня (показывается в оверлее успеха).
    @Published private(set) var lastDayBonus = 0

    let camera = CameraService()
    let questText: String

    /// Момент открытия экрана камеры — для бонуса за скорость.
    private let openedAt = Date()

    private let detector = ObjectDetectionService.shared
    private let keywords: [String]
    /// Вторая группа ключевых слов (для «Дуэта»: нужно заснять оба предмета).
    private let keywordsB: [String]?
    /// Фиксированная награда за снимок в режиме мини-игр (квесты — nil).
    private let pointsOverride: Int?
    private let onComplete: (UIImage) -> Void
    private let onFinish: (Bool) -> Void

    init(questText: String,
         keywords: [String],
         keywordsB: [String]? = nil,
         pointsOverride: Int? = nil,
         onComplete: @escaping (UIImage) -> Void,
         onFinish: @escaping (Bool) -> Void) {
        self.questText = questText
        self.keywords = keywords
        self.keywordsB = keywordsB
        self.pointsOverride = pointsOverride
        self.onComplete = onComplete
        self.onFinish = onFinish
        flashOn = GameSettings.shared.flashMode == .on
    }

    // MARK: - Жизненный цикл

    /// Запрашивает разрешение на камеру, проверяет модель и запускает сессию.
    /// Камера запускается всегда — модель нужна только для автопроверки фото.
    func start() async {
        let authorized = await camera.requestAuthorization()
        guard authorized else {
            permissionDenied = true
            return
        }
        camera.start { [weak self] ok in
            Task { @MainActor in
                self?.cameraUnavailable = !ok
            }
        }
        if !detector.isModelAvailable {
            modelMissing = true
            showModelSheet = true
        }
    }

    func toggleFlash() {
        flashOn.toggle()
    }

    // MARK: - Съёмка и проверка

    /// Спуск затвора: делает фото и запускает проверку.
    func capture() {
        guard phase != .checking, !permissionDenied else { return }
        Haptics.shutter()
        camera.photoHandler = { [weak self] data in
            self?.handlePhoto(data)
        }
        camera.capture(flashOn: flashOn)
    }

    private func handlePhoto(_ data: Data) {
        guard let image = UIImage(data: data) else { return }
        capturedPhoto = image
        phase = .checking
        Task { await runDetection(image) }
    }

    /// Классификация через Core ML + Vision.
    /// Классификация выполняется в фоне, результат применяется на главном потоке.
    private func runDetection(_ image: UIImage) async {
        guard detector.isModelAvailable else {
            // Модели нет: фото остаётся на экране, предлагаем сохранить вручную.
            phase = .idle
            modelMissing = true
            showModelSheet = true
            return
        }
        let results = await detector.classify(image)
        guard !results.isEmpty else {
            detectedLabel = nil
            presentFailure()
            return
        }
        detectedLabel = results.prefix(3)
            .map { "\($0.identifier) (\(Int($0.confidence * 100))%)" }
            .joined(separator: ", ")

        let ok: Bool
        if let keywordsB {
            ok = detector.isMatch(results: results, keywords: keywords)
                && detector.isMatch(results: results, keywords: keywordsB)
        } else {
            ok = detector.isMatch(results: results, keywords: keywords)
        }
        if ok {
            await succeed(image, confidence: results.first?.confidence)
        } else {
            presentFailure()
        }
    }

    /// Сохранить фото без проверки нейросетью (модель отсутствует).
    func saveWithoutCheck() {
        guard let image = capturedPhoto else { return }
        showModelSheet = false
        Task { await succeed(image, confidence: nil) }
    }

    /// Закрыть предупреждение о модели и вернуться к видоискателю.
    func dismissModelSheet() {
        showModelSheet = false
        capturedPhoto = nil
        phase = .idle
    }

    private func presentFailure() {
        phase = .failure
        Haptics.error()
        showFailureAlert = true
    }

    /// Успех: начисляем очки, сохраняем фото, показываем зелёную галочку и закрываем камеру.
    /// В режиме мини-игр (pointsOverride) награда фиксированная и не трогает квесты.
    private func succeed(_ image: UIImage, confidence: Float?) async {
        let seconds = max(1, Int(Date().timeIntervalSince(openedAt)))
        if let pointsOverride {
            lastPointsEarned = pointsOverride
            lastDayBonus = 0
        } else {
            lastPointsEarned = GameStats.shared.recordCompleted(questText: questText,
                                                                confidence: confidence,
                                                                seconds: seconds)
            lastDayBonus = GameStats.shared.lastDayBonus
        }
        onComplete(image)
        Haptics.winSound()
        Haptics.success()
        withAnimation(.easeInOut(duration: 0.3)) { phase = .success }
        try? await Task.sleep(nanoseconds: 1_600_000_000)
        onFinish(true)
    }

    // MARK: - Действия пользователя

    /// «Переснять» — возврат в режим видоискателя.
    func retake() {
        phase = .idle
        capturedPhoto = nil
        detectedLabel = nil
    }

    /// «Сохранить принудительно» — если нейросеть ошиблась, фото всё равно засчитывается.
    func forceSave() {
        guard let image = capturedPhoto else { return }
        Task { await succeed(image, confidence: nil) }
    }

    /// «Отмена» — возврат на главный экран без фото.
    func cancel() {
        onFinish(false)
    }
}
