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
    /// Что распознала нейросеть (для сообщения об ошибке).
    @Published var detectedLabel: String?
    @Published var permissionDenied = false
    @Published var modelMissing = false
    @Published var cameraUnavailable = false
    @Published var flashOn = false
    @Published var showFailureAlert = false
    @Published var showModelSheet = false

    let camera = CameraService()
    let questText: String

    private let detector = ObjectDetectionService.shared
    private let keywords: [String]
    private let onComplete: (UIImage) -> Void
    private let onFinish: (Bool) -> Void

    init(questText: String,
         keywords: [String],
         onComplete: @escaping (UIImage) -> Void,
         onFinish: @escaping (Bool) -> Void) {
        self.questText = questText
        self.keywords = keywords
        self.onComplete = onComplete
        self.onFinish = onFinish
    }

    // MARK: - Жизненный цикл

    /// Запрашивает разрешение на камеру, проверяет модель и запускает сессию.
    func start() async {
        let authorized = await camera.requestAuthorization()
        guard authorized else {
            permissionDenied = true
            return
        }
        guard detector.isModelAvailable else {
            modelMissing = true
            return
        }
        camera.start { [weak self] ok in
            Task { @MainActor in
                self?.cameraUnavailable = !ok
            }
        }
    }

    func toggleFlash() {
        flashOn.toggle()
    }

    // MARK: - Съёмка и проверка

    /// Спуск затвора: делает фото и запускает проверку.
    func capture() {
        guard phase != .checking, !permissionDenied, !modelMissing else { return }
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
            modelMissing = true
            return
        }
        guard let result = await detector.classify(image) else {
            detectedLabel = nil
            presentFailure()
            return
        }
        detectedLabel = "\(result.identifier), \(Int(result.confidence * 100))%"

        if detector.isMatch(result: result, keywords: keywords) {
            await succeed(image)
        } else {
            presentFailure()
        }
    }

    private func presentFailure() {
        phase = .failure
        Haptics.error()
        showFailureAlert = true
    }

    /// Успех: сохраняем фото в базу, показываем зелёную галочку и закрываем камеру.
    private func succeed(_ image: UIImage) async {
        onComplete(image)
        Haptics.success()
        withAnimation(.easeInOut(duration: 0.3)) { phase = .success }
        try? await Task.sleep(nanoseconds: 1_400_000_000)
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
        Task { await succeed(image) }
    }

    /// «Отмена» — возврат на главный экран без фото.
    func cancel() {
        onFinish(false)
    }
}
