import SwiftUI

/// ViewModel главного экрана: публикует текущее задание, прогресс и последние фото.
@MainActor
final class HomeViewModel: ObservableObject {

    @Published private(set) var currentQuest: QuestDefinition?
    @Published private(set) var completedCount = 0
    @Published private(set) var totalCount = 0
    @Published private(set) var recent: [CompletedQuest] = []
    @Published private(set) var allCompleted = false

    private let questManager: QuestManager

    init(questManager: QuestManager) {
        self.questManager = questManager
        refresh()
    }

    /// Обновляет все публикуемые данные из хранилища.
    func refresh() {
        questManager.seedIfNeeded()
        currentQuest = questManager.currentQuest()
        let progress = questManager.progress()
        completedCount = progress.done
        totalCount = progress.total
        recent = questManager.recentCompleted(limit: 5)
        allCompleted = currentQuest == nil && totalCount > 0
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
