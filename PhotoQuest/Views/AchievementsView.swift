import SwiftUI

/// Экран достижений: очки, серия и список бейджей.
@MainActor
struct AchievementsView: View {

    @Environment(\.dismiss) private var dismiss

    private var stats: GameStats { GameStats.shared }
    private var achievements: [Achievement] {
        GameStats.shared.achievements(storage: .shared)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 24) {
                        statView(value: "\(stats.totalPoints)", label: "Очки", emoji: "⭐")
                        statView(value: "\(stats.currentStreak)", label: "Серия дней", emoji: "🔥")
                        statView(value: bestTimeText, label: "Рекорд", emoji: "⏱️")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .listRowBackground(Color.clear)

                Section("Бейджи") {
                    ForEach(achievements) { item in
                        HStack(spacing: 14) {
                            Text(item.emoji)
                                .font(.system(size: 34))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.title)
                                    .font(.headline)
                                Text(item.desc)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: item.isUnlocked ? "checkmark.seal.fill" : "lock.fill")
                                .font(.title3)
                                .foregroundStyle(item.isUnlocked ? .green : .secondary)
                        }
                        .opacity(item.isUnlocked ? 1 : 0.55)
                    }
                }
            }
            .navigationTitle("Достижения")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }

    private var bestTimeText: String {
        stats.bestTimeSeconds > 0 ? "\(stats.bestTimeSeconds) с" : "—"
    }

    private func statView(value: String, label: String, emoji: String) -> some View {
        VStack(spacing: 4) {
            Text(emoji)
                .font(.title2)
            Text(value)
                .font(.title3.bold())
                .monospacedDigit()
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 16)
            .fill(Color(.secondarySystemGroupedBackground)))
    }
}
