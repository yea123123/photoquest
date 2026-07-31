import SwiftUI

/// Хаб мини-игр: «Фото-Бинго» (прогулка), «Фото-Спринт» (гонка на время),
/// «Фото-Рулетка» (барабан), «Фото-Дуэт» (два в одном), «Угадай-ка» (викторина).
@MainActor
struct GamesView: View {

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    NavigationLink {
                        BingoView()
                    } label: {
                        gameCard(
                            emoji: "🎯",
                            color: .blue,
                            title: "Фото-Бинго",
                            subtitle: "Гуляй и собирай",
                            description: "Карточка 3×3: найди и сфоткай 9 предметов. Ряд, столбец или диагональ — +50 очков, «Бинго» — +150. Идеальна для прогулки!"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        SprintView()
                    } label: {
                        gameCard(
                            emoji: "🏃",
                            color: .orange,
                            title: "Фото-Спринт",
                            subtitle: "60 секунд",
                            description: "Сфоткай как можно больше случайных предметов за минуту. Серия удач — множитель ×2, ×3, ×4… Промах сбрасывает комбо."
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        RouletteView()
                    } label: {
                        gameCard(
                            emoji: "🎡",
                            color: .purple,
                            title: "Фото-Рулетка",
                            subtitle: "45 секунд на охоту",
                            description: "Крути барабан — выпадет предмет, на поиск и съёмку которого даётся 45 секунд. Успех — +30 очков!"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        DuetView()
                    } label: {
                        gameCard(
                            emoji: "🧩",
                            color: .pink,
                            title: "Фото-Дуэт",
                            subtitle: "Два в одном кадре",
                            description: "Сфоткай ДВА предмета в одном кадре: кот + кружка, бабочка + цветок… Пара — +40, вся карточка — «Дуэт!» +200."
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        GuessItView()
                    } label: {
                        gameCard(
                            emoji: "🧠",
                            color: .teal,
                            title: "Угадай-ка",
                            subtitle: "Викторина по фото",
                            description: "Выбери фото из галереи и угадай, что на нём: 4 варианта, 10 раундов, +10 очков за верный ответ, идеал — бонус +30."
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Мини-игры")
        }
    }

    private func gameCard(emoji: String,
                          color: Color,
                          title: String,
                          subtitle: String,
                          description: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Text(emoji)
                    .font(.system(size: 40))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(color)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
    }
}
