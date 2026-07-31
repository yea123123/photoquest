import Combine
import Foundation

/// Карточка «Фото-Бинго»: 3×3 предмета, которые нужно найти и сфоткать.
/// Карточка хранится в UserDefaults, прогресс переживает перезапуск.
@MainActor
final class BingoViewModel: ObservableObject {

    struct Card: Codable {
        /// Русские ключи словаря (например, «кот», «фонтан»).
        var keys: [String] = []
        /// Отмеченные клетки (9 штук).
        var done: [Bool] = []
        /// Сколько линий уже начислено очками.
        var claimedLines = 0
        /// Бонус за полную карточку уже начислен.
        var claimedFull = false
    }

    @Published private(set) var card: Card
    @Published private(set) var lastBonus = 0

    private let defaults = UserDefaults.standard
    private static let storageKey = "bingo.card"

    init() {
        if let data = defaults.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode(Card.self, from: data) {
            card = decoded
        } else {
            card = Self.makeCard()
            save()
        }
    }

    /// Создаёт новую карточку: 9 случайных предметов из словаря.
    static func makeCard() -> Card {
        let keys = Array(QuestKeywords.all.keys.shuffled().prefix(9))
        return Card(keys: keys, done: Array(repeating: false, count: 9))
    }

    var doneCount: Int { card.done.filter { $0 }.count }
    var isFull: Bool { card.done.allSatisfy { $0 } }

    /// Количество собранных линий (3 ряда + 3 столбца + 2 диагонали).
    var lineCount: Int {
        guard card.keys.count == 9 else { return 0 }
        let lines = [(0, 1, 2), (3, 4, 5), (6, 7, 8),
                     (0, 3, 6), (1, 4, 7), (2, 5, 8),
                     (0, 4, 8), (2, 4, 6)]
        return lines.filter { card.done[$0.0] && card.done[$0.1] && card.done[$0.2] }.count
    }

    /// Клетка закрыта: предмет сфоткали. Начисляет бонусы за линии и «Бинго».
    func complete(index: Int) {
        guard card.keys.indices.contains(index), !card.done[index] else { return }
        card.done[index] = true

        let oldLines = card.claimedLines
        let newLines = lineCount
        var bonus = 0
        if newLines > oldLines {
            let gained = newLines - oldLines
            card.claimedLines = newLines
            bonus += gained * 50
        }
        if isFull && !card.claimedFull {
            card.claimedFull = true
            bonus += 150
        }
        if bonus > 0 {
            lastBonus = bonus
            GameStats.shared.addPoints(bonus)
        } else {
            lastBonus = 0
        }
        save()
    }

    /// Новая карточка (текущий прогресс сбрасывается).
    func newCard() {
        card = Self.makeCard()
        lastBonus = 0
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(card) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }
}
