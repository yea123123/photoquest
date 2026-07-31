import SwiftUI

@main
struct PhotoQuestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/// Корневой экран: две вкладки — «Квест» и «Галерея».
struct ContentView: View {
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
        }
    }
}
