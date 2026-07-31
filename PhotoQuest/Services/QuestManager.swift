import UIKit

/// Логика выдачи заданий: очередь, пропуск, завершение, перезапуск.
final class QuestManager {

    private let storage: StorageService

    init(storage: StorageService) {
        self.storage = storage
    }

    /// Создаёт стартовую очередь из 100 заданий (перемешанных) при первом запуске.
    func seedIfNeeded() {
        storage.seedIfNeeded(quests: QuestLibrary.quests)
    }

    /// Текущее задание (первое невыполненное в очереди, опционально по категории).
    func currentQuest(category: String? = nil) -> QuestDefinition? {
        QuestLibrary.definition(for: storage.currentQuest(category: category)?.text)
    }

    /// Прогресс: (выполнено, всего).
    func progress() -> (done: Int, total: Int) {
        storage.counts()
    }

    /// Последние выполненные задания — для миниатюр на главном экране.
    func recentCompleted(limit: Int = 5) -> [CompletedQuest] {
        storage.recentCompleted(limit: limit)
    }

    /// «Пропустить»: задание уходит в конец очереди и вернётся после остальных.
    func skipCurrent() {
        if let text = storage.currentQuest()?.text {
            storage.moveToEnd(text: text)
        }
    }

    /// «Новое задание»: смена задания без начисления прогресса (аналог пропуска).
    func replaceCurrent() {
        skipCurrent()
    }

    /// Завершает текущее задание: сохраняет фото и отмечает задание выполненным.
    func completeCurrent(image: UIImage) {
        if let text = storage.currentQuest()?.text {
            storage.completeQuest(text: text, image: image)
        }
    }

    /// «Начать заново»: очищает очередь заданий и заново перемешивает.
    func restart() {
        storage.resetQuests()
    }
}
