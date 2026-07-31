import SwiftUI

// MARK: - URL: Identifiable (для ShareSheet через .sheet(item:))

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

// MARK: - Форматирование дат

extension Date {
    /// Форматирует дату: «31 июля 2026, 14:05».
    func questString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy, HH:mm"
        return formatter.string(from: self)
    }
}

// MARK: - Цвет категории задания

extension QuestDefinition {
    var categoryColor: Color {
        Constants.categoryColors[category] ?? Color.accentColor
    }
}

// MARK: - Тактильная обратная связь

enum Haptics {
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func error() { UINotificationFeedbackGenerator().notificationOccurred(.error) }
    static func light() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
}
