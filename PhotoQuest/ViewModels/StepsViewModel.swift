import Combine
import CoreMotion
import Foundation

/// «Шагомер-Челлендж»: шаги за сегодня открывают награды.
/// 500 шагов — +100, 1500 — +250, 3000 — +500. Награда — раз в день.
@MainActor
final class StepsViewModel: ObservableObject {

    struct Level {
        let threshold: Int
        let reward: Int
        let emoji: String
        let title: String
    }

    static let levels: [Level] = [
        Level(threshold: 500, reward: 100, emoji: "🥉", title: "Разминка"),
        Level(threshold: 1500, reward: 250, emoji: "🥈", title: "Прогулка"),
        Level(threshold: 3000, reward: 500, emoji: "🥇", title: "Поход"),
    ]

    @Published private(set) var stepsToday = 0
    @Published private(set) var claimed: [Int] = []
    /// Шагомер недоступен (симулятор/старый iPhone).
    @Published private(set) var unavailable = false
    /// Доступ к движению запрещён.
    @Published private(set) var denied = false
    @Published private(set) var lastReward = 0

    private let pedometer = CMPedometer()
    private let defaults = UserDefaults.standard
    private static let keyClaimed = "steps.claimed"
    private static let keyDay = "steps.day"
    private var refreshTask: Task<Void, Never>?

    init() {
        let dayKey = Self.dayKey()
        if defaults.string(forKey: Self.keyDay) != dayKey {
            defaults.set(dayKey, forKey: Self.keyDay)
            defaults.removeObject(forKey: Self.keyClaimed)
            claimed = []
        } else {
            claimed = defaults.array(forKey: Self.keyClaimed) as? [Int] ?? []
        }
    }

    /// Запускает автообновление шагов (каждые 30 секунд).
    func startRefreshing() {
        guard refreshTask == nil else { return }
        refreshSteps()
        refreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                guard !Task.isCancelled else { return }
                refreshSteps()
            }
        }
    }

    func stopRefreshing() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    /// Запрашивает шаги с начала дня и начисляет открытые награды.
    func refreshSteps() {
        guard CMPedometer.isStepCountingAvailable() else {
            unavailable = true
            return
        }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        pedometer.queryPedometerData(from: startOfDay, to: Date()) { [weak self] data, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let error {
                    print("Шагомер: \(error.localizedDescription)")
                    let status = CMPedometer.authorizationStatus()
                    if status == .denied || status == .restricted {
                        self.denied = true
                    }
                    return
                }
                self.denied = false
                self.stepsToday = data?.numberOfSteps.intValue ?? 0
                self.claimNewLevels()
            }
        }
    }

    private func claimNewLevels() {
        for (index, level) in Self.levels.enumerated() where !claimed.contains(index) {
            guard stepsToday >= level.threshold else { continue }
            claimed.append(index)
            defaults.set(claimed, forKey: Self.keyClaimed)
            lastReward = level.reward
            GameStats.shared.addPoints(level.reward)
        }
        claimed.sort()
    }

    private static func dayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
