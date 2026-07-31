import SwiftUI

/// Экран настроек: чувствительность детекта, звук и вибрация, вспышка,
/// тема оформления и управление прогрессом.
@MainActor
struct SettingsView: View {

    @ObservedObject private var settings = GameSettings.shared

    @State private var showResetStats = false
    @State private var showResetQuests = false
    @State private var showResetDone = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Чувствительность детекта", selection: $settings.sensitivity) {
                        ForEach(GameSettings.Sensitivity.allCases, id: \.self) { value in
                            Text(value.label).tag(value)
                        }
                    }
                    Text(sensitivityHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Распознавание")
                } footer: {
                    Text("«Щадящая» засчитывает задания чаще, но допускает ошибки. «Строгая» — наоборот, почти не ошибается, но требует идеального кадра.")
                }

                Section("Звук и вибрация") {
                    Toggle("Звуки", isOn: $settings.soundEnabled)
                    Toggle("Вибрация", isOn: $settings.hapticsEnabled)
                }

                Section("Камера") {
                    Picker("Вспышка при старте", selection: $settings.flashMode) {
                        ForEach(GameSettings.Flash.allCases, id: \.self) { value in
                            Text(value.label).tag(value)
                        }
                    }
                }

                Section("Внешний вид") {
                    Picker("Тема", selection: $settings.theme) {
                        ForEach(GameSettings.Theme.allCases, id: \.self) { value in
                            Text(value.label).tag(value)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Прогресс") {
                    Button("Сбросить очки и серию", role: .destructive) {
                        showResetStats = true
                    }
                    Button("Начать все задания заново", role: .destructive) {
                        showResetQuests = true
                    }
                }

                Section("О приложении") {
                    LabeledContent("Версия", value: appVersion)
                    LabeledContent("Нейросеть", value: "MobileNetV2 (ImageNet, 1001 класс)")
                    LabeledContent("Разработчик", value: "yea123123")
                }
            }
            .navigationTitle("Настройки")
            .alert("Сбросить очки и серию?", isPresented: $showResetStats) {
                Button("Сбросить", role: .destructive) {
                    GameStats.shared.reset()
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Очки, серия, рекорды и достижения будут обнулены. Задания и фотографии не пострадают.")
            }
            .alert("Начать заново?", isPresented: $showResetQuests) {
                Button("Начать заново", role: .destructive) {
                    resetQuests()
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Все задания станут невыполненными и перемешаются заново. Фотографии в галерее сохранятся.")
            }
            .alert("Готово", isPresented: $showResetDone) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Задания перемешаны. Новый квест начинается!")
            }
        }
    }

    private var sensitivityHint: String {
        let value = settings.sensitivity
        switch value {
        case .lenient: return "Сейчас включена щадящая проверка — почти всё засчитывается."
        case .balanced: return "Сейчас включена обычная проверка — сбалансированный вариант."
        case .strict: return "Сейчас включена строгая проверка — только очевидные совпадения."
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func resetQuests() {
        QuestManager(storage: .shared).restart()
        showResetDone = true
    }
}
