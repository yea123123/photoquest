import Combine
import SwiftUI

/// «Угадай-ка»: выбери фото из галереи, угадай, что на нём.
/// 10 раундов, +10 очков за верный ответ, идеал (10/10) — бонус +30.
@MainActor
final class GuessItViewModel: ObservableObject {

    let totalRounds = 10

    /// Фото текущего раунда.
    @Published private(set) var photo: UIImage?
    /// 4 варианта ответа (ключи словаря).
    @Published private(set) var options: [String] = []
    /// Правильный ключ текущего раунда.
    @Published private(set) var correctKey = ""
    /// Номер раунда (1...10).
    @Published private(set) var round = 0
    @Published private(set) var score = 0
    @Published private(set) var finished = false
    /// Результат последнего ответа (nil — ещё не отвечали).
    @Published private(set) var lastWasCorrect: Bool?
    /// Ключ, который выбрал игрок в последнем ответе (для подсветки).
    @Published private(set) var chosenKey = ""
    /// Сообщение об ошибке распознавания фото.
    @Published private(set) var lastMessage: String?

    private let detector = ObjectDetectionService.shared

    /// Фото выбрано из галереи: распознаём и готовим вопрос.
    func handlePicked(_ image: UIImage) async {
        photo = image
        options = []
        correctKey = ""
        lastWasCorrect = nil
        lastMessage = nil

        let results = await detector.classify(image)
        guard let best = detector.bestKey(for: results), best.confidence >= 0.12 else {
            lastMessage = "Не получилось распознать это фото — выбери другое"
            photo = nil
            return
        }
        correctKey = best.key
        options = Self.makeOptions(correct: best.key)
    }

    /// Ответ игрока: засчитывает очки и переходит к следующему раунду.
    func answer(_ key: String) {
        guard photo != nil, lastWasCorrect == nil, !finished else { return }
        let ok = key == correctKey
        lastWasCorrect = ok
        chosenKey = key
        if ok {
            score += 10
            GameStats.shared.addPoints(10)
        }
        round += 1
        if round >= totalRounds {
            finished = true
            if score >= totalRounds * 10 {
                GameStats.shared.addPoints(30)
            }
        }
    }

    /// Следующий раунд: нужно выбрать новое фото.
    func next() {
        photo = nil
        options = []
        correctKey = ""
        lastWasCorrect = nil
        chosenKey = ""
        lastMessage = nil
    }

    /// Новая игра.
    func restart() {
        round = 0
        score = 0
        finished = false
        next()
    }

    var perfectBonus: Int { 30 }

    /// 4 варианта: правильный ответ + 3 случайных ключа.
    private static func makeOptions(correct: String) -> [String] {
        var pool = QuestKeywords.all.keys.filter { $0 != correct }.shuffled()
        var options = [correct]
        options.append(contentsOf: pool.prefix(3))
        return options.shuffled()
    }
}
