import SwiftUI

/// «Фото-Бинго»: карточка 3×3 — найди и сфоткай все предметы.
/// Собери ряд, столбец или диагональ — получишь бонус. Отлично для прогулок!
@MainActor
struct BingoView: View {

    @StateObject private var viewModel = BingoViewModel()

    @State private var showCamera = false
    @State private var cameraIndex = 0
    @State private var showNewCardAlert = false
    @State private var showBonus = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    bingoGrid
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
        .navigationTitle("Фото-Бинго")
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
            Text("Текущий прогресс карточки пропадёт. Отметок: \(viewModel.doneCount) из 9.")
        }
    }

    // MARK: - Шапка

    private var headerCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 20) {
                statBlock(value: "\(viewModel.doneCount)/9", label: "Найдено", emoji: "📷")
                statBlock(value: "\(viewModel.lineCount)", label: "Линий", emoji: "〰️")
                statBlock(value: "\(viewModel.lineCount * 50)", label: "Очки линий", emoji: "⭐")
            }
            Text("Найди и сфоткай предметы. Линия (ряд, столбец или диагональ) — +50 очков, полная карточка — «Бинго!» +150.")
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

    // MARK: - Сетка

    private var bingoGrid: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(0..<9, id: \.self) { index in
                cellButton(index)
            }
        }
    }

    private func cellButton(_ index: Int) -> some View {
        let key = viewModel.card.keys.indices.contains(index) ? viewModel.card.keys[index] : ""
        let isDone = viewModel.card.done.indices.contains(index) && viewModel.card.done[index]
        return Button {
            guard !isDone else { return }
            Haptics.light()
            cameraIndex = index
            showCamera = true
        } label: {
            VStack(spacing: 6) {
                if isDone {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.green)
                    Text("Готово")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                } else {
                    Text("📷")
                        .font(.title2)
                    Text(key)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(RoundedRectangle(cornerRadius: 18)
                .fill(isDone ? Color.green.opacity(0.15) : Color(.secondarySystemGroupedBackground)))
            .overlay(RoundedRectangle(cornerRadius: 18)
                .strokeBorder(isDone ? Color.green.opacity(0.5) : Color.clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .disabled(isDone)
    }

    private var fullCardBanner: some View {
        Text("🎉 БИНГО! Вся карточка собрана!")
            .font(.headline)
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.yellow.opacity(0.25)))
    }

    // MARK: - Камера

    private func camera(for index: Int) -> some View {
        let key = viewModel.card.keys.indices.contains(index) ? viewModel.card.keys[index] : ""
        let keywords = QuestKeywords.keywords(for: key)
        return CameraView(
            questText: "Найди: \(key)",
            keywords: keywords,
            pointsOverride: 10,
            onComplete: { _ in viewModel.complete(index: index) },
            onFinish: { _ in showCamera = false }
        )
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
