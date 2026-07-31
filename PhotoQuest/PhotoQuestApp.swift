import SwiftUI

@main
struct PhotoQuestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/// Корневой экран: четыре вкладки — «Квест», «Галерея», «Достижения», «Настройки».
struct ContentView: View {

    @StateObject private var settings = GameSettings.shared

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Квест", systemImage: "camera.aperture")
                }
            GalleryView()
                .tabItem {
                    Label("Галерея", systemImage: "photo.on.rectangle")
                }
            AchievementsView(embedded: true)
                .tabItem {
                    Label("Достижения", systemImage: "trophy.fill")
                }
            SettingsView()
                .tabItem {
                    Label("Настройки", systemImage: "gearshape.fill")
                }
        }
        .preferredColorScheme(settings.theme.colorScheme)
    }
}
