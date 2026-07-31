import Combine
import Foundation

/// «Фото-Дуэт»: сфоткай ДВА предмета в одном кадре.
/// Карточка из 6 пар хранится в UserDefaults. Пара — +40 очков,
/// вся карточка — бонус «Дуэт» +200.
@MainActor
final class DuetViewModel: ObservableObject {

    struct Card: Codable {
        /// Пары ключей словаря (по 2 предмета на кадр).
        var pairs: [[String]] = []
        var done: [Bool] = []
        var claimedFull = false
    }

    /// Пул сочетаний, которые реально встречаются вместе.
    static let pool: [[String]] = [
        ["кот", "кружка"],
        ["бабочка", "цветок"],
        ["машина", "дерево"],
        ["собака", "круглое"],
        ["часы", "книга"],
        ["лампа", "книга"],
        ["телефон", "кружка"],
        ["мороженое", "ягоды"],
        ["велосипед", "здание"],
        ["окно", "цветок"],
    ]

    @Published private(set) var card: Card
    @Published private(set) var lastBonus = 0

    private let defaults = UserDefaults.standard
    private static let storageKey = "duet.card"

    init() {
        if let data = defaults.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode(Card.self, from: data) {
            card = decoded
        } else {
            card = Self.makeCard()
            save()
        }
    }

    static func makeCard() -> Card {
        let pairs = pool.shuffled().prefix(6).map { $0 }
        return Card(pairs: pairs, done: Array(repeating: false, count: 6))
    }

    var doneCount: Int { card.done.filter { $0 }.count }
    var isFull: Bool { card.done.allSatisfy { $0 } }

    /// Пара закрыта: оба предмета на одном кадре засчитаны.
    func complete(index: Int) {
        guard card.pairs.indices.contains(index), !card.done[index] else { return }
        card.done[index] = true

        var bonus = 40
        if isFull && !card.claimedFull {
            card.claimedFull = true
            bonus += 200
        }
        lastBonus = bonus
        GameStats.shared.addPoints(bonus)
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
