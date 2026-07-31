import SwiftUI

/// «Фото-Спринт»: 60 секунд, чтобы сфоткать как можно больше случайных
/// предметов. Каждое удачное фото — 10 очков × комбо.
@MainActor
struct SprintView: View {

    @StateObject private var viewModel = SprintViewModel()

    @Environment(\.dismiss) private var dismiss

    @State private var showCamera = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 24) {
                if viewModel.isRunning {
                    runningView
                } else if viewModel.finished {
                    resultView
                } else {
                    introView
                }
            }
            .padding(20)
        }
        .navigationTitle("Фото-Спринт")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(
                questText: "Сфоткай: \(viewModel.targetText)",
                keywords: viewModel.targetKeywords,
                pointsOverride: 10,
                onComplete: { _ in },
                onFinish: { success in
                    showCamera = false
                    if success {
                        viewModel.didCompleteShot()
                    } else {
                        viewModel.didFailShot()
                    }
                }
            )
        }
        .onDisappear { viewModel.cancel() }
    }

    // MARK: - Старт

    private var introView: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "figure.walk")
                .font(.system(size: 64))
                .foregroundStyle(.orange)
            Text("60 секунд — сколько предметов успеешь сфоткать?")
                .font(.title3.bold())
                .multilineTextAlignment(.center)
            Text("Каждое удачное фото — 10 очков. Серия удач подряд даёт множитель ×2, ×3, ×4… Промах сбрасывает комбо.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button {
                Haptics.light()
                viewModel.start()
            } label: {
                Text("🏃 Поехали!")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(Color.orange))
            }
        }
    }

    // MARK: - Раунд

    private var runningView: some View {
        VStack(spacing: 22) {
            timerRing
            HStack(spacing: 28) {
                scoreBlock(emoji: "⭐", value: "\(viewModel.score)", label: "Очки")
                scoreBlock(emoji: "🔥", value: "×\(viewModel.combo)", label: "Комбо")
            }
            targetCard
            Button {
                Haptics.light()
                showCamera = true
            } label: {
                Label("Сфоткать", systemImage: "camera.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(Color.accentColor))
            }
        }
    }

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(Color(.secondarySystemGroupedBackground), lineWidth: 10)
            Circle()
                .trim(from: 0, to: CGFloat(viewModel.timeLeft) / CGFloat(viewModel.duration))
                .stroke(ringColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text("\(viewModel.timeLeft)")
                    .font(.system(size: 44, weight: .bold))
                    .monospacedDigit()
                Text("секунд")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 160, height: 160)
    }

    private var ringColor: Color {
        switch viewModel.timeLeft {
        case 0..<10: return .red
        case 10..<25: return .orange
        default: return .green
        }
    }

    private var targetCard: some View {
        VStack(spacing: 6) {
            Text("Сейчас найди:")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(viewModel.targetText)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
    }

    private func scoreBlock(emoji: String, value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(emoji).font(.title3)
            Text(value).font(.title2.bold()).monospacedDigit()
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }

    // MARK: - Итоги

    private var resultView: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "flag.checkered")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("Время вышло!")
                .font(.title.bold())
            Text("Набрано очков: \(viewModel.score)")
                .font(.title2.bold())
                .monospacedDigit()
            if viewModel.score > 0 {
                Text("Очки уже добавлены к общему счёту ⭐")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                Haptics.light()
                viewModel.start()
            } label: {
                Text("Ещё раз")
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
