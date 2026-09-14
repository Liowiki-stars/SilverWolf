import SwiftUI
import SwiftData

@main
struct SilverWolfApp: App {
    // SwiftData 容器
    let container: ModelContainer = {
        do {
            return try ModelContainer(for: ChatMessage.self, CollectedSong.self, Memory.self)
        } catch {
            fatalError("SwiftData 初始化失败: \(error)")
        }
    }()

    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(appState.chatViewModel)
                .environmentObject(appState.musicViewModel)
                .environmentObject(appState.companionViewModel)
                .modelContainer(container)
                .onAppear {
                    appState.initialize(modelContext: container.mainContext)
                }
                .preferredColorScheme(.dark)
                .fullScreenCover(isPresented: $appState.showCompanionMode) {
                    CompanionModeView()
                        .environmentObject(appState.companionViewModel)
                        .environmentObject(appState.chatViewModel)
                }
        }
    }
}

// MARK: - 根视图（底部Tab导航）
struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $appState.currentTab) {
            ChatView()
                .tabItem {
                    Label(AppTab.chat.rawValue, systemImage: AppTab.chat.icon)
                }
                .tag(AppTab.chat)

            MusicView()
                .tabItem {
                    Label(AppTab.music.rawValue, systemImage: AppTab.music.icon)
                }
                .tag(AppTab.music)

            SmartHomeView()
                .tabItem {
                    Label(AppTab.home.rawValue, systemImage: AppTab.home.icon)
                }
                .tag(AppTab.home)

            SettingsView()
                .tabItem {
                    Label(AppTab.settings.rawValue, systemImage: AppTab.settings.icon)
                }
                .tag(AppTab.settings)
        }
        .tint(Color(hex: "9D4EDD"))
    }
}
