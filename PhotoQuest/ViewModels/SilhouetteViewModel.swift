import Combine
import Foundation

/// «Угадай по силуэту»: размытое эмодзи и 3 варианта.
/// На ответ — 12 секунд. Верно — +10 очков, идеал (10/10) — бонус +30.
@MainActor
final class SilhouetteViewModel: ObservableObject {

    struct Item {
        let name: String
        let emoji: String
    }

    static let items: [Item] = [
        Item(name: "кот", emoji: "🐱"), Item(name: "собака", emoji: "🐶"),
        Item(name: "тигр", emoji: "🐯"), Item(name: "слон", emoji: "🐘"),
        Item(name: "зебра", emoji: "🦓"), Item(name: "бабочка", emoji: "🦋"),
        Item(name: "сова", emoji: "🦉"), Item(name: "пингвин", emoji: "🐧"),
        Item(name: "кит", emoji: "🐳"), Item(name: "акула", emoji: "🦈"),
        Item(name: "роза", emoji: "🌹"), Item(name: "подсолнух", emoji: "🌻"),
        Item(name: "кактус", emoji: "🌵"), Item(name: "пальма", emoji: "🌴"),
        Item(name: "гриб", emoji: "🍄"), Item(name: "пицца", emoji: "🍕"),
        Item(name: "бургер", emoji: "🍔"), Item(name: "мороженое", emoji: "🍦"),
        Item(name: "арбуз", emoji: "🍉"), Item(name: "клубника", emoji: "🍓"),
        Item(name: "часы", emoji: "🕐"), Item(name: "лампа", emoji: "💡"),
        Item(name: "книга", emoji: "📚"), Item(name: "телефон", emoji: "📱"),
        Item(name: "наушники", emoji: "🎧"), Item(name: "машина", emoji: "🚗"),
        Item(name: "велосипед", emoji: "🚲"), Item(name: "самолёт", emoji: "✈️"),
        Item(name: "поезд", emoji: "🚆"), Item(name: "вертолёт", emoji: "🚁"),
        Item(name: "ракета", emoji: "🚀"), Item(name: "мяч", emoji: "⚽"),
        Item(name: "баскетбол", emoji: "🏀"), Item(name: "лыжи", emoji: "🎿"),
        Item(name: "теннис", emoji: "🎾"), Item(name: "гитара", emoji: "🎸"),
        Item(name: "пианино", emoji: "🎹"), Item(name: "барабан", emoji: "🥁"),
        Item(name: "микрофон", emoji: "🎤"), Item(name: "камера", emoji: "📷"),
    ]

    let totalRounds = 10
    let timePerRound = 12

    @Published private(set) var round = 0
    @Published private(set) var score = 0
    @Published private(set) var timeLeft = 12
    @Published private(set) var options: [String] = []
    @Published private(set) var correctName = ""
    @Published private(set) var chosenName = ""
    @Published private(set) var lastWasCorrect: Bool?
    @Published private(set) var finished = false

    private var roundTask: Task<Void, Never>?

    /// Эмодзи текущего раунда.
    var currentEmoji: String {
        Self.items.first { $0.name == correctName }?.emoji ?? "❓"
    }

    /// Запуск новой игры.
    func start() {
        round = 0
        score = 0
        finished = false
        nextRound()
    }

    /// Ответ: верно — +10 очков.
    func answer(_ name: String) {
        guard lastWasCorrect == nil, !finished else { return }
        roundTask?.cancel()
        let ok = name == correctName
        lastWasCorrect = ok
        chosenName = name
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
            return
        }
        roundTask = Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard !Task.isCancelled else { return }
            nextRound()
        }
    }

    /// Время вышло: засчитываем промах и переходим дальше.
    private func timeout() {
        guard lastWasCorrect == nil, !finished else { return }
        lastWasCorrect = false
        chosenName = ""
        round += 1
        if round >= totalRounds {
            finished = true
            if score >= totalRounds * 10 {
                GameStats.shared.addPoints(30)
            }
            return
        }
        roundTask = Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard !Task.isCancelled else { return }
            nextRound()
        }
    }

    private func nextRound() {
        guard !finished else { return }
        let item = Self.items.randomElement() ?? Self.items[0]
        correctName = item.name
        options = Self.makeOptions(correct: item.name)
        lastWasCorrect = nil
        chosenName = ""
        timeLeft = timePerRound
        startRoundTimer()
    }

    private func startRoundTimer() {
        roundTask?.cancel()
        roundTask = Task {
            while !Task.isCancelled && timeLeft > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                timeLeft -= 1
                if timeLeft <= 0 {
                    timeout()
                }
            }
        }
    }

    /// 3 варианта: правильный + 2 случайных.
    private static func makeOptions(correct: String) -> [String] {
        var names = items.map(\.name).filter { $0 != correct }.shuffled()
        var options = [correct]
        options.append(contentsOf: names.prefix(2))
        return options.shuffled()
    }
}
