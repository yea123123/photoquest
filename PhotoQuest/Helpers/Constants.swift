import SwiftUI

/// Общие константы приложения.
enum Constants {
    static let appName = "Фото-квест"

    /// Имя файла модели Core ML (без расширения).
    /// Xcode автоматически компилирует добавленный .mlmodel в .mlmodelc при сборке.
    static let modelFileName = "MobileNetV2"

    /// Страница, откуда можно скачать модель MobileNetV2.
    static let modelDownloadURL = URL(string: "https://developer.apple.com/machine-learning/models/")!

    /// Минимальная уверенность нейросети для засчитывания задания (60%).
    static let minConfidence: Float = 0.6

    /// Цвета категорий заданий (работают в светлой и тёмной теме).
    static let categoryColors: [String: Color] = [
        "Животные": Color(red: 0.91, green: 0.55, blue: 0.25),
        "Дом":      Color(red: 0.55, green: 0.42, blue: 0.85),
        "Техника":  Color(red: 0.20, green: 0.62, blue: 0.86),
        "Транспорт": Color(red: 0.27, green: 0.75, blue: 0.55),
        "Еда":      Color(red: 0.95, green: 0.35, blue: 0.35),
        "Природа":  Color(red: 0.35, green: 0.72, blue: 0.35),
        "Город":    Color(red: 0.45, green: 0.55, blue: 0.65),
        "Люди":     Color(red: 0.85, green: 0.45, blue: 0.65),
        "Хобби":    Color(red: 0.85, green: 0.70, blue: 0.25),
        "Разное":   Color(red: 0.55, green: 0.55, blue: 0.60),
    ]
}
