import Combine
import Foundation

/// «Фото-Бомба»: фитиль горит 30 секунд. Каждое удачное фото добавляет
/// 10 секунд и очки × комбо. Промах сжигает 8 секунд. Фитиль догорел — БУМ.
@MainActor
final class BombViewModel: ObservableObject {

    let startFuse = 30

    @Published private(set) var fuseLeft = 30
    @Published private(set) var score = 0
    @Published private(set) var combo = 1
    @Published private(set) var targetKey = ""
    @Published private(set) var isRunning = false
    @Published private(set) var exploded = false

    private var timerTask: Task<Void, Never>?

    var targetKeywords: [String] {
        QuestKeywords.keywords(for: targetKey)
    }

    /// Запуск: бомба загорается.
    func start() {
        guard !isRunning else { return }
        fuseLeft = startFuse
        score = 0
        combo = 1
        exploded = false
        isRunning = true
        nextTarget()
        startTimer()
    }

    /// Удачное фото: +10×комбо очков, фитиль +10 секунд, новая цель.
    func didCompleteShot() {
        guard isRunning else { return }
        let reward = 10 * combo
        score += reward
        GameStats.shared.addPoints(reward)
        combo += 1
        fuseLeft = min(90, fuseLeft + 10)
        nextTarget()
    }

    /// Промах или отмена: комбо сбрасывается, фитиль горит быстрее.
    func didFailShot() {
        guard isRunning else { return }
        combo = 1
        fuseLeft = max(5, fuseLeft - 8)
    }

    /// Выйти из раунда (накопленное уже в общем счёте).
    func cancel() {
        timerTask?.cancel()
        timerTask = nil
        isRunning = false
    }

    private func nextTarget() {
        targetKey = QuestKeywords.all.keys.shuffled().first ?? "кот"
    }

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled && fuseLeft > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                fuseLeft -= 1
                if fuseLeft <= 0 {
                    explode()
                }
            }
        }
    }

    private func explode() {
        timerTask?.cancel()
        timerTask = nil
        isRunning = false
        exploded = true
    }
}
