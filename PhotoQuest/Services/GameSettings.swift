import Combine
import SwiftUI

/// Настройки приложения, хранятся в UserDefaults.
@MainActor
final class GameSettings: ObservableObject {

    static let shared = GameSettings()

    // MARK: - Чувствительность детекта

    /// Чем ниже пороги, тем чаще задание засчитывается автоматически.
    enum Sensitivity: String, CaseIterable {
        case lenient, balanced, strict

        /// Порог для первых трёх ответов модели (её главные кандидаты).
        var topFloor: Float {
            switch self {
            case .lenient: return 0.08
            case .balanced: return 0.1
            case .strict: return 0.2
            }
        }

        /// Порог для остальных классов из топ-10.
        var restThreshold: Float {
            switch self {
            case .lenient: return 0.15
            case .balanced: return 0.25
            case .strict: return 0.35
            }
        }

        var label: String {
            switch self {
            case .lenient: return "Щадящая"
            case .balanced: return "Обычная"
            case .strict: return "Строгая"
            }
        }
    }

    // MARK: - Тема оформления

    enum Theme: String, CaseIterable {
        case system, light, dark

        var label: String {
            switch self {
            case .system: return "Как в системе"
            case .light: return "Светлая"
            case .dark: return "Тёмная"
            }
        }

        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }

    // MARK: - Вспышка при старте камеры

    enum Flash: String, CaseIterable {
        case auto, on, off

        var label: String {
            switch self {
            case .auto: return "Авто"
            case .on: return "Всегда вкл"
            case .off: return "Выкл"
            }
        }
    }

    // MARK: - Состояние

    private let defaults = UserDefaults.standard
    private static let keySound = "settings.sound"
    private static let keyHaptics = "settings.haptics"
    private static let keySensitivity = "settings.sensitivity"
    private static let keyTheme = "settings.theme"
    private static let keyFlash = "settings.flash"

    @Published var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Self.keySound) }
    }
    @Published var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Self.keyHaptics) }
    }
    @Published var sensitivity: Sensitivity {
        didSet { defaults.set(sensitivity.rawValue, forKey: Self.keySensitivity) }
    }
    @Published var theme: Theme {
        didSet { defaults.set(theme.rawValue, forKey: Self.keyTheme) }
    }
    @Published var flashMode: Flash {
        didSet { defaults.set(flashMode.rawValue, forKey: Self.keyFlash) }
    }

    private init() {
        soundEnabled = defaults.object(forKey: Self.keySound) as? Bool ?? true
        hapticsEnabled = defaults.object(forKey: Self.keyHaptics) as? Bool ?? true
        sensitivity = Sensitivity(rawValue: defaults.string(forKey: Self.keySensitivity) ?? "") ?? .balanced
        theme = Theme(rawValue: defaults.string(forKey: Self.keyTheme) ?? "") ?? .system
        flashMode = Flash(rawValue: defaults.string(forKey: Self.keyFlash) ?? "") ?? .auto
    }
}
