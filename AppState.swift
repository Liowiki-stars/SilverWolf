import Foundation
import SwiftData

// MARK: - 全局应用状态
@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    // ViewModels
    var chatViewModel: ChatViewModel!
    var musicViewModel: MusicViewModel!
    var companionViewModel: CompanionViewModel!

    // 全局设置
    @Published var currentTab: AppTab = .chat
    @Published var isVoiceRecording = false
    @Published var showCompanionMode = false

    private init() {}

    // MARK: - 初始化（在App入口调用）
    func initialize(modelContext: ModelContext) {
        chatViewModel = ChatViewModel(modelContext: modelContext)
        musicViewModel = MusicViewModel(modelContext: modelContext)
        companionViewModel = CompanionViewModel()
        companionViewModel.setModelContext(modelContext)
    }
}

// MARK: - 底部Tab
enum AppTab: String, CaseIterable {
    case chat = "对话"
    case music = "音乐"
    case home = "家居"
    case settings = "设置"

    var icon: String {
        switch self {
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .music: return "music.note"
        case .home: return "house.fill"
        case .settings: return "gearshape.fill"
        }
    }
}
