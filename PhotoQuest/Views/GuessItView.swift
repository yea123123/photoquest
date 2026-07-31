import PhotosUI
import SwiftUI
import UIKit

/// «Угадай-ка»: выбери фото из галереи и угадай, что на нём.
/// 10 раундов, +10 очков за верный ответ, идеал — бонус +30.
@MainActor
struct GuessItView: View {

    @StateObject private var viewModel = GuessItViewModel()

    @State private var showPicker = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 18) {
                if viewModel.finished {
                    resultView
                } else {
                    roundHeader
                    photoArea
                    optionsArea
                }
            }
            .padding(20)
        }
        .navigationTitle("Угадай-ка")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPicker) {
            PhotoPicker(
                onPick: { image in
                    showPicker = false
                    Task { await viewModel.handlePicked(image) }
                },
                onDismiss: { showPicker = false }
            )
        }
    }

    // MARK: - Шапка раунда

    private var roundHeader: some View {
        HStack(spacing: 16) {
            statBlock(emoji: "🎯", value: "\(viewModel.round)/\(viewModel.totalRounds)", label: "Раунд")
            statBlock(emoji: "⭐", value: "\(viewModel.score)", label: "Очки")
        }
    }

    private func statBlock(emoji: String, value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(emoji).font(.title3)
            Text(value).font(.headline).monospacedDigit()
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }

    // MARK: - Фото

    @ViewBuilder
    private var photoArea: some View {
        if let photo = viewModel.photo {
            Image(uiImage: photo)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 260)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .transition(.opacity)
        } else {
            VStack(spacing: 12) {
                if let message = viewModel.lastMessage {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                }
                Button {
                    showPicker = true
                } label: {
                    VStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 44))
                        Text("Выбрать фото из галереи")
                            .font(.headline)
                    }
                    .foregroundStyle(Color.accentColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .background(RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.secondarySystemGroupedBackground)))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Варианты ответа

    private var optionsArea: some View {
        VStack(spacing: 10) {
            if viewModel.photo != nil && viewModel.options.isEmpty {
                ProgressView()
                    .padding(.vertical, 20)
            } else if viewModel.photo != nil {
                ForEach(viewModel.options, id: \.self) { key in
                    optionButton(key)
                }
                feedbackText
                if viewModel.lastWasCorrect != nil {
                    Button("Дальше") {
                        viewModel.next()
                    }
                    .font(.headline)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
                }
            }
        }
    }

    private func optionButton(_ key: String) -> some View {
        let isCorrect = key == viewModel.correctKey
        let isChosen = key == viewModel.chosenKey
        let reveal = viewModel.lastWasCorrect != nil
        let style: Color = reveal
            ? (isCorrect ? .green : (isChosen ? .red : .gray.opacity(0.3)))
            : .clear

        return Button {
            Haptics.light()
            withAnimation { viewModel.answer(key) }
        } label: {
            HStack(spacing: 10) {
                Text(QuestKeywords.emoji(for: key))
                    .font(.title2)
                Text(key)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                if reveal {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : (isChosen ? "xmark.circle.fill" : ""))
                        .font(.title2)
                        .foregroundStyle(isCorrect ? .green : .red)
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground)))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(style, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.lastWasCorrect != nil)
    }

    @ViewBuilder
    private var feedbackText: some View {
        if let result = viewModel.lastWasCorrect {
            Text(result ? "Верно! +10 ⭐" : "Мимо… Правильный ответ: \(viewModel.correctKey)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(result ? Color.green : Color.red)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Итоги

    private var resultView: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: viewModel.score >= 100 ? "crown.fill" : "flag.checkered")
                .font(.system(size: 64))
                .foregroundStyle(viewModel.score >= 100 ? .yellow : .green)
            Text("Игра окончена!")
                .font(.title.bold())
            Text("Угадано: \(viewModel.score / 10) из \(viewModel.totalRounds)")
                .font(.title2.bold())
                .monospacedDigit()
            if viewModel.score >= 100 {
                Text("Идеально! Бонус +\(viewModel.perfectBonus) ⭐")
                    .font(.headline)
                    .foregroundStyle(.yellow)
            }
            Text("Все очки уже в общем счёте ⭐")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                Haptics.light()
                viewModel.restart()
            } label: {
                Text("Сыграть ещё")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(Color.accentColor))
            }
        }
    }
}

// MARK: - Пикер фото (PHPicker — без запроса разрешений)

/// Обёртка над PHPickerViewController для выбора одного фото.
struct PhotoPicker: UIViewControllerRepresentable {

    let onPick: (UIImage) -> Void
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onDismiss: onDismiss)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPick: (UIImage) -> Void
        let onDismiss: () -> Void

        init(onPick: @escaping (UIImage) -> Void, onDismiss: @escaping () -> Void) {
            self.onPick = onPick
            self.onDismiss = onDismiss
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider else {
                onDismiss()
                return
            }
            provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                DispatchQueue.main.async {
                    if let image = object as? UIImage {
                        self?.onPick(image)
                    } else {
                        self?.onDismiss()
                    }
                }
            }
        }
    }
}
