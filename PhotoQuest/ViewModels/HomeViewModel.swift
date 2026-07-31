import SwiftUI

/// ViewModel главного экрана: публикует текущее задание, прогресс, очки и последние фото.
@MainActor
final class HomeViewModel: ObservableObject {

    @Published private(set) var currentQuest: QuestDefinition?
    @Published private(set) var completedCount = 0
    @Published private(set) var totalCount = 0
    @Published private(set) var recent: [CompletedQuest] = []
    @Published private(set) var allCompleted = false
    @Published private(set) var categoryDone = false
    @Published private(set) var totalPoints = 0
    @Published private(set) var currentStreak = 0
    @Published private(set) var chosenCategory: String?

    private let questManager: QuestManager
    private let defaults = UserDefaults.standard
    private static let keyCategory = "home.category"

    init(questManager: QuestManager) {
        self.questManager = questManager
        chosenCategory = defaults.string(forKey: Self.keyCategory)
        refresh()
    }

    /// Уровень игрока по очкам (для бейджа в шапке).
    var level: PlayerLevel {
        GameStats.level(points: totalPoints)
    }

    /// Обновляет все публикуемые данные из хранилища.
    func refresh() {
        questManager.seedIfNeeded()
        currentQuest = questManager.currentQuest(category: chosenCategory)
        let progress = questManager.progress()
        completedCount = progress.done
        totalCount = progress.total
        recent = questManager.recentCompleted(limit: 5)
        allCompleted = currentQuest == nil && totalCount > 0
        categoryDone = chosenCategory != nil && currentQuest == nil && !allCompleted
        totalPoints = GameStats.shared.totalPoints
        currentStreak = GameStats.shared.currentStreak
    }

    /// Выбор категории фильтра («Все» — nil).
    func setCategory(_ category: String?) {
        chosenCategory = category
        if let category {
            defaults.set(category, forKey: Self.keyCategory)
        } else {
            defaults.removeObject(forKey: Self.keyCategory)
        }
        refresh()
    }

    /// «Пропустить» — задание уходит в конец очереди.
    func skip() {
        questManager.skipCurrent()
        refresh()
    }

    /// «Новое задание» — смена задания.
    func newQuest() {
        questManager.replaceCurrent()
        refresh()
    }

    /// Вызывается камерой при успешной (или принудительной) съёмке.
    func completeCurrent(image: UIImage) {
        questManager.completeCurrent(image: image)
        refresh()
    }

    /// «Начать заново» после прохождения всех заданий.
    func restart() {
        questManager.restart()
        refresh()
    }
}
