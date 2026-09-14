import Foundation
import SwiftData

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isProcessing = false
    @Published var inputText = ""

    private let modelContext: ModelContext
    private let aiService: AIService

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.aiService = AIService.shared
        loadHistory()
    }

    // MARK: - 加载历史对话
    private func loadHistory() {
        let descriptor = FetchDescriptor<ChatMessage>(
            sortBy: [SortDescriptor(\.timestamp)]
        )
        do {
            messages = try modelContext.fetch(descriptor)
        } catch {
            print("加载对话历史失败: \(error)")
        }
    }

    // MARK: - 发送消息
    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isProcessing else { return }

        // 添加用户消息
        let userMsg = ChatMessage(role: "user", content: text)
        messages.append(userMsg)
        modelContext.insert(userMsg)
        inputText = ""
        isProcessing = true

        // 检查是否为音乐指令（优先处理）
        if let musicAction = MusicCommandParser.parse(text) {
            handleMusicCommand(musicAction, text: text)
            return
        }

        // 调用AI大模型生成回复
        Task {
            do {
                let response = try await aiService.generateResponse(
                    systemPrompt: SilverWolfPersona.systemPrompt,
                    messages: messages.map { ["role": $0.role, "content": $0.content] }
                )
                // 银狼人设后处理
                let polished = SilverWolfPersona.polish(response)
                let aiMsg = ChatMessage(role: "assistant", content: polished)
                await MainActor.run {
                    messages.append(aiMsg)
                    modelContext.insert(aiMsg)
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    let errorMsg = ChatMessage(
                        role: "assistant",
                        content: SilverWolfPersona.templateReply(for: "error") ?? "小黎，啧，出bug了罢了"
                    )
                    messages.append(errorMsg)
                    modelContext.insert(errorMsg)
                    isProcessing = false
                }
            }
        }
    }

    // MARK: - 处理音乐指令
    private func handleMusicCommand(_ action: MusicAction, text: String) {
        guard let musicVM = AppState.shared.musicViewModel else {
            let errorMsg = ChatMessage(role: "assistant", content: "小黎，音乐模块未初始化，无法执行而已")
            messages.append(errorMsg)
            modelContext.insert(errorMsg)
            isProcessing = false
            return
        }
        var reply = ""

        switch action.type {
        case .play:
            if let keyword = action.keyword {
                Task {
                    await musicVM.searchAndPlay(keyword: keyword)
                }
                reply = SilverWolfPersona.templateReply(for: "play_music") ?? "小黎，已启动播放进程嘛"
            } else {
                musicVM.resume()
                reply = "小黎，播放进程已恢复而已"
            }
        case .pause:
            musicVM.pause()
            reply = SilverWolfPersona.templateReply(for: "pause_music") ?? "小黎，播放进程已挂起罢了"
        case .next:
            musicVM.next()
            reply = SilverWolfPersona.templateReply(for: "next_song") ?? "小黎，已切换下一条链路嘛"
        case .prev:
            musicVM.prev()
            reply = "小黎，回溯至前一条音频链路而已"
        case .collect:
            if let current = musicVM.currentSong {
                musicVM.toggleCollect(song: current)
                reply = SilverWolfPersona.templateReply(for: "collect") ?? "小黎，已加密存储嘛"
            } else {
                reply = "小黎，当前没有播放中的链路，无法收藏罢了"
            }
        case .volumeUp:
            musicVM.volumeUp()
            reply = "小黎，音量参数已上调（敲键盘声）"
        case .volumeDown:
            musicVM.volumeDown()
            reply = "小黎，音量参数已下调而已"
        case .unknown:
            break
        }

        let aiMsg = ChatMessage(role: "assistant", content: reply)
        messages.append(aiMsg)
        modelContext.insert(aiMsg)
        isProcessing = false
    }

    // MARK: - 清空对话
    func clearHistory() {
        do {
            try modelContext.delete(model: ChatMessage.self)
            messages.removeAll()
        } catch {
            print("清空对话失败: \(error)")
        }
    }
}

// MARK: - 音乐指令解析
enum MusicActionType {
    case play, pause, next, prev, collect, volumeUp, volumeDown, unknown
}

struct MusicAction {
    let type: MusicActionType
    let keyword: String?
}

enum MusicCommandParser {
    static func parse(_ text: String) -> MusicAction? {
        let t = text.lowercased()

        // 播放
        if t.contains("播放") || t.contains("放歌") || t.contains("开始播放") {
            var keyword: String? = nil
            if let range = t.range(of: "播放") {
                let after = String(t[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                if !after.isEmpty { keyword = after }
            }
            return MusicAction(type: .play, keyword: keyword)
        }

        // 暂停
        if t.contains("暂停") || t.contains("停一下") || t.contains("别放了") {
            return MusicAction(type: .pause, keyword: nil)
        }

        // 下一首
        if t.contains("下一首") || t.contains("下一曲") || t.contains("换一首") {
            return MusicAction(type: .next, keyword: nil)
        }

        // 上一首
        if t.contains("上一首") || t.contains("上一曲") {
            return MusicAction(type: .prev, keyword: nil)
        }

        // 收藏
        if t.contains("收藏") || t.contains("加入歌单") {
            return MusicAction(type: .collect, keyword: nil)
        }

        // 音量大
        if t.contains("音量大") || t.contains("调大") || t.contains("声音大点") {
            return MusicAction(type: .volumeUp, keyword: nil)
        }

        // 音量小
        if t.contains("音量小") || t.contains("调小") || t.contains("声音小点") {
            return MusicAction(type: .volumeDown, keyword: nil)
        }

        return nil
    }
}
