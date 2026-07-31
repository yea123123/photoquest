import Combine
import Foundation

/// «Фото-Спринт»: 60 секунд, чтобы сфоткать как можно больше случайных
/// предметов. Каждое удачное фото — 10 очков × комбо. Комбо растёт за
/// серию успехов подряд и сбрасывается при промахе или отмене.
@MainActor
final class SprintViewModel: ObservableObject {

    let duration = 60

    @Published private(set) var timeLeft = 60
    @Published private(set) var score = 0
    @Published private(set) var combo = 1
    @Published private(set) var targetKey = ""
    @Published private(set) var isRunning = false
    @Published private(set) var finished = false

    private var timerTask: Task<Void, Never>?

    /// Текущее задание спринта (русский ключ словаря).
    var targetText: String {
        QuestKeywords.all[targetKey]?.isEmpty == false ? targetKey : "предмет"
    }

    /// Ключевые слова для проверки текущей цели.
    var targetKeywords: [String] {
        QuestKeywords.keywords(for: targetKey)
    }

    /// Запуск раунда.
    func start() {
        guard !isRunning else { return }
        timeLeft = duration
        score = 0
        combo = 1
        finished = false
        isRunning = true
        nextTarget()
        timerTask = Task {
            while !Task.isCancelled && timeLeft > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                timeLeft -= 1
                if timeLeft <= 0 {
                    finish()
                }
            }
        }
    }

    /// Фото засчитано: плюс очки с учётом комбо, новая цель.
    func didCompleteShot() {
        guard isRunning else { return }
        score += 10 * combo
        combo += 1
        nextTarget()
    }

    /// Фото не засчитано (промах или отмена): комбо сбрасывается.
    func didFailShot() {
        guard isRunning else { return }
        combo = 1
    }

    /// Завершение раунда: начисляем заработанные очки.
    func finish() {
        timerTask?.cancel()
        timerTask = nil
        isRunning = false
        if !finished {
            finished = true
            if score > 0 {
                GameStats.shared.addPoints(score)
            }
        }
    }

    /// Выход из раунда без начисления (если не завершён — очки теряются).
    func cancel() {
        timerTask?.cancel()
        timerTask = nil
        isRunning = false
    }

    private func nextTarget() {
        targetKey = QuestKeywords.all.keys.shuffled().first ?? "кот"
    }
}
