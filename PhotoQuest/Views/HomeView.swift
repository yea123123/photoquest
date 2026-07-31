import SwiftUI
import UIKit

/// Главный экран: текущее задание (1/3 экрана), кнопка камеры,
/// кнопки «Пропустить»/«Новое задание», прогресс и последние 5 фото.
struct HomeView: View {

    @StateObject private var viewModel = HomeViewModel(questManager: QuestManager(storage: .shared))

    @State private var showCamera = false
    @State private var showSuccessFlash = false
    @State private var showAchievements = false
    @State private var flashPoints = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 18) {
                    header
                    categoryChips
                    questArea
                        .frame(height: max(170, geo.size.height * 0.28))
                    Spacer(minLength: 0)
                    cameraButton
                    actionButtons
                    if !viewModel.recent.isEmpty && !viewModel.allCompleted {
                        recentStrip
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
        .overlay {
            if showSuccessFlash { successFlashOverlay }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(
                questText: viewModel.currentQuest?.text ?? "",
                keywords: viewModel.currentQuest?.keywords ?? [],
                onComplete: { image in viewModel.completeCurrent(image: image) },
                onFinish: { success in cameraDidFinish(success: success) }
            )
        }
        .sheet(isPresented: $showAchievements) { AchievementsView() }
        .onAppear { viewModel.refresh() }
    }

    // MARK: - Шапка с прогрессом и очками

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(Constants.appName)
                    .font(.largeTitle.bold())
                Spacer()
                Button {
                    Haptics.light()
                    showAchievements = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(.yellow)
                        Text("\(viewModel.totalPoints)")
                            .font(.subheadline.weight(.bold))
                            .monospacedDigit()
                        if viewModel.currentStreak >= 2 {
                            Text("🔥\(viewModel.currentStreak)")
                                .font(.caption.weight(.semibold))
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Достижения: \(viewModel.totalPoints) очков")
            }
            ProgressView(value: viewModel.totalCount > 0 ? Double(viewModel.completedCount) / Double(viewModel.totalCount) : 0)
                .tint(.green)
            HStack {
                Text("\(viewModel.completedCount) / \(viewModel.totalCount)")
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                Spacer()
                if let category = viewModel.chosenCategory {
                    Text(category)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Фильтр по категориям

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip("Все", category: nil)
                ForEach(QuestLibrary.categories, id: \.self) { category in
                    categoryChip(category, category: category)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func categoryChip(_ title: String, category: String?) -> some View {
        let isSelected = viewModel.chosenCategory == category
        return Button {
            Haptics.light()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                viewModel.setCategory(category)
            }
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground)))
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Область задания (с анимацией смены)

    private var questArea: some View {
        ZStack {
            if viewModel.allCompleted {
                completionCard
                    .transition(.asymmetric(insertion: .scale(scale: 0.85).combined(with: .opacity),
                                            removal: .opacity))
            } else if viewModel.categoryDone {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 46))
                        .foregroundStyle(.green)
                    Text("В этой категории всё выполнено!")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    Text("Выбери другую категорию или вернись ко всем заданиям.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 26)
                    .fill(Color(.secondarySystemGroupedBackground)))
            } else if let quest = viewModel.currentQuest {
                QuestCardView(quest: quest)
                    .id(quest.text)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .move(edge: .leading).combined(with: .opacity)))
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Большая круглая кнопка камеры

    private var cameraButton: some View {
        Button {
            if viewModel.currentQuest != nil {
                showCamera = true
            }
        } label: {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.75)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 104, height: 104)
                    .shadow(color: Color.accentColor.opacity(0.5), radius: 16, y: 8)
                Circle()
                    .strokeBorder(.white.opacity(0.9), lineWidth: 4)
                    .frame(width: 92, height: 92)
                Image(systemName: "camera.fill")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .disabled(viewModel.allCompleted)
        .accessibilityLabel("Сделать фото")
    }

    // MARK: - «Пропустить» и «Новое задание»

    private var actionButtons: some View {
        HStack(spacing: 14) {
            Button {
                Haptics.light()
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { viewModel.skip() }
            } label: {
                Label("Пропустить", systemImage: "forward.end.fill")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Capsule().strokeBorder(Color.secondary.opacity(0.5), lineWidth: 1))
            }
            Button {
                Haptics.light()
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { viewModel.newQuest() }
            } label: {
                Label("Новое задание", systemImage: "arrow.triangle.2.circlepath")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.accentColor.opacity(0.12)))
            }
        }
        .buttonStyle(.plain)
        .disabled(viewModel.allCompleted)
    }

    // MARK: - Последние 5 выполненных заданий

    private var recentStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Последние выполненные")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.recent, id: \.objectID) { item in
                        VStack(spacing: 6) {
                            Group {
                                if let image = item.loadImage() {
                                    Image(uiImage: image).resizable().scaledToFill()
                                } else {
                                    Color.gray.opacity(0.2)
                                        .overlay(Image(systemName: "photo").foregroundStyle(.gray))
                                }
                            }
                            .frame(width: 76, height: 76)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            Text(item.questText)
                                .font(.caption2)
                                .lineLimit(1)
                                .frame(width: 76)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Поздравление после всех заданий

    private var completionCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "party.popper")
                .font(.system(size: 56))
                .foregroundStyle(.yellow)
            Text("Поздравляем!")
                .font(.title.bold())
            Text("Все \(viewModel.totalCount) заданий выполнены. Ты настоящий фото-герой!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                Haptics.success()
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { viewModel.restart() }
            } label: {
                Label("Начать заново", systemImage: "arrow.counterclockwise")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.accentColor))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 26).fill(Color(.secondarySystemGroupedBackground)))
        .padding(20)
    }

    // MARK: - Зелёная вспышка при успехе

    private var successFlashOverlay: some View {
        ZStack {
            Color.green.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 96))
                    .foregroundStyle(.white)
                Text("Фото сохранено!")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                Text("+\(flashPoints) очков ⭐")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
            }
        }
        .transition(.opacity)
    }

    // MARK: - Обработка закрытия камеры

    @MainActor
    private func cameraDidFinish(success: Bool) {
        showCamera = false
        guard success else { return }
        viewModel.refresh()
        flashPoints = GameStats.shared.lastPointsEarned
        Haptics.success()
        withAnimation(.easeInOut(duration: 0.25)) { showSuccessFlash = true }
        Task {
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            withAnimation(.easeInOut(duration: 0.4)) { showSuccessFlash = false }
        }
    }
}
