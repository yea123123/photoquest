import AVFoundation

/// Сервис камеры на базе AVFoundation (без UIImagePickerController).
/// Управляет сессией захвата, разрешениями и съёмкой фото.
final class CameraService: NSObject {

    /// Сессия захвата; к ней подключается preview-слой (AVCaptureVideoPreviewLayer).
    let session = AVCaptureSession()

    /// Очередь для операций с сессией — нельзя трогать сессию с главного потока.
    private let sessionQueue = DispatchQueue(label: "photoquest.camera.session")

    private let photoOutput = AVCapturePhotoOutput()

    /// Вызывается с данными JPEG после съёмки (на главном потоке).
    var photoHandler: ((Data) -> Void)?

    // MARK: - Разрешения

    /// Запрашивает разрешение на доступ к камере.
    func requestAuthorization() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    continuation.resume(returning: granted)
                }
            }
        default:
            return false
        }
    }

    // MARK: - Запуск / остановка

    /// Настраивает сессию (вход с задней камеры, выход для фото) и запускает её.
    /// completion(true) — сессия работает, false — камера недоступна (например, симулятор).
    func start(completion: ((Bool) -> Void)? = nil) {
        sessionQueue.async { [weak self] in
            guard let self else { completion?(false); return }
            guard !self.session.isRunning else { completion?(true); return }

            self.session.beginConfiguration()

            var hasInput = true
            if self.session.inputs.isEmpty {
                guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                      let input = try? AVCaptureDeviceInput(device: device) else {
                    self.session.commitConfiguration()
                    completion?(false)
                    return
                }
                hasInput = self.session.canAddInput(input)
                if hasInput { self.session.addInput(input) }
            }

            if !self.session.outputs.contains(self.photoOutput), self.session.canAddOutput(self.photoOutput) {
                if self.photoOutput.isMaxPhotoQualityPrioritizationSupported {
                    self.photoOutput.maxPhotoQualityPrioritization = .quality
                }
                self.session.addOutput(self.photoOutput)
            }

            self.session.sessionPreset = .photo
            self.session.commitConfiguration()

            if hasInput { self.session.startRunning() }
            completion?(hasInput)
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    // MARK: - Съёмка

    /// Делает снимок. Результат приходит в photoHandler.
    func capture(flashOn: Bool) {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }

            let settings: AVCapturePhotoSettings
            if self.photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
                settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
            } else {
                settings = AVCapturePhotoSettings()
            }
            settings.flashMode = flashOn ? .on : .off
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: AVCapturePhotoCaptureDelegate {

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard error == nil, let data = photo.fileDataRepresentation() else { return }
        DispatchQueue.main.async { [weak self] in
            self?.photoHandler?(data)
        }
    }
}
