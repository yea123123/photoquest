import Foundation

/// Описание задания: текст, категория и ключ для словаря распознавания.
struct QuestDefinition: Identifiable, Hashable {
    let text: String
    let category: String
    /// Ключ в словаре QuestKeywords (русское слово → английские названия классов MobileNetV2 / ImageNet).
    let keywordKey: String

    var id: String { text }

    /// Английские названия объектов, которые считаются правильным ответом для этого задания.
    var keywords: [String] { QuestKeywords.keywords(for: keywordKey) }
}
