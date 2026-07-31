import AVFoundation
import SwiftUI
import UIKit

/// Экран камеры: видоискатель AVFoundation, текущее задание поверх,
/// кнопка спуска затвора и отмена. После съёмки — проверка через Core ML.
struct CameraView: View {

    @StateObject private var viewModel: CameraViewModel

    init(questText: String,
         keywords: [String],
         onComplete: @escaping (UIImage) -> Void,
         onFinish: @escaping (Bool) -> Void) {
        _viewModel = StateObject(wrappedValue: CameraViewModel(
            questText: questText,
            keywords: keywords,
            onComplete: onComplete,
            onFinish: onFinish
        ))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Видоискатель или последний снимок
            Group {
                if let photo = viewModel.capturedPhoto {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                } else {
                    CameraPreview(session: viewModel.camera.session)
                        .ignoresSafeArea()
                }
            }

            // Затемнение сверху и снизу для читаемости текста
            LinearGradient(colors: [.black.opacity(0.55), .clear, .clear, .black.opacity(0.5)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack {
                questBanner
                Spacer()
                controls
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34)

            // Состояния: проверка, успех, ошибка
            if viewModel.phase == .checking {
                checkingOverlay
            }
            if viewModel.phase == .success {
                successOverlay
            }
            if viewModel.phase == .failure {
                Color.red.opacity(0.3).ignoresSafeArea().transition(.opacity)
            }
            if viewModel.permissionDenied {
                permissionDeniedOverlay
            }
        }
        .statusBarHidden()
        .task { await viewModel.start() }
        .onDisappear { viewModel.camera.stop() }
        .alert(isPresented: $viewModel.showFailureAlert) { failureAlert }
        .sheet(isPresented: $viewModel.showModelSheet) { modelMissingSheet }
    }

    // MARK: - Текущее задание поверх видоискателя

    private var questBanner: some View {
        Text(viewModel.questText)
            .font(.headline)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Capsule().fill(.black.opacity(0.45)))
            .padding(.top, 12)
    }

    // MARK: - Управление

    private var controls: some View {
        HStack(spacing: 44) {
            Button {
                viewModel.toggleFlash()
            } label: {
                Image(systemName: viewModel.flashOn ? "bolt.fill" : "bolt.slash.fill")
                    .font(.title3)
                    .foregroundStyle(viewModel.flashOn ? .yellow : .white)
                    .frame(width: 54, height: 54)
                    .background(Circle().fill(.white.opacity(0.16)))
            }
            .accessibilityLabel("Вспышка")

            Button {
                viewModel.capture()
            } label: {
                ZStack {
                    Circle().strokeBorder(.white, lineWidth: 5).frame(width: 86, height: 86)
                    Circle().fill(.white).frame(width: 72, height: 72)
                }
            }
            .disabled(viewModel.phase == .checking)
            .accessibilityLabel("Снять фото")

            Button {
                viewModel.cancel()
            } label: {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(Circle().fill(.white.opacity(0.16)))
            }
            .accessibilityLabel("Отмена")
        }
    }

    // MARK: - Оверлеи

    private var checkingOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 14) {
                ProgressView().tint(.white).scaleEffect(1.4)
                Text("Проверяем фото…")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
        .transition(.opacity)
    }

    private var successOverlay: some View {
        ZStack {
            Color.green.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 120))
                    .foregroundStyle(.white)
                Text("Задание выполнено!")
                    .font(.title.bold())
                    .foregroundStyle(.white)
            }
        }
        .transition(.opacity)
    }

    private var permissionDeniedOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "video.slash")
                .font(.system(size: 48))
                .foregroundStyle(.white)
            Text("Нет доступа к камере")
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text("Разрешите доступ в настройках, чтобы делать фото для заданий.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
            Button {
                openSettings()
            } label: {
                Text("Открыть настройки")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(.white))
            }
            Button {
                viewModel.cancel()
            } label: {
                Text("Назад")
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
        }
        .padding(24)
    }

    /// Предупреждение об ошибке распознавания: переснять или сохранить принудительно.
    private var failureAlert: Alert {
        let recognized = viewModel.detectedLabel.map { "\n\nРаспознано: \($0)" } ?? ""
        return Alert(
            title: Text("Не похоже на задание"),
            message: Text("Это не похоже на «\(viewModel.questText)», попробуй ещё раз.\(recognized)"),
            primaryButton: .default(Text("Переснять")) { viewModel.retake() },
            secondaryButton: .default(Text("Сохранить принудительно")) { viewModel.forceSave() }
        )
    }

    /// Показывается, если модель MobileNetV2 не добавлена в проект.
    private var modelMissingSheet: some View {
        VStack(spacing: 18) {
            Image(systemName: "cpu")
                .font(.system(size: 52))
                .foregroundStyle(.orange)
            Text("Не найдена модель MobileNetV2")
                .font(.title3.bold())
            Text("Скачайте модель MobileNetV2.mlmodel и добавьте её в проект (галочка Target Membership). Без неё приложение не сможет проверять фото.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Link(destination: Constants.modelDownloadURL) {
                Text("Открыть страницу модели")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.accentColor))
            }
            Button("Понятно") { viewModel.showModelSheet = false }
                .font(.subheadline)
        }
        .padding(28)
        .presentationDetents([.medium])
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Видоискатель (AVCaptureVideoPreviewLayer в SwiftUI)

/// UIView-обёртка над AVCaptureVideoPreviewLayer.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    static func dismantleUIView(_ uiView: PreviewView, coordinator: ()) {
        // Отключаем сессию от слоя, чтобы не было артефактов при закрытии.
        uiView.videoPreviewLayer.session = nil
    }
}

/// Вьюха, слой которой — AVCaptureVideoPreviewLayer.
final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
