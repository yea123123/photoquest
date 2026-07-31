import SwiftUI

/// Галерея выполненных заданий: фото, текст, дата, удаление свайпом
/// и экспорт (PDF через ShareSheet или сохранение в системную галерею).
struct GalleryView: View {

    @StateObject private var viewModel = GalleryViewModel(storage: .shared)

    @State private var shareURL: URL?
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.items.isEmpty {
                    EmptyGalleryView()
                } else {
                    List {
                        ForEach(viewModel.items, id: \.objectID) { item in
                            GalleryRow(item: item)
                        }
                        .onDelete { offsets in
                            withAnimation { viewModel.delete(at: offsets) }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Галерея")
            .toolbar {
                if !viewModel.items.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                exportPDF()
                            } label: {
                                Label("Экспорт в PDF", systemImage: "doc.richtext")
                            }
                            Button {
                                saveToLibrary()
                            } label: {
                                Label("Сохранить в фотоальбом", systemImage: "square.and.arrow.down")
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .overlay {
                if viewModel.isExporting { exportingOverlay }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .sheet(item: $shareURL) { url in
                ShareSheet(items: [url])
            }
            .task { viewModel.refresh() }
        }
    }

    /// Затемняющая подложка на время экспорта.
    private var exportingOverlay: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            VStack(spacing: 14) {
                ProgressView().controlSize(.large)
                Text("Экспортируем…")
                    .font(.headline)
            }
            .padding(26)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color(.secondarySystemBackground)))
        }
    }

    // MARK: - Экспорт

    private func exportPDF() {
        viewModel.isExporting = true
        Task {
            let url = await viewModel.exportPDF()
            viewModel.isExporting = false
            if let url {
                shareURL = url
            } else {
                alertTitle = "Не удалось экспортировать"
                alertMessage = "Сначала выполните хотя бы одно задание."
                showAlert = true
            }
        }
    }

    private func saveToLibrary() {
        viewModel.isExporting = true
        Task {
            let result = await viewModel.saveAllToLibrary()
            viewModel.isExporting = false
            switch result {
            case .success:
                alertTitle = "Готово"
                alertMessage = "Все фотографии сохранены в ваш фотоальбом."
            case .failure(let error):
                alertTitle = "Ошибка"
                alertMessage = error.localizedDescription
            }
            showAlert = true
        }
    }
}

/// Строка галереи: миниатюра, текст задания и дата.
struct GalleryRow: View {
    let item: CompletedQuest

    var body: some View {
        HStack(spacing: 14) {
            Group {
                if let image = item.loadImage() {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.15))
                        .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 5) {
                Text(item.questText)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                Text(item.date?.questString() ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
