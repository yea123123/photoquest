import Combine
import Foundation

/// Достижение: бейдж с названием и описанием.
struct Achievement: Identifiable {
    let id: String
    let emoji: String
    let title: String
    let desc: String
    let isUnlocked: Bool
}

/// Игровая статистика: очки, серия, рекорды и достижения.
/// Хранится в UserDefaults — не требует миграций CoreData.
@MainActor
final class GameStats: ObservableObject {

    static let shared = GameStats()

    private let defaults = UserDefaults.standard
    private static let keyPoints = "game.points"
    private static let keyStreak = "game.streak"
    private static let keyLastDate = "game.lastDate"
    private static let keyBestTime = "game.bestTime"
    private static let keyMaxConfidence = "game.maxConfidence"

    @Published private(set) var totalPoints: Int
    @Published private(set) var currentStreak: Int
    @Published private(set) var bestTimeSeconds: Int
    @Published private(set) var maxConfidence: Float
    /// Очки, начисленные за последнее выполненное задание (для надписи «+N»).
    @Published private(set) var lastPointsEarned = 0

    private init() {
        totalPoints = defaults.integer(forKey: Self.keyPoints)
        currentStreak = defaults.integer(forKey: Self.keyStreak)
        bestTimeSeconds = defaults.integer(forKey: Self.keyBestTime)
        maxConfidence = defaults.float(forKey: Self.keyMaxConfidence)
    }

    // MARK: - Начисление очков

    /// Задание выполнено: начисляет очки, продлевает серию, обновляет рекорды.
    /// Формула: 50 базовых + бонус за уверенность детекта (до 50)
    /// + бонус за скорость (до 29) + бонус за серию (до 50).
    @discardableResult
    func recordCompleted(questText: String, confidence: Float?, seconds: Int) -> Int {
        updateStreak()

        var points = 50
        if let confidence, confidence >= Constants.minConfidence {
            points += Int(confidence * 50)
            maxConfidence = max(maxConfidence, confidence)
        }
        if seconds > 0, seconds < 30 {
            points += 30 - seconds
        }
        points += min(currentStreak, 10) * 5

        totalPoints += points
        bestTimeSeconds = bestTimeSeconds == 0 ? seconds : min(bestTimeSeconds, seconds)

        defaults.set(totalPoints, forKey: Self.keyPoints)
        defaults.set(currentStreak, forKey: Self.keyStreak)
        defaults.set(Date(), forKey: Self.keyLastDate)
        defaults.set(bestTimeSeconds, forKey: Self.keyBestTime)
        defaults.set(maxConfidence, forKey: Self.keyMaxConfidence)

        lastPointsEarned = points
        return points
    }

    /// Серия: задание сегодня или вчера продлевает её, иначе — сброс на 1.
    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let last = defaults.object(forKey: Self.keyLastDate) as? Date else {
            currentStreak = 1
            return
        }
        let lastDay = calendar.startOfDay(for: last)
        if calendar.isDate(today, inSameDayAs: lastDay) {
            return // повторные задания в тот же день серию не меняют
        }
        let dayDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
        currentStreak = dayDiff == 1 ? currentStreak + 1 : 1
    }

    // MARK: - Достижения

    /// Текущий список достижений (с учётом истории заданий в хранилище).
    func achievements(storage: StorageService) -> [Achievement] {
        let completed = storage.fetchCompletedQuests()
        let count = completed.count
        let days = Set(completed.compactMap { $0.date.map { Calendar.current.startOfDay(for: $0) } }).count

        return [
            Achievement(id: "first", emoji: "📸", title: "Первый кадр",
                        desc: "Выполни первое задание", isUnlocked: count >= 1),
            Achievement(id: "ten", emoji: "🔟", title: "Десятка",
                        desc: "Выполни 10 заданий", isUnlocked: count >= 10),
            Achievement(id: "fifty", emoji: "🏅", title: "Фотокор",
                        desc: "Выполни 50 заданий", isUnlocked: count >= 50),
            Achievement(id: "legend", emoji: "👑", title: "Фото-легенда",
                        desc: "Выполни все 100 заданий", isUnlocked: count >= 100),
            Achievement(id: "streak3", emoji: "🔥", title: "На волне",
                        desc: "Серия: 3 дня подряд", isUnlocked: currentStreak >= 3),
            Achievement(id: "streak7", emoji: "⚡", title: "Не остановить",
                        desc: "Серия: 7 дней подряд", isUnlocked: currentStreak >= 7),
            Achievement(id: "speedy", emoji: "⏱️", title: "Быстрый снаппер",
                        desc: "Сфоткай задание меньше чем за 20 секунд", isUnlocked: bestTimeSeconds > 0 && bestTimeSeconds < 20),
            Achievement(id: "sniper", emoji: "🎯", title: "Снайпер",
                        desc: "Детект с уверенностью 90%+", isUnlocked: maxConfidence >= 0.9),
            Achievement(id: "marathon", emoji: "📅", title: "Марафонец",
                        desc: "Играй 5 разных дней", isUnlocked: days >= 5),
            Achievement(id: "rich", emoji: "💎", title: "Рекордсмен",
                        desc: "Набери 500 очков", isUnlocked: totalPoints >= 500),
        ]
    }
}
