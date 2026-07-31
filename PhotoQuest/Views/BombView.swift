import SwiftUI

/// «Фото-Бомба»: обезвредь бомбу, пока горит фитиль!
/// Каждое удачное фото — +10 секунд к фитилю и очки × комбо.
/// Промах сжигает 8 секунд. Фитиль догорел — БУМ!
@MainActor
struct BombView: View {

    @StateObject private var viewModel = BombViewModel()

    @Environment(\.dismiss) private var dismiss

    @State private var showCamera = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 20) {
                if viewModel.isRunning {
                    runningView
                } else if viewModel.exploded {
                    boomView
                } else {
                    introView
                }
            }
            .padding(20)
        }
        .navigationTitle("Фото-Бомба")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(
                questText: "Обезвредь: \(viewModel.targetKey)!",
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
            Image(systemName: "bomb.fill")
                .font(.system(size: 64))
                .foregroundStyle(.red)
            Text("Бомба заминирована!")
                .font(.title2.bold())
            Text("Фитиль горит 30 секунд. Каждое удачное фото продлевает его на 10 секунд и даёт очки × комбо. Промах сжигает 8 секунд. Сколько протянешь?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button {
                Haptics.light()
                viewModel.start()
            } label: {
                Text("💣 Обезвредить!")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(Color.red))
            }
        }
    }

    // MARK: - Раунд

    private var runningView: some View {
        VStack(spacing: 20) {
            fuseRing
            HStack(spacing: 28) {
                scoreBlock(emoji: "⭐", value: "\(viewModel.score)", label: "Очки")
                scoreBlock(emoji: "🔥", value: "×\(viewModel.combo)", label: "Комбо")
            }
            targetCard
            Button {
                Haptics.light()
                showCamera = true
            } label: {
                Label("Сфоткать!", systemImage: "camera.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(Color.accentColor))
            }
        }
    }

    private var fuseRing: some View {
        ZStack {
            Circle()
                .stroke(Color(.secondarySystemGroupedBackground), lineWidth: 10)
            Circle()
                .trim(from: 0, to: CGFloat(viewModel.fuseLeft) / CGFloat(viewModel.startFuse))
                .stroke(fuseColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text(viewModel.fuseLeft <= 10 ? "💣" : "⏱️")
                    .font(.system(size: 30))
                Text("\(viewModel.fuseLeft)")
                    .font(.system(size: 44, weight: .bold))
                    .monospacedDigit()
                Text("сек до взрыва")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 170, height: 170)
        .scaleEffect(viewModel.fuseLeft <= 10 ? 1.05 : 1)
        .animation(viewModel.fuseLeft <= 10 ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true) : .default,
                   value: viewModel.fuseLeft <= 10)
    }

    private var fuseColor: Color {
        switch viewModel.fuseLeft {
        case 0..<10: return .red
        case 10..<20: return .orange
        default: return .green
        }
    }

    private var targetCard: some View {
        VStack(spacing: 6) {
            Text("Обезвредь фото:")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Text(QuestKeywords.emoji(for: viewModel.targetKey))
                    .font(.system(size: 34))
                Text(viewModel.targetKey)
                    .font(.largeTitle.bold())
            }
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

    // MARK: - Взрыв

    private var boomView: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.red)
            Text("БУМ! 💥")
                .font(.largeTitle.bold())
            Text("Бомба взорвалась, но ты успел набрать \(viewModel.score) очков!")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("Все очки уже в общем счёте ⭐")
                .font(.subheadline)
                .foregroundStyle(.secondary)
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
                    .background(Capsule().fill(Color.red))
            }
            Button("Назад") { dismiss() }
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
