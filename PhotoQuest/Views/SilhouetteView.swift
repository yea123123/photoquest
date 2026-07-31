import SwiftUI

/// «Угадай по силуэту»: размытое эмодзи и 3 варианта ответа.
/// На каждый раунд — 12 секунд. Верно — +10 очков, идеал — бонус +30.
@MainActor
struct SilhouetteView: View {

    @StateObject private var viewModel = SilhouetteViewModel()

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 18) {
                if viewModel.finished {
                    resultView
                } else {
                    roundHeader
                    silhouetteArea
                    optionButtons
                    if let result = viewModel.lastWasCorrect {
                        feedbackText(result)
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("Угадай по силуэту")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel.round == 0 && viewModel.options.isEmpty {
                viewModel.start()
            }
        }
    }

    // MARK: - Шапка

    private var roundHeader: some View {
        HStack(spacing: 16) {
            statBlock(emoji: "🎯", value: "\(viewModel.round + 1)/\(viewModel.totalRounds)", label: "Раунд")
            statBlock(emoji: "⭐", value: "\(viewModel.score)", label: "Очки")
            statBlock(emoji: "⏱️", value: "\(max(0, viewModel.timeLeft))", label: "Секунд")
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

    // MARK: - Силуэт

    private var silhouetteArea: some View {
        Text(viewModel.currentEmoji)
            .font(.system(size: 96))
            .blur(radius: 12)
            .opacity(0.9)
            .frame(maxWidth: .infinity)
            .frame(height: 210)
            .background(RoundedRectangle(cornerRadius: 22)
                .fill(Color(.secondarySystemGroupedBackground)))
            .overlay(alignment: .topTrailing) {
                if viewModel.lastWasCorrect != nil {
                    Image(systemName: (viewModel.lastWasCorrect == true) ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(viewModel.lastWasCorrect == true ? .green : .red)
                        .padding(10)
                }
            }
    }

    // MARK: - Варианты

    private var optionButtons: some View {
        VStack(spacing: 10) {
            ForEach(viewModel.options, id: \.self) { name in
                optionButton(name)
            }
        }
    }

    private func optionButton(_ name: String) -> some View {
        let isCorrect = name == viewModel.correctName
        let isChosen = name == viewModel.chosenName
        let reveal = viewModel.lastWasCorrect != nil
        let style: Color = reveal
            ? (isCorrect ? .green : (isChosen ? .red : .gray.opacity(0.3)))
            : .clear

        return Button {
            Haptics.light()
            withAnimation { viewModel.answer(name) }
        } label: {
            HStack {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                if reveal && (isCorrect || isChosen) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(isCorrect ? .green : .red)
                }
            }
            .padding(15)
            .background(RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground)))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(style, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .disabled(reveal)
    }

    @ViewBuilder
    private func feedbackText(_ result: Bool) -> some View {
        Text(result
            ? "Верно! +10 ⭐"
            : (viewModel.chosenName.isEmpty ? "Время вышло… Правильно: \(viewModel.correctName)"
                                            : "Мимо… Правильно: \(viewModel.correctName)"))
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(result ? Color.green : Color.red)
            .multilineTextAlignment(.center)
    }

    // MARK: - Итоги

    private var resultView: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: viewModel.score >= 100 ? "crown.fill" : "flag.checkered")
                .font(.system(size: 64))
                .foregroundStyle(viewModel.score >= 100 ? .yellow : .green)
            Text("Готово!")
                .font(.title.bold())
            Text("Угадано: \(viewModel.score / 10) из \(viewModel.totalRounds)")
                .font(.title2.bold())
                .monospacedDigit()
            if viewModel.score >= 100 {
                Text("Идеально! Бонус +30 ⭐")
                    .font(.headline)
                    .foregroundStyle(.yellow)
            }
            Text("Все очки уже в общем счёте ⭐")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                Haptics.light()
                viewModel.start()
            } label: {
                Text("Сыграть ещё")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(Color.accentColor))
            }
            Button("Назад") { dismiss() }
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
