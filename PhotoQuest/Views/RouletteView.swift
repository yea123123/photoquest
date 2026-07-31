import SwiftUI

/// «Фото-Рулетка»: крути барабан, лови выпавший предмет за 45 секунд.
@MainActor
struct RouletteView: View {

    @StateObject private var viewModel = RouletteViewModel()

    @State private var showCamera = false
    @State private var showReward = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 20) {
                header
                Spacer(minLength: 0)
                wheel
                Spacer(minLength: 0)

                if viewModel.spinning {
                    Text("Крутим…")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                } else if !viewModel.targetKey.isEmpty {
                    targetPanel
                } else {
                    Button {
                        Haptics.light()
                        viewModel.spin()
                    } label: {
                        Label("Крутить барабан", systemImage: "arrow.clockwise")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(Capsule().fill(Color.purple))
                    }
                    .disabled(!viewModel.canSpin)
                }
            }
            .padding(20)
        }
        .navigationTitle("Фото-Рулетка")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.lastReward) { newValue in
            guard newValue > 0 else { return }
            showReward = true
        }
        .overlay { if showReward { rewardOverlay } }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(
                questText: "Сфоткай: \(viewModel.targetKey)",
                keywords: viewModel.targetKeywords,
                pointsOverride: 30,
                onComplete: { _ in viewModel.didCompleteShot() },
                onFinish: { _ in showCamera = false }
            )
        }
    }

    // MARK: - Шапка

    private var header: some View {
        HStack(spacing: 20) {
            statBlock(emoji: "🎡", value: "\(viewModel.wins)", label: "Удач")
            statBlock(emoji: "⭐", value: "\(viewModel.wins * 30)", label: "Очки")
            statBlock(emoji: "⏱️", value: "\(viewModel.timeLeft) с", label: "Таймер")
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

    // MARK: - Барабан

    private var wheel: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.purple.opacity(0.4), lineWidth: 6)
                .frame(width: 260, height: 260)

            ForEach(viewModel.segments.indices, id: \.self) { index in
                let angle = Angle.degrees(Double(index) * 45 - 90)
                let radius = 88.0
                Text(QuestKeywords.emoji(for: viewModel.segments[index]))
                    .font(.system(size: 34))
                    .frame(width: 58, height: 58)
                    .background(Circle().fill(segmentColor(index)))
                    .shadow(color: .black.opacity(0.12), radius: 3, y: 2)
                    .offset(x: cos(angle.radians) * radius,
                            y: sin(angle.radians) * radius)
            }
            .rotationEffect(.degrees(viewModel.rotation))
        }
        .frame(width: 280, height: 280)
        .overlay(alignment: .top) {
            Image(systemName: "arrowtriangle.down.fill")
                .font(.title)
                .foregroundStyle(.red)
                .offset(y: -4)
        }
    }

    private func segmentColor(_ index: Int) -> Color {
        let palette: [Color] = [.blue, .orange, .green, .pink, .teal, .yellow, .indigo, .red]
        return palette[index % palette.count].opacity(0.9)
    }

    // MARK: - Цель

    private var targetPanel: some View {
        VStack(spacing: 12) {
            Text("Выпало! Найди за \(viewModel.timeLeft) секунд:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Text(QuestKeywords.emoji(for: viewModel.targetKey))
                    .font(.system(size: 36))
                Text(viewModel.targetKey)
                    .font(.largeTitle.bold())
            }
            Button {
                Haptics.light()
                showCamera = true
            } label: {
                Label("Идти снимать!", systemImage: "camera.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 13)
                    .background(Capsule().fill(Color.accentColor))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
    }

    // MARK: - Награда

    private var rewardOverlay: some View {
        Text("+\(viewModel.lastReward) ⭐")
            .font(.title.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background(Capsule().fill(Color.green))
            .shadow(radius: 10)
            .transition(.scale.combined(with: .opacity))
            .onAppear {
                Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    withAnimation { showReward = false }
                }
            }
    }
}
