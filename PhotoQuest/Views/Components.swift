import SwiftUI
import UIKit

/// Переиспользуемые UI-компоненты.

// MARK: - Карточка задания

/// Карточка с крупным текстом задания и категорией.
struct QuestCardView: View {
    let quest: QuestDefinition

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26)
                .fill(LinearGradient(colors: [quest.categoryColor, quest.categoryColor.opacity(0.65)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            VStack(spacing: 14) {
                Text(quest.text)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.55)
                    .padding(.horizontal, 22)
                Text(quest.category)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.95))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.white.opacity(0.22)))
            }
            .padding(20)
        }
        .shadow(color: quest.categoryColor.opacity(0.45), radius: 14, y: 8)
    }
}

// MARK: - ShareSheet

/// Системный ShareSheet для экспорта PDF.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Пустая галерея

/// Заглушка, когда выполненных заданий ещё нет.
struct EmptyGalleryView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("Пока нет выполненных заданий")
                .font(.headline)
            Text("Откройте вкладку «Квест» и сделайте первое фото!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
    }
}
