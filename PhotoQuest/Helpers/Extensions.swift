import AudioToolbox
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

/// Звук и вибрация управляются настройками (вкладка «Настройки»).
enum Haptics {
    @MainActor
    static func success() {
        guard GameSettings.shared.hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    @MainActor
    static func error() {
        guard GameSettings.shared.hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    @MainActor
    static func light() {
        guard GameSettings.shared.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    /// Звук затвора камеры.
    @MainActor
    static func shutter() {
        guard GameSettings.shared.soundEnabled else { return }
        AudioServicesPlaySystemSound(1108)
    }
    /// Короткий «победный» звук.
    @MainActor
    static func winSound() {
        guard GameSettings.shared.soundEnabled else { return }
        AudioServicesPlaySystemSound(1104)
    }
}
