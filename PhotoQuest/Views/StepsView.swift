import SwiftUI

/// «Шагомер-Челлендж»: шаги за сегодня открывают награды.
/// 500 шагов — +100, 1500 — +250, 3000 — +500.
@MainActor
struct StepsView: View {

    @StateObject private var viewModel = StepsViewModel()

    @State private var showReward = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    stepsCard
                    if viewModel.unavailable {
                        unavailableCard
                    } else if viewModel.denied {
                        deniedCard
                    } else {
                        levelList
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Шагомер")
        .navigationBarTitleDisplayMode(.inline)
        .task { viewModel.startRefreshing() }
        .onDisappear { viewModel.stopRefreshing() }
        .onChange(of: viewModel.lastReward) { newValue in
            guard newValue > 0 else { return }
            showReward = true
        }
        .overlay { if showReward { rewardOverlay } }
    }

    // MARK: - Шаги

    private var stepsCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "figure.walk.motion")
                .font(.system(size: 52))
                .foregroundStyle(.green)
            Text("\(viewModel.stepsToday)")
                .font(.system(size: 52, weight: .bold))
                .monospacedDigit()
            Text("шагов сегодня")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                Haptics.light()
                viewModel.refreshSteps()
            } label: {
                Label("Обновить", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
    }

    // MARK: - Уровни

    private var levelList: some View {
        VStack(spacing: 12) {
            ForEach(Array(StepsViewModel.levels.enumerated()), id: \.offset) { index, level in
                levelCard(index: index, level: level)
            }
        }
    }

    private func levelCard(index: Int, level: StepsViewModel.Level) -> some View {
        let isClaimed = viewModel.claimed.contains(index)
        let progress = Double(min(viewModel.stepsToday, level.threshold)) / Double(level.threshold)
        let isCurrent = !isClaimed && index == viewModel.claimed.count
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(level.emoji)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.title)
                        .font(.headline)
                    Text(isClaimed ? "Собрано! +\(level.reward) ⭐" : "\(level.threshold) шагов → +\(level.reward) очков")
                        .font(.caption)
                        .foregroundStyle(isClaimed ? .green : .secondary)
                }
                Spacer()
                if isClaimed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                } else if isCurrent {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                }
            }
            ProgressView(value: progress)
                .tint(isClaimed ? .green : .orange)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18)
            .fill(isCurrent ? Color.orange.opacity(0.12) : Color(.secondarySystemGroupedBackground)))
        .overlay(RoundedRectangle(cornerRadius: 18)
            .strokeBorder(isCurrent ? Color.orange.opacity(0.5) : Color.clear, lineWidth: 2))
    }

    // MARK: - Сообщения

    private var unavailableCard: some View {
        Text("Шагомер недоступен на этом устройстве.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }

    private var deniedCard: some View {
        VStack(spacing: 10) {
            Text("Нет доступа к шагам")
                .font(.headline)
            Text("Разрешите «Движение и фитнес» в настройках, чтобы челлендж считал шаги.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Открыть настройки") {
                openSettings()
            }
            .font(.subheadline.weight(.semibold))
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
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
                    try? await Task.sleep(nanoseconds: 1_800_000_000)
                    withAnimation { showReward = false }
                }
            }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
