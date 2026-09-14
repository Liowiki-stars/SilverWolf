import Foundation
import SwiftData

// MARK: - 记忆数据模型
@Model
final class Memory {
    var id: UUID
    var type: String          // preference / habit / fact / event / conversation
    var category: String      // 分类标签（如"音乐"/"作息"/"喜好"）
    var content: String       // 记忆内容
    var importance: Int       // 重要度 1-5（5最重要）
    var createdAt: Date
    var lastAccessedAt: Date
    var accessCount: Int
    var source: String        // 来源（"对话提取"/"场景观察"/"用户输入"）
    var isPinned: Bool        // 是否置顶（永不遗忘）

    init(type: MemoryType, category: String, content: String, importance: Int = 3, source: String = "对话提取") {
        self.id = UUID()
        self.type = type.rawValue
        self.category = category
        self.content = content
        self.importance = importance
        self.createdAt = Date()
        self.lastAccessedAt = Date()
        self.accessCount = 0
        self.source = source
        self.isPinned = false
    }
}

// MARK: - 记忆类型枚举
enum MemoryType: String, CaseIterable, Identifiable {
    case preference = "偏好"      // 喜欢/不喜欢什么
    case habit = "习惯"           // 作息/行为习惯
    case fact = "重要事实"        // 生日/工作/重要的人
    case event = "事件"           // 发生过的事
    case conversation = "对话摘要" // 聊过的话题

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .preference: return "heart.fill"
        case .habit: return "clock.fill"
        case .fact: return "star.fill"
        case .event: return "calendar.fill"
        case .conversation: return "bubble.left.fill"
        }
    }

    var color: String {
        switch self {
        case .preference: return "EC4899"
        case .habit: return "3B82F6"
        case .fact: return "FBBF24"
        case .event: return "10B981"
        case .conversation: return "9D4EDD"
        }
    }
}
