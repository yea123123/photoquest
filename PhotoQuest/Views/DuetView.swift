import SwiftUI

/// «Фото-Дуэт»: сфоткай два предмета в одном кадре.
/// Каждая пара — +40 очков, вся карточка — «Дуэт!» +200.
@MainActor
struct DuetView: View {

    @StateObject private var viewModel = DuetViewModel()

    @State private var showCamera = false
    @State private var cameraIndex = 0
    @State private var showNewCardAlert = false
    @State private var showBonus = false

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(0..<6, id: \.self) { index in
                            pairCell(index)
                        }
                    }
                    if viewModel.isFull { fullCardBanner }
                    Button("Новая карточка") {
                        showNewCardAlert = true
                    }
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(.bordered)
                }
                .padding(16)
            }
        }
        .navigationTitle("Фото-Дуэт")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.lastBonus) { newValue in
            guard newValue > 0 else { return }
            showBonus = true
        }
        .overlay { if showBonus { bonusOverlay } }
        .fullScreenCover(isPresented: $showCamera) {
            camera(for: cameraIndex)
        }
        .alert("Новая карточка?", isPresented: $showNewCardAlert) {
            Button("Создать", role: .destructive) { viewModel.newCard() }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Текущий прогресс пропадёт. Собрано пар: \(viewModel.doneCount) из 6.")
        }
    }

    // MARK: - Шапка

    private var headerCard: some View {
        VStack(spacing: 8) {
            HStack(spacing: 20) {
                statBlock(value: "\(viewModel.doneCount)/6", label: "Пар", emoji: "🧩")
                statBlock(value: "\(viewModel.doneCount * 40)", label: "Очки", emoji: "⭐")
            }
            Text("Сфоткай ОБА предмета в одном кадре! Пара — +40, вся карточка — «Дуэт!» +200.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(.secondarySystemGroupedBackground)))
    }

    private func statBlock(value: String, label: String, emoji: String) -> some View {
        VStack(spacing: 3) {
            Text(emoji).font(.title3)
            Text(value).font(.headline).monospacedDigit()
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Пары

    private func pairCell(_ index: Int) -> some View {
        let pair = viewModel.card.pairs.indices.contains(index) ? viewModel.card.pairs[index] : []
        let isDone = viewModel.card.done.indices.contains(index) && viewModel.card.done[index]
        return Button {
            guard !isDone, pair.count == 2 else { return }
            Haptics.light()
            cameraIndex = index
            showCamera = true
        } label: {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Text(QuestKeywords.emoji(for: pair.first ?? ""))
                        .font(.system(size: 30))
                    Text("+")
                        .font(.title3.bold())
                        .foregroundStyle(.secondary)
                    Text(QuestKeywords.emoji(for: pair.count > 1 ? pair[1] : ""))
                        .font(.system(size: 30))
                }
                Text(isDone ? "Готово!" : "\(pair.first ?? "") + \(pair.count > 1 ? pair[1] : "")")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isDone ? Color.green : Color.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(RoundedRectangle(cornerRadius: 18)
                .fill(isDone ? Color.green.opacity(0.15) : Color(.secondarySystemGroupedBackground)))
            .overlay(RoundedRectangle(cornerRadius: 18)
                .strokeBorder(isDone ? Color.green.opacity(0.5) : Color.clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .disabled(isDone)
    }

    private var fullCardBanner: some View {
        Text("🧩 ДУЭТ! Вся карточка собрана!")
            .font(.headline)
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.purple.opacity(0.2)))
    }

    // MARK: - Камера

    private func camera(for index: Int) -> AnyView {
        let pair = viewModel.card.pairs.indices.contains(index) ? viewModel.card.pairs[index] : []
        guard pair.count == 2 else {
            return AnyView(Color.black.ignoresSafeArea())
        }
        return AnyView(CameraView(
            questText: "Сфоткай: \(pair[0]) И \(pair[1]) в одном кадре!",
            keywords: QuestKeywords.keywords(for: pair[0]),
            keywordsB: QuestKeywords.keywords(for: pair[1]),
            pointsOverride: 40,
            onComplete: { _ in viewModel.complete(index: index) },
            onFinish: { _ in showCamera = false }
        ))
    }

    // MARK: - Бонус

    private var bonusOverlay: some View {
        Text("+\(viewModel.lastBonus) ⭐")
            .font(.title.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background(Capsule().fill(Color.green))
            .shadow(radius: 10)
            .transition(.scale.combined(with: .opacity))
            .onAppear {
                Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    withAnimation { showBonus = false }
                }
            }
    }
}
